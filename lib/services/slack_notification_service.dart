import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import './supabase_service.dart';

class SlackNotificationService {
  static SlackNotificationService? _instance;
  static SlackNotificationService get instance =>
      _instance ??= SlackNotificationService._();

  SlackNotificationService._();

  SupabaseClient get _client => SupabaseService.instance.client;

  static const String slackWebhookUrl = String.fromEnvironment(
    'SLACK_WEBHOOK_URL',
    defaultValue: '',
  );
  static const String slackSigningSecret = String.fromEnvironment(
    'SLACK_SIGNING_SECRET',
    defaultValue: '',
  );

  /// Send performance alert to Slack
  Future<bool> sendPerformanceAlert({
    required Map<String, dynamic> anomaly,
  }) async {
    try {
      if (slackWebhookUrl.isEmpty) {
        debugPrint('Slack webhook URL not configured');
        return false;
      }

      // Get notification settings
      final settings = await _client
          .from('slack_notification_settings')
          .select()
          .eq('notification_type', 'performance_alerts')
          .maybeSingle();

      if (settings == null || settings['enabled'] != true) {
        debugPrint('Performance alerts disabled in settings');
        return false;
      }

      // Check quiet hours
      if (await _isQuietHours(settings)) {
        debugPrint('Skipping alert during quiet hours');
        return false;
      }

      final channel = settings['channel'] as String;
      final operationName = anomaly['operation_name'] as String;
      final severity = anomaly['severity'] as String;
      final baselineP95 = anomaly['baseline_p95_ms'];
      final currentP95 = anomaly['current_p95_ms'];
      final deviation = anomaly['deviation_percentage'];

      // Construct Slack message
      final message = {
        'channel': channel,
        'blocks': [
          {
            'type': 'header',
            'text': {
              'type': 'plain_text',
              'text': '⚠️ Performance Anomaly Detected',
              'emoji': true,
            },
          },
          {
            'type': 'context',
            'elements': [
              {
                'type': 'mrkdwn',
                'text':
                    'Operation: *$operationName* | Severity: *${severity.toUpperCase()}*',
              },
            ],
          },
          {
            'type': 'section',
            'fields': [
              {
                'type': 'mrkdwn',
                'text': '*Baseline P95*\n${baselineP95.toStringAsFixed(0)}ms',
              },
              {
                'type': 'mrkdwn',
                'text': '*Current P95*\n${currentP95.toStringAsFixed(0)}ms',
              },
              {
                'type': 'mrkdwn',
                'text': '*Deviation*\n+${deviation.toStringAsFixed(1)}%',
              },
              {
                'type': 'mrkdwn',
                'text':
                    '*Severity*\n${_getSeverityEmoji(severity)} ${severity.toUpperCase()}',
              },
            ],
          },
          {'type': 'divider'},
          {
            'type': 'actions',
            'elements': [
              {
                'type': 'button',
                'text': {
                  'type': 'plain_text',
                  'text': 'View Details',
                  'emoji': true,
                },
                'url':
                    'https://vottery2205.builtwithrocket.new/enhanced-performance-anomaly-detection-dashboard?anomaly_id=${anomaly['anomaly_id']}',
                'style': 'primary',
              },
              {
                'type': 'button',
                'text': {
                  'type': 'plain_text',
                  'text': 'Acknowledge',
                  'emoji': true,
                },
                'action_id': 'acknowledge_anomaly',
                'value': anomaly['anomaly_id'],
              },
            ],
          },
        ],
      };

      // Send to Slack
      final response = await http.post(
        Uri.parse(slackWebhookUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(message),
      );

      if (response.statusCode == 200) {
        // Log message
        await _logSlackMessage(
          channel: channel,
          messageType: 'performance_alert',
          anomalyId: anomaly['anomaly_id'],
          messagePayload: message,
          deliveryStatus: 'delivered',
        );
        return true;
      } else {
        debugPrint('Slack API error: ${response.statusCode}');
        await _logSlackMessage(
          channel: channel,
          messageType: 'performance_alert',
          anomalyId: anomaly['anomaly_id'],
          messagePayload: message,
          deliveryStatus: 'failed',
          errorMessage: response.body,
        );
        return false;
      }
    } catch (e) {
      debugPrint('Send performance alert error: $e');
      return false;
    }
  }

  /// Send incident alert to Slack
  Future<bool> sendIncidentAlert({
    required Map<String, dynamic> incident,
  }) async {
    try {
      if (slackWebhookUrl.isEmpty) return false;

      final settings = await _client
          .from('slack_notification_settings')
          .select()
          .eq('notification_type', 'security_incidents')
          .maybeSingle();

      if (settings == null || settings['enabled'] != true) {
        return false;
      }

      final channel = settings['channel'] as String;
      final incidentType = incident['incident_type'] as String;
      final severity = incident['severity'] as String;

      final emoji = incidentType.contains('security') ? '🚨' : '⚙️';

      final message = {
        'channel': channel,
        'blocks': [
          {
            'type': 'header',
            'text': {
              'type': 'plain_text',
              'text': '$emoji ${_getIncidentTypeLabel(incidentType)} Incident',
              'emoji': true,
            },
          },
          {
            'type': 'context',
            'elements': [
              {
                'type': 'mrkdwn',
                'text':
                    'Incident ID: *${incident['incident_id']}* | Detected: ${_formatTimestamp(incident['detected_at'])}',
              },
            ],
          },
          {
            'type': 'section',
            'fields': [
              {'type': 'mrkdwn', 'text': '*Title*\n${incident['title']}'},
              {
                'type': 'mrkdwn',
                'text':
                    '*Severity*\n${_getSeverityEmoji(severity)} ${severity.toUpperCase()}',
              },
              {'type': 'mrkdwn', 'text': '*Status*\n${incident['status']}'},
              {
                'type': 'mrkdwn',
                'text':
                    '*Impact*\n${incident['affected_systems']?.length ?? 0} systems affected',
              },
            ],
          },
          {
            'type': 'section',
            'text': {
              'type': 'mrkdwn',
              'text':
                  '*Affected Resources*\n${_formatAffectedSystems(incident['affected_systems'])}',
            },
          },
          {'type': 'divider'},
          {
            'type': 'actions',
            'elements': [
              {
                'type': 'button',
                'text': {
                  'type': 'plain_text',
                  'text': 'View Incident',
                  'emoji': true,
                },
                'url':
                    'https://vottery2205.builtwithrocket.new/automated-incident-response-center?incident_id=${incident['incident_id']}',
                'style': 'primary',
              },
              {
                'type': 'button',
                'text': {
                  'type': 'plain_text',
                  'text': 'Acknowledge',
                  'emoji': true,
                },
                'action_id': 'acknowledge_incident',
                'value': incident['incident_id'],
              },
              {
                'type': 'button',
                'text': {
                  'type': 'plain_text',
                  'text': 'Escalate',
                  'emoji': true,
                },
                'action_id': 'escalate_incident',
                'value': incident['incident_id'],
                'style': 'danger',
              },
            ],
          },
        ],
      };

      final response = await http.post(
        Uri.parse(slackWebhookUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(message),
      );

      if (response.statusCode == 200) {
        await _logSlackMessage(
          channel: channel,
          messageType: 'incident_alert',
          incidentId: incident['incident_id'],
          messagePayload: message,
          deliveryStatus: 'delivered',
        );
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('Send incident alert error: $e');
      return false;
    }
  }

  /// Send remediation update to Slack
  Future<bool> sendRemediationUpdate({
    required String incidentId,
    required String updateMessage,
    required List<Map<String, dynamic>> completedSteps,
    required String currentStep,
  }) async {
    try {
      if (slackWebhookUrl.isEmpty) return false;

      final settings = await _client
          .from('slack_notification_settings')
          .select()
          .eq('notification_type', 'security_incidents')
          .maybeSingle();

      if (settings == null) return false;

      final channel = settings['channel'] as String;

      final message = {
        'channel': channel,
        'blocks': [
          {
            'type': 'header',
            'text': {
              'type': 'plain_text',
              'text': '✅ Remediation Progress',
              'emoji': true,
            },
          },
          {
            'type': 'section',
            'text': {'type': 'mrkdwn', 'text': updateMessage},
          },
          {
            'type': 'section',
            'text': {
              'type': 'mrkdwn',
              'text':
                  '*Completed Steps*\n${_formatCompletedSteps(completedSteps)}',
            },
          },
          {
            'type': 'section',
            'text': {
              'type': 'mrkdwn',
              'text': '*Current Step*\n🔄 $currentStep',
            },
          },
        ],
      };

      final response = await http.post(
        Uri.parse(slackWebhookUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(message),
      );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Send remediation update error: $e');
      return false;
    }
  }

  /// Test Slack webhook
  Future<bool> testWebhook(String webhookUrl) async {
    try {
      final message = {
        'text': '✅ Slack integration test successful!',
        'blocks': [
          {
            'type': 'section',
            'text': {
              'type': 'mrkdwn',
              'text':
                  '*Vottery Slack Integration*\nYour webhook is configured correctly and ready to receive notifications.',
            },
          },
        ],
      };

      final response = await http.post(
        Uri.parse(webhookUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(message),
      );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Test webhook error: $e');
      return false;
    }
  }

  /// Get notification history
  Future<List<Map<String, dynamic>>> getNotificationHistory({
    int limit = 50,
  }) async {
    try {
      final messages = await _client
          .from('slack_messages')
          .select()
          .order('sent_at', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(messages);
    } catch (e) {
      debugPrint('Get notification history error: $e');
      return [];
    }
  }

  /// Update notification settings
  Future<bool> updateNotificationSettings({
    required String notificationType,
    required String channel,
    required bool enabled,
    String? severityThreshold,
    String? quietHoursStart,
    String? quietHoursEnd,
  }) async {
    try {
      await _client.from('slack_notification_settings').upsert({
        'notification_type': notificationType,
        'channel': channel,
        'enabled': enabled,
        'severity_threshold': severityThreshold,
        'quiet_hours_start': quietHoursStart,
        'quiet_hours_end': quietHoursEnd,
        'updated_at': DateTime.now().toIso8601String(),
      });

      return true;
    } catch (e) {
      debugPrint('Update notification settings error: $e');
      return false;
    }
  }

  /// Helper: Check if current time is in quiet hours
  Future<bool> _isQuietHours(Map<String, dynamic> settings) async {
    try {
      final quietStart = settings['quiet_hours_start'] as String?;
      final quietEnd = settings['quiet_hours_end'] as String?;

      if (quietStart == null || quietEnd == null) return false;

      final now = TimeOfDay.now();
      final start = _parseTimeOfDay(quietStart);
      final end = _parseTimeOfDay(quietEnd);

      if (start == null || end == null) return false;

      final nowMinutes = now.hour * 60 + now.minute;
      final startMinutes = start.hour * 60 + start.minute;
      final endMinutes = end.hour * 60 + end.minute;

      if (startMinutes < endMinutes) {
        return nowMinutes >= startMinutes && nowMinutes <= endMinutes;
      } else {
        return nowMinutes >= startMinutes || nowMinutes <= endMinutes;
      }
    } catch (e) {
      return false;
    }
  }

  /// Helper: Parse time string to TimeOfDay
  TimeOfDay? _parseTimeOfDay(String time) {
    try {
      final parts = time.split(':');
      return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    } catch (e) {
      return null;
    }
  }

  /// Helper: Log Slack message
  Future<void> _logSlackMessage({
    required String channel,
    required String messageType,
    String? incidentId,
    String? anomalyId,
    required Map<String, dynamic> messagePayload,
    required String deliveryStatus,
    String? errorMessage,
  }) async {
    try {
      await _client.from('slack_messages').insert({
        'channel': channel,
        'message_type': messageType,
        'incident_id': incidentId,
        'anomaly_id': anomalyId,
        'message_payload': messagePayload,
        'sent_at': DateTime.now().toIso8601String(),
        'delivery_status': deliveryStatus,
        'error_message': errorMessage,
      });
    } catch (e) {
      debugPrint('Log Slack message error: $e');
    }
  }

  /// Helper: Get severity emoji
  String _getSeverityEmoji(String severity) {
    switch (severity.toLowerCase()) {
      case 'critical':
      case 'p0':
        return '🔴';
      case 'high':
      case 'p1':
        return '🟠';
      case 'medium':
      case 'p2':
        return '🟡';
      default:
        return '🟢';
    }
  }

  /// Helper: Get incident type label
  String _getIncidentTypeLabel(String type) {
    if (type.contains('security')) return 'Security';
    if (type.contains('payment')) return 'Payment';
    if (type.contains('performance')) return 'Performance';
    return 'System';
  }

  /// Helper: Format timestamp
  String _formatTimestamp(String timestamp) {
    try {
      final dt = DateTime.parse(timestamp);
      final now = DateTime.now();
      final diff = now.difference(dt);

      if (diff.inMinutes < 60) {
        return '${diff.inMinutes} minutes ago';
      } else if (diff.inHours < 24) {
        return '${diff.inHours} hours ago';
      } else {
        return '${diff.inDays} days ago';
      }
    } catch (e) {
      return timestamp;
    }
  }

  /// Helper: Format affected systems
  String _formatAffectedSystems(List<dynamic>? systems) {
    if (systems == null || systems.isEmpty) return 'None';
    return systems.map((s) => '• $s').join('\n');
  }

  /// Helper: Format completed steps
  String _formatCompletedSteps(List<Map<String, dynamic>> steps) {
    if (steps.isEmpty) return 'None';
    return steps.map((s) => '✅ ${s['step_name']}').join('\n');
  }
}
