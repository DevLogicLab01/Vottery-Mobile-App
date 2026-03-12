import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import './fraud_detection_service.dart';
import './user_security_service.dart';
import './supabase_service.dart';
import './auth_service.dart';
import './twilio_notification_service.dart';
import './enhanced_notification_service.dart';

/// Datadog threshold alert types
enum DatadogAlertType {
  queryLatencyBreach,
  errorRateBreach,
  connectionPoolExhaustion,
}

/// Automated incident alert from Datadog
class AutomatedIncidentAlert {
  final DatadogAlertType type;
  final double threshold;
  final double actualValue;
  final DateTime timestamp;
  final int consecutiveBreaches;

  AutomatedIncidentAlert({
    required this.type,
    required this.threshold,
    required this.actualValue,
    required this.consecutiveBreaches,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  String get typeLabel {
    switch (type) {
      case DatadogAlertType.queryLatencyBreach:
        return 'query_latency_breach';
      case DatadogAlertType.errorRateBreach:
        return 'error_rate_breach';
      case DatadogAlertType.connectionPoolExhaustion:
        return 'connection_pool_exhaustion';
    }
  }
}

/// Datadog threshold monitor - polls every 30 seconds
class DatadogThresholdMonitor {
  Timer? _pollingTimer;
  final Map<String, int> _consecutiveBreaches = {};
  final Function(AutomatedIncidentAlert) onAlert;

  // Thresholds
  static const double queryLatencyThresholdMs = 100.0;
  static const double errorRateThreshold = 5.0;
  static const double connectionPoolThreshold = 80.0;
  static const int consecutiveBreachesRequired = 5;

  DatadogThresholdMonitor({required this.onAlert});

  void start() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _pollMetrics();
    });
    debugPrint('📊 DatadogThresholdMonitor started (30s polling)');
  }

  void stop() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  Future<void> _pollMetrics() async {
    try {
      // Simulate Datadog metric polling (in production, call Datadog API)
      final metrics = await _fetchDatadogMetrics();

      final p95Latency = metrics['query_latency_p95'] ?? 0.0;
      final errorRate = metrics['error_rate'] ?? 0.0;
      final poolUtilization =
          metrics['database_connection_pool_utilization'] ?? 0.0;

      // Check query latency
      if (p95Latency > queryLatencyThresholdMs) {
        _consecutiveBreaches['latency'] =
            (_consecutiveBreaches['latency'] ?? 0) + 1;
        if (_consecutiveBreaches['latency']! >= consecutiveBreachesRequired) {
          onAlert(
            AutomatedIncidentAlert(
              type: DatadogAlertType.queryLatencyBreach,
              threshold: queryLatencyThresholdMs,
              actualValue: p95Latency,
              consecutiveBreaches: _consecutiveBreaches['latency']!,
            ),
          );
          _consecutiveBreaches['latency'] = 0;
        }
      } else {
        _consecutiveBreaches['latency'] = 0;
      }

      // Check error rate
      if (errorRate > errorRateThreshold) {
        _consecutiveBreaches['error_rate'] =
            (_consecutiveBreaches['error_rate'] ?? 0) + 1;
        if (_consecutiveBreaches['error_rate']! >= 1) {
          onAlert(
            AutomatedIncidentAlert(
              type: DatadogAlertType.errorRateBreach,
              threshold: errorRateThreshold,
              actualValue: errorRate,
              consecutiveBreaches: _consecutiveBreaches['error_rate']!,
            ),
          );
          _consecutiveBreaches['error_rate'] = 0;
        }
      } else {
        _consecutiveBreaches['error_rate'] = 0;
      }

      // Check connection pool
      if (poolUtilization > connectionPoolThreshold) {
        _consecutiveBreaches['pool'] = (_consecutiveBreaches['pool'] ?? 0) + 1;
        if (_consecutiveBreaches['pool']! >= 1) {
          onAlert(
            AutomatedIncidentAlert(
              type: DatadogAlertType.connectionPoolExhaustion,
              threshold: connectionPoolThreshold,
              actualValue: poolUtilization,
              consecutiveBreaches: _consecutiveBreaches['pool']!,
            ),
          );
          _consecutiveBreaches['pool'] = 0;
        }
      } else {
        _consecutiveBreaches['pool'] = 0;
      }
    } catch (e) {
      debugPrint('Datadog polling error: $e');
    }
  }

  Future<Map<String, double>> _fetchDatadogMetrics() async {
    // In production: call Datadog API GET /api/v1/query
    // Returning simulated metrics for now
    return {
      'query_latency_p95': 85.0 + (DateTime.now().second % 30).toDouble(),
      'error_rate': 2.0 + (DateTime.now().second % 10) * 0.3,
      'database_connection_pool_utilization':
          65.0 + (DateTime.now().second % 20).toDouble(),
    };
  }
}

