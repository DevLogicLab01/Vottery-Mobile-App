import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import './supabase_service.dart';
import './slack_notification_service.dart';
import './pagerduty_service.dart';
import './resend_email_service.dart';

class AlertRoutingService {
  static AlertRoutingService? _instance;
  static AlertRoutingService get instance =>
      _instance ??= AlertRoutingService._();

  AlertRoutingService._();

  SupabaseClient get _client => SupabaseService.instance.client;

  /// Route performance anomaly alert based on severity
  Future<bool> routePerformanceAlert({
    required Map<String, dynamic> anomaly,
  }) async {
    try {
      final severity = anomaly['severity'] as String;
      final anomalyId = anomaly['anomaly_id'] as String;

      // Check deduplication (30-minute cooldown)
      if (await _isInCooldownPeriod(anomaly['operation_name'])) {
        debugPrint('Alert in cooldown period, skipping');
        return false;
      }

      bool alertSent = false;

      // Route based on severity
      if (severity == 'critical') {
        // Critical: PagerDuty + Slack
        await Future.wait([
          _sendPagerDutyAlert(anomaly),
          _sendSlackAlert(anomaly),
        ]);
        alertSent = true;
      } else if (severity == 'high') {
        // High: Slack only
        alertSent = await _sendSlackAlert(anomaly);
      } else if (severity == 'medium') {
        // Medium: Email only
        alertSent = await _sendEmailAlert(anomaly);
      }

      // Update alert_sent flag
      if (alertSent) {
        await _client
            .from('performance_anomalies')
            .update({'alert_sent': true})
            .eq('anomaly_id', anomalyId);
      }

      return alertSent;
    } catch (e) {
      debugPrint('Route performance alert error: $e');
      return false;
    }
  }

  /// Send PagerDuty alert for critical anomalies
  Future<bool> _sendPagerDutyAlert(Map<String, dynamic> anomaly) async {
    try {
      final incidentId = await PagerDutyService.instance.createPagerDutyIncident(
        incidentId: anomaly['anomaly_id'],
        title: 'Critical Performance Anomaly: ${anomaly['operation_name']}',
        description:
            'P95 latency increased from ${anomaly['baseline_p95_ms']}ms to ${anomaly['current_p95_ms']}ms (+${anomaly['deviation_percentage'].toStringAsFixed(1)}%)',
        severity: 'critical',
        incidentData: {
          'incident_type': 'performance_anomaly',
          'affected_resource': anomaly['operation_name'],
          'anomaly_id': anomaly['anomaly_id'],
        },
      );

      if (incidentId != null) {
        // Store PagerDuty incident ID in anomaly record
        await _client
            .from('performance_anomalies')
            .update({
              'root_cause_analysis': {
                ...anomaly['root_cause_analysis'] ?? {},
                'pagerduty_incident_id': incidentId,
              },
            })
            .eq('anomaly_id', anomaly['anomaly_id']);

        return true;
      }

      return false;
    } catch (e) {
      debugPrint('Send PagerDuty alert error: $e');
      return false;
    }
  }

  /// Send Slack alert
  Future<bool> _sendSlackAlert(Map<String, dynamic> anomaly) async {
    try {
      return await SlackNotificationService.instance.sendPerformanceAlert(
        anomaly: anomaly,
      );
    } catch (e) {
      debugPrint('Send Slack alert error: $e');
      return false;
    }
  }

