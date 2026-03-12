import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import './enhanced_notification_service.dart';
import './supabase_service.dart';
import './telnyx_sms_service.dart';

/// SLA Monitoring Service
/// Monitors performance metrics across all screens and detects SLA violations
class SLAMonitorService {
  static SLAMonitorService? _instance;
  static SLAMonitorService get instance => _instance ??= SLAMonitorService._();
  SLAMonitorService._();

  SupabaseClient get _client => SupabaseService.instance.client;
  final TelnyxSMSService _telnyxService = TelnyxSMSService.instance;
  final EnhancedNotificationService _notificationService =
      EnhancedNotificationService.instance;

  // SLA Thresholds
  static const double screenLoadTimeThresholdMs = 3000;
  static const double apiResponseTimeThresholdMs = 500;
  static const double errorRateThreshold = 1.0; // 1%
  static const double uptimeThreshold = 99.9; // 99.9%

  final List<SLAViolation> _activeViolations = [];
  List<SLAViolation> get activeViolations =>
      List.unmodifiable(_activeViolations);

  /// Check metrics and detect SLA violations
  Future<List<SLAViolation>> checkSLACompliance() async {
    final violations = <SLAViolation>[];

    try {
      // Check screen load times
      final screenMetrics = await _getScreenLoadMetrics();
      for (final metric in screenMetrics) {
        if (metric['avg_load_time_ms'] > screenLoadTimeThresholdMs) {
          violations.add(
            SLAViolation(
              type: 'screen_load_time',
              screen: metric['screen_name'],
              currentValue: metric['avg_load_time_ms'].toDouble(),
              threshold: screenLoadTimeThresholdMs,
              severity: metric['avg_load_time_ms'] > 5000
                  ? 'critical'
                  : 'warning',
            ),
          );
        }
      }

      // Check API response times
      final apiMetrics = await _getApiResponseMetrics();
      for (final metric in apiMetrics) {
        if (metric['avg_response_time_ms'] > apiResponseTimeThresholdMs) {
          violations.add(
            SLAViolation(
              type: 'api_response_time',
              screen: metric['endpoint'],
              currentValue: metric['avg_response_time_ms'].toDouble(),
              threshold: apiResponseTimeThresholdMs,
              severity: metric['avg_response_time_ms'] > 1000
                  ? 'critical'
                  : 'warning',
            ),
          );
        }
      }

      // Check error rates
      final errorRate = await _getErrorRate();
      if (errorRate > errorRateThreshold) {
        violations.add(
          SLAViolation(
            type: 'error_rate',
            screen: 'global',
            currentValue: errorRate,
            threshold: errorRateThreshold,
            severity: errorRate > 5.0 ? 'critical' : 'warning',
          ),
        );
      }

      // Update active violations
      _activeViolations
        ..clear()
        ..addAll(violations);

      // Log violations
      for (final violation in violations) {
        await _logViolation(violation);
      }

      // Trigger alerts for critical violations
      final criticalViolations = violations
          .where((v) => v.severity == 'critical')
          .toList();
      if (criticalViolations.isNotEmpty) {
        await _triggerAlerts(criticalViolations);
      }

      // Incident correlation
      if (violations.length > 3) {
        await _correlateIncidents(violations);
      }

      return violations;
    } catch (e) {
      debugPrint('SLA check error: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _getScreenLoadMetrics() async {
    try {
      final result = await _client
          .from('screen_performance_metrics')
          .select('screen_name, avg_load_time_ms')
          .order('avg_load_time_ms', ascending: false)
          .limit(20);
      return List<Map<String, dynamic>>.from(result);
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _getApiResponseMetrics() async {
    try {
      final result = await _client
          .from('api_performance_metrics')
          .select('endpoint, avg_response_time_ms')
          .order('avg_response_time_ms', ascending: false)
          .limit(20);
      return List<Map<String, dynamic>>.from(result);
    } catch (e) {
      return [];
    }
  }

  Future<double> _getErrorRate() async {
    try {
      final result = await _client
          .from('error_rate_metrics')
          .select('error_rate')
          .order('measured_at', ascending: false)
          .limit(1)
          .maybeSingle();
      return (result?['error_rate'] ?? 0.0).toDouble();
    } catch (e) {
      return 0.0;
    }
  }

  Future<void> _logViolation(SLAViolation violation) async {
    try {
      await _client.from('sla_violations').insert({
        'violation_type': violation.type,
        'screen_or_endpoint': violation.screen,
        'current_value': violation.currentValue,
        'threshold_value': violation.threshold,
        'severity': violation.severity,
        'detected_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Log violation error: $e');
    }
  }

  Future<void> _triggerAlerts(List<SLAViolation> violations) async {
    try {
      final admins = await _client
          .from('user_profiles')
          .select('id, phone_number')
          .eq('role', 'admin');

      final message =
          '🚨 SLA Violation: ${violations.length} critical issues. '
          '${violations.first.type}: ${violations.first.currentValue.toStringAsFixed(0)} '
          '(threshold: ${violations.first.threshold}). Check incident hub.';

      for (final admin in admins) {
        // Push notification
        await _notificationService.sendNotification(
          userId: admin['id'],
          title: 'SLA Violation Detected',
          body: message,
          category: 'sla_alert',
          priority: 'high',
        );

        // Telnyx SMS
        if (admin['phone_number'] != null) {
          await _telnyxService.sendSMS(
            toPhone: admin['phone_number'],
            messageBody: message,
            messageCategory: 'sla_alert',
          );
        }
      }

      // Create incident ticket
      await _client.from('incident_tickets').insert({
        'title': 'SLA Violation: ${violations.length} issues detected',
        'severity': 'critical',
        'violations': violations.map((v) => v.toMap()).toList(),
        'status': 'open',
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Trigger alerts error: $e');
    }
  }

  /// Incident correlation: detect coordinated attacks
  Future<void> _correlateIncidents(List<SLAViolation> violations) async {
    try {
      final hasPaymentFailures = violations.any(
        (v) => v.screen?.contains('payment') == true,
      );
      final hasFraudSpike = violations.any((v) => v.type == 'error_rate');

      if (hasPaymentFailures && hasFraudSpike) {
        await _client.from('incident_correlations').insert({
          'correlation_type': 'coordinated_attack',
          'description':
              'Fraud spike + payment failures detected simultaneously',
          'violations': violations.map((v) => v.toMap()).toList(),
          'detected_at': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      debugPrint('Correlate incidents error: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getViolationHistory({
    int limit = 50,
  }) async {
    try {
      final result = await _client
          .from('sla_violations')
          .select()
          .order('detected_at', ascending: false)
          .limit(limit);
      return List<Map<String, dynamic>>.from(result);
    } catch (e) {
      return [];
    }
  }
}

class SLAViolation {
  final String type;
  final String? screen;
  final double currentValue;
  final double threshold;
  final String severity;

  SLAViolation({
    required this.type,
    this.screen,
    required this.currentValue,
    required this.threshold,
    required this.severity,
  });

  Map<String, dynamic> toMap() => {
    'type': type,
    'screen': screen,
    'current_value': currentValue,
    'threshold': threshold,
    'severity': severity,
  };
}