import 'package:flutter/foundation.dart';
import './sentry_integration_service.dart';
import './alert_rules_service.dart';
import './twilio_notification_service.dart';
import './resend_email_service.dart';
import './supabase_service.dart';
import 'dart:async';

class SentryAlertIntegrationService {
  static SentryAlertIntegrationService? _instance;
  static SentryAlertIntegrationService get instance =>
      _instance ??= SentryAlertIntegrationService._();

  SentryAlertIntegrationService._();

  final SentryIntegrationService _sentry = SentryIntegrationService.instance;
  final AlertRulesService _alertRules = AlertRulesService.instance;
  final TwilioNotificationService _twilio = TwilioNotificationService.instance;
  final ResendEmailService _resend = ResendEmailService.instance;

  Timer? _monitoringTimer;
  final Map<String, DateTime> _lastAlertSent = {};
  final Map<String, int> _alertCounts = {};

  // Alert thresholds
  static const int criticalErrorsPerMinute = 10;
  static const int aiServiceFailuresPerHour = 5;
  static const int crashesPerDay = 100;
  static const int maxAlertsPerErrorTypePerHour = 3;

  /// Start monitoring Sentry error rates
  void startMonitoring() {
    _monitoringTimer?.cancel();
    _monitoringTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => _checkErrorThresholds(),
    );
    debugPrint('Sentry alert monitoring started');
  }

  /// Stop monitoring
  void stopMonitoring() {
    _monitoringTimer?.cancel();
    debugPrint('Sentry alert monitoring stopped');
  }

  /// Check error thresholds and trigger alerts
  Future<void> _checkErrorThresholds() async {
    try {
      final stats = await _sentry.getErrorRateStatistics();

      // Check critical errors per minute
      final errorRate = stats['error_rate'] as double? ?? 0.0;
      if (errorRate > criticalErrorsPerMinute) {
        await _triggerCriticalErrorAlert(
          errorRate: errorRate,
          totalIncidents: stats['total_incidents'] as int? ?? 0,
        );
      }

      // Check AI service failures
      await _checkAIServiceFailures();

      // Check daily crashes
      await _checkDailyCrashes();

      // Clean up old alert counts
      _cleanupAlertCounts();
    } catch (e) {
      debugPrint('Check error thresholds error: $e');
    }
  }

  /// Trigger critical error alert
  Future<void> _triggerCriticalErrorAlert({
    required double errorRate,
    required int totalIncidents,
  }) async {
    const errorType = 'critical_error_rate';

    // Check alert grouping (max 3 alerts per hour)
    if (!_canSendAlert(errorType)) {
      debugPrint('Alert storm prevention: Skipping $errorType alert');
      return;
    }

    try {
      // Create alert in automated alerting hub
      await _alertRules.triggerAlert(
        ruleId: 'critical_error_rate',
        metricType: 'error_rate',
        currentValue: errorRate,
        thresholdValue: criticalErrorsPerMinute.toDouble(),
        severity: 'critical',
        message:
            'Critical error rate: ${errorRate.toStringAsFixed(2)} errors/min (threshold: $criticalErrorsPerMinute)',
      );

      // Send Twilio SMS to on-call team
      await _sendCriticalSMS(
        errorType: 'Critical Error Rate',
        errorRate: errorRate,
        totalIncidents: totalIncidents,
      );

      // Send Resend email with detailed report
      await _sendDetailedErrorEmail(
        errorType: 'Critical Error Rate',
        errorRate: errorRate,
        totalIncidents: totalIncidents,
      );

      _recordAlertSent(errorType);
    } catch (e) {
      debugPrint('Trigger critical error alert error: $e');
    }
  }

  /// Check AI service failures
  Future<void> _checkAIServiceFailures() async {
    try {
      final oneHourAgo = DateTime.now().subtract(const Duration(hours: 1));

      final response = await SupabaseService.instance.client
          .from('error_tracking_incidents')
          .select()
          .eq('error_type', 'ai_service_failure')
          .gte('occurred_at', oneHourAgo.toIso8601String());

      final failures = List<Map<String, dynamic>>.from(response);

      if (failures.length > aiServiceFailuresPerHour) {
        const errorType = 'ai_service_failures';

        if (!_canSendAlert(errorType)) {
          return;
        }

        await _alertRules.triggerAlert(
          ruleId: 'ai_service_failures',
          metricType: 'ai_failures',
          currentValue: failures.length.toDouble(),
          thresholdValue: aiServiceFailuresPerHour.toDouble(),
          severity: 'high',
          message:
              'AI service failures: ${failures.length} failures/hour (threshold: $aiServiceFailuresPerHour)',
        );

        await _sendCriticalSMS(
          errorType: 'AI Service Failures',
          errorRate: failures.length.toDouble(),
          totalIncidents: failures.length,
        );

        await _sendDetailedErrorEmail(
          errorType: 'AI Service Failures',
          errorRate: failures.length.toDouble(),
          totalIncidents: failures.length,
          additionalDetails: _getAffectedServices(failures),
        );

        _recordAlertSent(errorType);
      }
    } catch (e) {
      debugPrint('Check AI service failures error: $e');
    }
  }

  /// Check daily crashes
  Future<void> _checkDailyCrashes() async {
    try {
      final oneDayAgo = DateTime.now().subtract(const Duration(days: 1));

      final response = await SupabaseService.instance.client
          .from('error_tracking_incidents')
          .select()
          .eq('error_type', 'crash')
          .gte('occurred_at', oneDayAgo.toIso8601String());

      final crashes = List<Map<String, dynamic>>.from(response);

      if (crashes.length > crashesPerDay) {
        const errorType = 'daily_crashes';

        if (!_canSendAlert(errorType)) {
          return;
        }

        await _alertRules.triggerAlert(
          ruleId: 'daily_crashes',
          metricType: 'crashes',
          currentValue: crashes.length.toDouble(),
          thresholdValue: crashesPerDay.toDouble(),
          severity: 'critical',
          message:
              'Daily crashes: ${crashes.length} crashes/day (threshold: $crashesPerDay)',
        );

        await _sendCriticalSMS(
          errorType: 'Daily Crashes',
          errorRate: crashes.length.toDouble(),
          totalIncidents: crashes.length,
        );

        await _sendDetailedErrorEmail(
          errorType: 'Daily Crashes',
          errorRate: crashes.length.toDouble(),
          totalIncidents: crashes.length,
          additionalDetails:
              'Affected users: ${_getAffectedUserCount(crashes)}',
        );

        _recordAlertSent(errorType);
      }
    } catch (e) {
      debugPrint('Check daily crashes error: $e');
    }
  }

  /// Send critical SMS via Twilio
  Future<void> _sendCriticalSMS({
    required String errorType,
    required double errorRate,
    required int totalIncidents,
  }) async {
    try {
      const onCallTeam = String.fromEnvironment(
        'ON_CALL_PHONE_NUMBERS',
        defaultValue: '',
      );

      if (onCallTeam.isEmpty) {
        debugPrint('No on-call phone numbers configured');
        return;
      }

      final phoneNumbers = onCallTeam.split(',');

      for (final phoneNumber in phoneNumbers) {
        await _twilio.sendSms(
          to: phoneNumber.trim(),
          body:
              '🚨 CRITICAL ALERT: $errorType\n'
              'Rate: ${errorRate.toStringAsFixed(2)}\n'
              'Incidents: $totalIncidents\n'
              'Time: ${DateTime.now().toString()}\n'
              'Action required immediately.',
        );
      }
    } catch (e) {
      debugPrint('Send critical SMS error: $e');
    }
  }

  /// Send detailed error email via Resend
  Future<void> _sendDetailedErrorEmail({
    required String errorType,
    required double errorRate,
    required int totalIncidents,
    String? additionalDetails,
  }) async {
    try {
      const onCallEmails = String.fromEnvironment(
        'ON_CALL_EMAIL_ADDRESSES',
        defaultValue: '',
      );

      if (onCallEmails.isEmpty) {
        debugPrint('No on-call email addresses configured');
        return;
      }

      final emailAddresses = onCallEmails.split(',');
      final recentIncidents = await _sentry.getRecentErrorIncidents(limit: 10);

      final htmlBody =
          '''
<!DOCTYPE html>
<html>
<head>
  <style>
    body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
    .header { background: #dc2626; color: white; padding: 20px; text-align: center; }
    .content { padding: 20px; }
    .metric { background: #f3f4f6; padding: 15px; margin: 10px 0; border-radius: 8px; }
    .metric-label { font-weight: bold; color: #6b7280; }
    .metric-value { font-size: 24px; color: #dc2626; }
    .incident { border-left: 4px solid #dc2626; padding: 10px; margin: 10px 0; background: #fef2f2; }
    .footer { background: #f3f4f6; padding: 15px; text-align: center; margin-top: 20px; }
  </style>
</head>
<body>
  <div class="header">
    <h1>🚨 Critical Error Alert</h1>
    <p>$errorType Threshold Exceeded</p>
  </div>
  
  <div class="content">
    <div class="metric">
      <div class="metric-label">Error Rate</div>
      <div class="metric-value">${errorRate.toStringAsFixed(2)} errors/min</div>
    </div>
    
    <div class="metric">
      <div class="metric-label">Total Incidents (Last 24h)</div>
      <div class="metric-value">$totalIncidents</div>
    </div>
    
    ${additionalDetails != null ? '<div class="metric"><div class="metric-label">Additional Details</div><p>$additionalDetails</p></div>' : ''}
    
    <h2>Recent Incidents</h2>
    ${recentIncidents.take(5).map((incident) => '''
    <div class="incident">
      <strong>${incident['error_type']}</strong> - ${incident['severity']}<br>
      <small>${incident['error_message']}</small><br>
      <small>Feature: ${incident['affected_feature'] ?? 'Unknown'}</small><br>
      <small>Time: ${incident['occurred_at']}</small>
    </div>
    ''').join('')}
    
    <h2>Recommended Actions</h2>
    <ul>
      <li>Review error logs in Sentry dashboard</li>
      <li>Check affected user impact</li>
      <li>Investigate root cause immediately</li>
      <li>Deploy hotfix if critical</li>
      <li>Update incident status in alert management hub</li>
    </ul>
  </div>
  
  <div class="footer">
    <p>Alert generated at ${DateTime.now().toString()}</p>
    <p>Vottery Platform Monitoring System</p>
  </div>
</body>
</html>
''';

      for (final email in emailAddresses) {
        await _resend.sendEmail(
          to: email.trim(),
          subject: '🚨 CRITICAL: $errorType Alert - Immediate Action Required',
          html: htmlBody,
        );
      }
    } catch (e) {
      debugPrint('Send detailed error email error: $e');
    }
  }

  /// Check if alert can be sent (alert grouping)
  bool _canSendAlert(String errorType) {
    final now = DateTime.now();
    final lastSent = _lastAlertSent[errorType];

    if (lastSent == null) {
      return true;
    }

    final hoursSinceLastAlert = now.difference(lastSent).inHours;

    if (hoursSinceLastAlert >= 1) {
      // Reset count after 1 hour
      _alertCounts[errorType] = 0;
      return true;
    }

    final currentCount = _alertCounts[errorType] ?? 0;
    return currentCount < maxAlertsPerErrorTypePerHour;
  }

  /// Record alert sent
  void _recordAlertSent(String errorType) {
    _lastAlertSent[errorType] = DateTime.now();
    _alertCounts[errorType] = (_alertCounts[errorType] ?? 0) + 1;
  }

  /// Clean up old alert counts
  void _cleanupAlertCounts() {
    final now = DateTime.now();
    final keysToRemove = <String>[];

    _lastAlertSent.forEach((key, value) {
      if (now.difference(value).inHours >= 1) {
        keysToRemove.add(key);
      }
    });

    for (final key in keysToRemove) {
      _lastAlertSent.remove(key);
      _alertCounts.remove(key);
    }
  }

  /// Get affected services from failures
  String _getAffectedServices(List<Map<String, dynamic>> failures) {
    final services = failures
        .map((f) => f['affected_feature'] as String?)
        .where((s) => s != null)
        .toSet();
    return services.join(', ');
  }

  /// Get affected user count
  int _getAffectedUserCount(List<Map<String, dynamic>> incidents) {
    final userIds = incidents
        .map((i) => (i['user_context'] as Map?)?['user_id'])
        .where((id) => id != null)
        .toSet();
    return userIds.length;
  }

  /// Configure alert thresholds (admin only)
  Future<void> configureAlertThresholds({
    int? criticalErrorsPerMinute,
    int? aiServiceFailuresPerHour,
    int? crashesPerDay,
    int? maxAlertsPerErrorTypePerHour,
  }) async {
    try {
      await SupabaseService.instance.client
          .from('sentry_alert_configuration')
          .upsert({
            'critical_errors_per_minute':
                criticalErrorsPerMinute ??
                SentryAlertIntegrationService.criticalErrorsPerMinute,
            'ai_service_failures_per_hour':
                aiServiceFailuresPerHour ??
                SentryAlertIntegrationService.aiServiceFailuresPerHour,
            'crashes_per_day':
                crashesPerDay ?? SentryAlertIntegrationService.crashesPerDay,
            'max_alerts_per_error_type_per_hour':
                maxAlertsPerErrorTypePerHour ??
                SentryAlertIntegrationService.maxAlertsPerErrorTypePerHour,
            'updated_at': DateTime.now().toIso8601String(),
          });
    } catch (e) {
      debugPrint('Configure alert thresholds error: $e');
    }
  }

  /// Get alert configuration
  Future<Map<String, dynamic>> getAlertConfiguration() async {
    try {
      final response = await SupabaseService.instance.client
          .from('sentry_alert_configuration')
          .select()
          .single();

      return Map<String, dynamic>.from(response);
    } catch (e) {
      debugPrint('Get alert configuration error: $e');
      return {
        'critical_errors_per_minute': criticalErrorsPerMinute,
        'ai_service_failures_per_hour': aiServiceFailuresPerHour,
        'crashes_per_day': crashesPerDay,
        'max_alerts_per_error_type_per_hour': maxAlertsPerErrorTypePerHour,
      };
    }
  }

  /// Acknowledge alert
  Future<void> acknowledgeAlert({
    required String alertId,
    required String acknowledgedBy,
    String status = 'acknowledged',
  }) async {
    try {
      await SupabaseService.instance.client
          .from('alert_incidents')
          .update({
            'status': status,
            'acknowledged_by': acknowledgedBy,
            'acknowledged_at': DateTime.now().toIso8601String(),
          })
          .eq('id', alertId);
    } catch (e) {
      debugPrint('Acknowledge alert error: $e');
    }
  }
}