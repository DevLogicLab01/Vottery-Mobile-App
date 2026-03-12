import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import './telnyx_sms_service.dart';
import './supabase_service.dart';
import './enhanced_notification_service.dart';

/// Telnyx Critical Alerts Service
/// Replaces Twilio for AI-related critical alerts
/// Handles: AI failover, cost-efficiency takeover, service disruptions
class TelnyxCriticalAlertsService {
  static TelnyxCriticalAlertsService? _instance;
  static TelnyxCriticalAlertsService get instance =>
      _instance ??= TelnyxCriticalAlertsService._();
  TelnyxCriticalAlertsService._();

  SupabaseClient get _client => SupabaseService.instance.client;
  final TelnyxSMSService _telnyxService = TelnyxSMSService.instance;
  final EnhancedNotificationService _notificationService =
      EnhancedNotificationService.instance;

  // Escalation tracking
  final Map<String, DateTime> _sentAlerts = {};
  static const Duration _escalationWindow = Duration(minutes: 5);

  /// AI Failover Detected Alert
  Future<void> sendAIFailoverAlert({
    required String fromService,
    required String toService,
    required String reason,
  }) async {
    final message =
        'Critical: AI service failover triggered. $fromService → $toService. '
        'Reason: $reason. Action required.';

    await _sendCriticalAlert(
      alertType: 'ai_failover_detected',
      message: message,
      severity: 'critical',
    );
  }

  /// Cost Efficiency Takeover Approval Alert
  Future<void> sendCostEfficiencyTakeoverAlert({
    required String recommendedService,
    required double projectedSavings,
    required String dashboardUrl,
  }) async {
    final message =
        'Gemini takeover recommended. Projected savings: \$${projectedSavings.toStringAsFixed(2)}. '
        'Approve via dashboard: $dashboardUrl';

    await _sendCriticalAlert(
      alertType: 'cost_efficiency_takeover_approval',
      message: message,
      severity: 'high',
    );
  }

  /// Service Disruption Alert
  Future<void> sendServiceDisruptionAlert({
    required String serviceName,
    required String fallbackService,
    required String errorDetails,
  }) async {
    final message =
        'AI service disruption: $serviceName down. '
        'Fallback activated: $fallbackService. Error: $errorDetails';

    await _sendCriticalAlert(
      alertType: 'service_disruption',
      message: message,
      severity: 'critical',
    );
  }

  /// SLA Violation Alert
  Future<void> sendSLAViolationAlert({
    required String violationType,
    required double currentValue,
    required double threshold,
  }) async {
    final message =
        '🚨 SLA Violation: $violationType. '
        'Current: ${currentValue.toStringAsFixed(1)}, Threshold: $threshold. '
        'Check incident hub immediately.';

    await _sendCriticalAlert(
      alertType: 'sla_violation',
      message: message,
      severity: 'critical',
    );
  }

  /// Core alert sending with routing and escalation
  Future<void> _sendCriticalAlert({
    required String alertType,
    required String message,
    required String severity,
  }) async {
    try {
      // Get on-call admin
      final onCallAdmin = await _getOnCallAdmin();
      if (onCallAdmin == null) {
        debugPrint('No on-call admin found for alert: $alertType');
        return;
      }

      final alertKey = '${alertType}_${onCallAdmin['id']}';
      final lastSent = _sentAlerts[alertKey];

      // Send primary alert
      if (onCallAdmin['phone_number'] != null) {
        await _telnyxService.sendSMS(
          toPhone: onCallAdmin['phone_number'],
          messageBody: '🚨 [$severity.toUpperCase()] $message',
          messageCategory: 'critical_ai_alert',
        );
      }

      // Push notification
      await _notificationService.sendNotification(
        userId: onCallAdmin['id'],
        title: 'Critical AI Alert',
        body: message,
        category: 'critical_alert',
        priority: 'high',
      );

      _sentAlerts[alertKey] = DateTime.now();

      // Log alert
      final alertId = await _logAlert(
        alertType: alertType,
        recipientPhone: onCallAdmin['phone_number'] ?? '',
        messageBody: message,
        severity: severity,
      );

      // Schedule escalation check
      Future.delayed(_escalationWindow, () async {
        await _checkAndEscalate(
          alertId: alertId,
          alertType: alertType,
          message: message,
          severity: severity,
          primaryAdminId: onCallAdmin['id'],
        );
      });
    } catch (e) {
      debugPrint('Send critical alert error: $e');
    }
  }