class AutomatedIncidentResponseService {
  static AutomatedIncidentResponseService? _instance;
  static AutomatedIncidentResponseService get instance =>
      _instance ??= AutomatedIncidentResponseService._();

  AutomatedIncidentResponseService._();

  SupabaseClient get _client => SupabaseService.instance.client;
  AuthService get _auth => AuthService.instance;
  FraudDetectionService get _fraudDetection => FraudDetectionService.instance;
  UserSecurityService get _securityService => UserSecurityService.instance;
  TwilioNotificationService get _twilioService =>
      TwilioNotificationService.instance;
  EnhancedNotificationService get _notificationService =>
      EnhancedNotificationService.instance;

  // Confidence threshold triggers
  static const double accountFreezeThreshold = 90.0;
  static const double transactionBlockThreshold = 85.0;
  static const double investigationThreshold = 75.0;
  static const double warningThreshold = 60.0;

  /// Execute automated response based on ML confidence score
  Future<Map<String, dynamic>> executeAutomatedResponse({
    required String incidentId,
    required String incidentType,
    required double confidenceScore,
    required Map<String, dynamic> incidentData,
  }) async {
    try {
      final actions = <String>[];
      final results = <String, dynamic>{};

      // Determine actions based on confidence score
      if (confidenceScore >= accountFreezeThreshold) {
        final freezeResult = await _freezeAccount(
          userId: incidentData['user_id'],
          reason: 'Automated fraud detection: $incidentType',
          confidenceScore: confidenceScore,
        );
        actions.add('account_freeze');
        results['account_freeze'] = freezeResult;
      }

      if (confidenceScore >= transactionBlockThreshold) {
        final blockResult = await _blockTransactions(
          userId: incidentData['user_id'],
          reason: 'High-confidence fraud detection',
        );
        actions.add('transaction_block');
        results['transaction_block'] = blockResult;
      }

      if (confidenceScore >= investigationThreshold) {
        final investigationResult = await _createInvestigation(
          incidentId: incidentId,
          incidentType: incidentType,
          priority: confidenceScore >= accountFreezeThreshold
              ? 'critical'
              : 'high',
          incidentData: incidentData,
        );
        actions.add('investigation_created');
        results['investigation'] = investigationResult;
      }

      if (confidenceScore >= warningThreshold) {
        await _sendStakeholderNotifications(
          incidentId: incidentId,
          incidentType: incidentType,
          confidenceScore: confidenceScore,
          actions: actions,
        );
        actions.add('stakeholder_notified');
      }

      // Log automated response
      await _logAutomatedResponse(
        incidentId: incidentId,
        confidenceScore: confidenceScore,
        actions: actions,
        results: results,
      );

      return {
        'success': true,
        'incident_id': incidentId,
        'confidence_score': confidenceScore,
        'actions_taken': actions,
        'results': results,
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      debugPrint('Execute automated response error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Freeze user account
  Future<bool> _freezeAccount({
    required String userId,
    required String reason,
    required double confidenceScore,
  }) async {
    try {
      await _client
          .from('user_accounts')
          .update({
            'is_frozen': true,
            'freeze_reason': reason,
            'freeze_confidence_score': confidenceScore,
            'frozen_at': DateTime.now().toIso8601String(),
            'frozen_by': 'automated_system',
          })
          .eq('user_id', userId);

      // Remove logSecurityEvent call as method doesn't exist
      // await _securityService.logSecurityEvent(
      //   userId: userId,
      //   eventType: 'account_freeze',
      //   severity: 'critical',
      //   description: reason,
      //   metadata: {'confidence_score': confidenceScore},
      // );

      return true;
    } catch (e) {
      debugPrint('Freeze account error: $e');
      return false;
    }
  }

  /// Block transactions for user
  Future<bool> _blockTransactions({
    required String userId,
    required String reason,
  }) async {
    try {
      await _client.from('transaction_blocks').insert({
        'user_id': userId,
        'block_reason': reason,
        'is_active': true,
        'created_by': 'automated_system',
      });

      return true;
    } catch (e) {
      debugPrint('Block transactions error: $e');
      return false;
    }
  }

  /// Create investigation case
  Future<String?> _createInvestigation({
    required String incidentId,
    required String incidentType,
    required String priority,
    required Map<String, dynamic> incidentData,
  }) async {
    try {
      final response = await _client
          .from('investigations')
          .insert({
            'incident_id': incidentId,
            'investigation_type': incidentType,
            'priority': priority,
            'status': 'open',
            'incident_data': incidentData,
            'created_by': 'automated_system',
          })
          .select()
          .single();

      return response['id'] as String?;
    } catch (e) {
      debugPrint('Create investigation error: $e');
      return null;
    }
  }

  /// Send notifications to stakeholders
  Future<void> _sendStakeholderNotifications({
    required String incidentId,
    required String incidentType,
    required double confidenceScore,
    required List<String> actions,
  }) async {
    try {
      // Get admin users
      final admins = await _client
          .from('user_profiles')
          .select('id, email, phone_number')
          .eq('role', 'admin');

      for (final admin in admins) {
        // Send email notification
        await _notificationService.sendNotification(
          userId: admin['id'],
          title: 'Automated Incident Response',
          body:
              'Incident $incidentId detected with ${confidenceScore.toStringAsFixed(1)}% confidence. Actions: ${actions.join(", ")}',
          category: 'security_alert',
          priority: confidenceScore >= accountFreezeThreshold
              ? 'high'
              : 'medium',
        );

        // Send SMS for critical incidents
        if (confidenceScore >= accountFreezeThreshold &&
            admin['phone_number'] != null) {
          await _twilioService.sendUserActivityNotification(
            phoneNumber: admin['phone_number'],
            activityType: 'CRITICAL',
            details:
                'Automated response executed for incident $incidentId. Confidence: ${confidenceScore.toStringAsFixed(1)}%',
          );
        }
      }
    } catch (e) {
      debugPrint('Send stakeholder notifications error: $e');
    }
  }

  /// Log automated response
  Future<void> _logAutomatedResponse({
    required String incidentId,
    required double confidenceScore,
    required List<String> actions,
    required Map<String, dynamic> results,
  }) async {
    try {
      await _client.from('automated_response_logs').insert({
        'incident_id': incidentId,
        'confidence_score': confidenceScore,
        'actions_taken': actions,
        'results': results,
        'executed_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Log automated response error: $e');
    }
  }

  /// Rollback automated action (for false positives)
  Future<bool> rollbackAction({
    required String incidentId,
    required String actionType,
    required String reason,
  }) async {
    try {
      final log = await _client
          .from('automated_response_logs')
          .select()
          .eq('incident_id', incidentId)
          .maybeSingle();

      if (log == null) return false;

      final userId = log['results']?['account_freeze']?['user_id'];
      if (userId == null) return false;

      switch (actionType) {
        case 'account_freeze':
          await _client
              .from('user_accounts')
              .update({
                'is_frozen': false,
                'freeze_reason': null,
                'unfrozen_at': DateTime.now().toIso8601String(),
                'unfrozen_by': _auth.currentUser?.id ?? 'system',
                'unfreeze_reason': reason,
              })
              .eq('user_id', userId);
          break;

        case 'transaction_block':
          await _client
              .from('transaction_blocks')
              .update({'is_active': false})
              .eq('user_id', userId);
          break;
      }

      await _client.from('automated_response_rollbacks').insert({
        'incident_id': incidentId,
        'action_type': actionType,
        'rollback_reason': reason,
        'rolled_back_by': _auth.currentUser?.id ?? 'system',
      });

      return true;
    } catch (e) {
      debugPrint('Rollback action error: $e');
      return false;
    }
  }

  /// Get automated response history
  Future<List<Map<String, dynamic>>> getResponseHistory({
    int limit = 50,
  }) async {
    try {
      final response = await _client
          .from('automated_response_logs')
          .select()
          .order('executed_at', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get response history error: $e');
      return [];
    }
  }

  /// Get rollback history
  Future<List<Map<String, dynamic>>> getRollbackHistory({
    int limit = 50,
  }) async {
    try {
      final response = await _client
          .from('automated_response_rollbacks')
          .select()
          .order('created_at', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get rollback history error: $e');
      return [];
    }
  }
}