  /// Send email alert for medium severity
  Future<bool> _sendEmailAlert(Map<String, dynamic> anomaly) async {
    try {
      // Get ops team email list
      final opsTeam = await _client
          .from('user_profiles')
          .select('email')
          .inFilter('role', ['devops_admin', 'super_admin']);

      if (opsTeam.isEmpty) return false;

      final emailList = opsTeam
          .map((user) => user['email'] as String)
          .where((email) => email.isNotEmpty)
          .toList();

      if (emailList.isEmpty) return false;

      // Send email via Resend
      final operationName = anomaly['operation_name'] as String;
      final baselineP95 = anomaly['baseline_p95_ms'];
      final currentP95 = anomaly['current_p95_ms'];
      final deviation = anomaly['deviation_percentage'];

      for (final email in emailList) {
        await ResendEmailService.instance.sendEmail(
          to: email,
          subject: 'Performance Anomaly Alert: $operationName',
          html:
              '''
            <h2>Medium Severity Performance Anomaly Detected</h2>
            <p><strong>Operation:</strong> $operationName</p>
            <p><strong>Baseline P95:</strong> ${baselineP95}ms</p>
            <p><strong>Current P95:</strong> ${currentP95}ms</p>
            <p><strong>Deviation:</strong> $deviation%</p>
            <p><strong>Anomaly ID:</strong> ${anomaly['anomaly_id']}</p>
            <p><strong>Detected At:</strong> ${anomaly['detected_at']}</p>
          ''',
        );
      }

      return true;
    } catch (e) {
      debugPrint('Send email alert error: $e');
      return false;
    }
  }

  /// Check if operation is in cooldown period (30 minutes)
  Future<bool> _isInCooldownPeriod(String operationName) async {
    try {
      final thirtyMinutesAgo = DateTime.now().subtract(
        const Duration(minutes: 30),
      );

      final recentAlert = await _client
          .from('performance_anomalies')
          .select()
          .eq('operation_name', operationName)
          .eq('alert_sent', true)
          .gte('detected_at', thirtyMinutesAgo.toIso8601String())
          .maybeSingle();

      return recentAlert != null;
    } catch (e) {
      debugPrint('Check cooldown period error: $e');
      return false;
    }
  }

  /// Get alert configuration settings
  Future<Map<String, dynamic>> getAlertConfiguration() async {
    try {
      final slackSettings = await _client
          .from('slack_notification_settings')
          .select()
          .eq('notification_type', 'performance_alerts')
          .maybeSingle();

      return {
        'slack_enabled': slackSettings?['enabled'] ?? false,
        'slack_channel': slackSettings?['channel'] ?? '#performance-alerts',
        'quiet_hours_start': slackSettings?['quiet_hours_start'],
        'quiet_hours_end': slackSettings?['quiet_hours_end'],
        'critical_threshold': 200,
        'high_threshold': 150,
        'medium_threshold': 100,
      };
    } catch (e) {
      debugPrint('Get alert configuration error: $e');
      return {
        'slack_enabled': false,
        'critical_threshold': 200,
        'high_threshold': 150,
        'medium_threshold': 100,
      };
    }
  }

  /// Update alert configuration
  Future<bool> updateAlertConfiguration({
    required Map<String, dynamic> config,
  }) async {
    try {
      // Update Slack settings
      await _client.from('slack_notification_settings').upsert({
        'notification_type': 'performance_alerts',
        'channel': config['slack_channel'],
        'enabled': config['slack_enabled'],
        'quiet_hours_start': config['quiet_hours_start'],
        'quiet_hours_end': config['quiet_hours_end'],
        'updated_at': DateTime.now().toIso8601String(),
      });

      return true;
    } catch (e) {
      debugPrint('Update alert configuration error: $e');
      return false;
    }
  }

  /// Test alert routing (send test alert)
  Future<bool> sendTestAlert(String channel) async {
    try {
      final testAnomaly = {
        'anomaly_id': 'test-${DateTime.now().millisecondsSinceEpoch}',
        'operation_name': 'test_operation',
        'severity': 'high',
        'baseline_p95_ms': 100,
        'current_p95_ms': 250,
        'deviation_percentage': 150.0,
        'detected_at': DateTime.now().toIso8601String(),
      };

      return await _sendSlackAlert(testAnomaly);
    } catch (e) {
      debugPrint('Send test alert error: $e');
      return false;
    }
  }
}