  /// Get current on-call admin
  Future<Map<String, dynamic>?> _getOnCallAdmin() async {
    try {
      // Check on_call_schedule table
      final schedule = await _client
          .from('on_call_schedule')
          .select('admin_id, user_profiles(id, phone_number, email)')
          .lte('start_time', DateTime.now().toIso8601String())
          .gte('end_time', DateTime.now().toIso8601String())
          .maybeSingle();

      if (schedule != null) {
        return schedule['user_profiles'] as Map<String, dynamic>?;
      }

      // Fallback: get any admin
      final admin = await _client
          .from('user_profiles')
          .select('id, phone_number, email')
          .eq('role', 'admin')
          .limit(1)
          .maybeSingle();

      return admin;
    } catch (e) {
      debugPrint('Get on-call admin error: $e');
      return null;
    }
  }

  /// Escalate if no acknowledgment within 5 minutes
  Future<void> _checkAndEscalate({
    required String? alertId,
    required String alertType,
    required String message,
    required String severity,
    required String primaryAdminId,
  }) async {
    try {
      // Check if alert was acknowledged
      if (alertId != null) {
        final alert = await _client
            .from('telnyx_critical_alerts_log')
            .select('acknowledged_at')
            .eq('alert_id', alertId)
            .maybeSingle();

        if (alert?['acknowledged_at'] != null) {
          return; // Already acknowledged
        }
      }

      // Escalate to secondary admin
      final secondaryAdmin = await _client
          .from('user_profiles')
          .select('id, phone_number')
          .eq('role', 'admin')
          .neq('id', primaryAdminId)
          .limit(1)
          .maybeSingle();

      if (secondaryAdmin != null && secondaryAdmin['phone_number'] != null) {
        await _telnyxService.sendSMS(
          toPhone: secondaryAdmin['phone_number'],
          messageBody:
              '🚨 ESCALATION: Unacknowledged alert after 5min. [$alertType] $message',
          messageCategory: 'critical_ai_alert_escalation',
        );

        // Log escalation
        await _logAlert(
          alertType: '${alertType}_escalation',
          recipientPhone: secondaryAdmin['phone_number'],
          messageBody: 'ESCALATION: $message',
          severity: 'critical',
        );
      }
    } catch (e) {
      debugPrint('Escalation error: $e');
    }
  }

  /// Log alert to telnyx_critical_alerts_log
  Future<String?> _logAlert({
    required String alertType,
    required String recipientPhone,
    required String messageBody,
    required String severity,
  }) async {
    try {
      final result = await _client
          .from('telnyx_critical_alerts_log')
          .insert({
            'alert_type': alertType,
            'recipient_phone': recipientPhone,
            'message_body': messageBody,
            'severity': severity,
            'sent_at': DateTime.now().toIso8601String(),
          })
          .select('alert_id')
          .single();

      return result['alert_id']?.toString();
    } catch (e) {
      debugPrint('Log alert error: $e');
      return null;
    }
  }

  /// Acknowledge an alert
  Future<void> acknowledgeAlert(String alertId) async {
    try {
      await _client
          .from('telnyx_critical_alerts_log')
          .update({'acknowledged_at': DateTime.now().toIso8601String()})
          .eq('alert_id', alertId);
    } catch (e) {
      debugPrint('Acknowledge alert error: $e');
    }
  }

  /// Get alert history
  Future<List<Map<String, dynamic>>> getAlertHistory({int limit = 50}) async {
    try {
      final result = await _client
          .from('telnyx_critical_alerts_log')
          .select()
          .order('sent_at', ascending: false)
          .limit(limit);
      return List<Map<String, dynamic>>.from(result);
    } catch (e) {
      return [];
    }
  }
}
