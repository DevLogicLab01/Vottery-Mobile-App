import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import './supabase_service.dart';
import './error_tracking_service.dart';
import './slack_notification_service.dart';

class SentryIntegrationService {
  static SentryIntegrationService? _instance;
  static SentryIntegrationService get instance =>
      _instance ??= SentryIntegrationService._();

  SentryIntegrationService._();

  SupabaseClient get _client => SupabaseService.instance.client;
  ErrorTrackingService get _errorTracking => ErrorTrackingService.instance;

  /// Track error incident in database
  Future<void> trackErrorIncident({
    required String errorType,
    required String severity,
    required String errorMessage,
    String? affectedFeature,
    String? stackTrace,
    Map<String, dynamic>? userContext,
    Map<String, dynamic>? deviceInfo,
    String? sentryEventId,
  }) async {
    try {
      await _client.from('error_tracking_incidents').insert({
        'error_type': errorType,
        'severity': severity,
        'affected_feature': affectedFeature,
        'error_message': errorMessage,
        'stack_trace': stackTrace,
        'user_context': userContext ?? {},
        'device_info': deviceInfo ?? {},
        'sentry_event_id': sentryEventId,
        'status': 'open',
      });

      // Also send to Sentry
      await _errorTracking.captureException(
        errorMessage,
        context: affectedFeature,
        extras: {
          'error_type': errorType,
          'severity': severity,
          ...?userContext,
          ...?deviceInfo,
        },
      );
    } catch (e) {
      debugPrint('Track error incident error: $e');
    }
  }

  /// Get recent error incidents
  Future<List<Map<String, dynamic>>> getRecentErrorIncidents({
    String? severity,
    String? status,
    int limit = 50,
  }) async {
    try {
      final response = await _client.rpc(
        'get_recent_error_incidents',
        params: {'p_limit': limit, 'p_severity': severity},
      );

      return List<Map<String, dynamic>>.from(response ?? []);
    } catch (e) {
      debugPrint('Get recent error incidents error: $e');
      return [];
    }
  }

  /// Get error incidents by feature
  Future<List<Map<String, dynamic>>> getErrorIncidentsByFeature(
    String feature,
  ) async {
    try {
      final response = await _client
          .from('error_tracking_incidents')
          .select()
          .eq('affected_feature', feature)
          .order('occurred_at', ascending: false)
          .limit(50);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get error incidents by feature error: $e');
      return [];
    }
  }

  /// Get error rate statistics
  Future<Map<String, dynamic>> getErrorRateStatistics() async {
    try {
      final last24Hours = DateTime.now().subtract(const Duration(hours: 24));

      final response = await _client
          .from('error_tracking_incidents')
          .select()
          .gte('occurred_at', last24Hours.toIso8601String());

      final incidents = List<Map<String, dynamic>>.from(response);

      final criticalCount = incidents
          .where((i) => i['severity'] == 'critical')
          .length;
      final highCount = incidents.where((i) => i['severity'] == 'high').length;
      final mediumCount = incidents
          .where((i) => i['severity'] == 'medium')
          .length;
      final lowCount = incidents.where((i) => i['severity'] == 'low').length;

      final openCount = incidents.where((i) => i['status'] == 'open').length;
      final resolvedCount = incidents
          .where((i) => i['status'] == 'resolved')
          .length;

      return {
        'total_incidents': incidents.length,
        'critical_count': criticalCount,
        'high_count': highCount,
        'medium_count': mediumCount,
        'low_count': lowCount,
        'open_count': openCount,
        'resolved_count': resolvedCount,
        'error_rate': incidents.length / 24.0, // errors per hour
      };
    } catch (e) {
      debugPrint('Get error rate statistics error: $e');
      return _getDefaultErrorStats();
    }
  }

  /// Update error incident status
  Future<bool> updateErrorIncidentStatus({
    required String incidentId,
    required String status,
    String? assignedTo,
  }) async {
    try {
      final updateData = {
        'status': status,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (assignedTo != null) {
        updateData['assigned_to'] = assignedTo;
      }

      if (status == 'resolved') {
        updateData['resolved_at'] = DateTime.now().toIso8601String();
      }

      await _client
          .from('error_tracking_incidents')
          .update(updateData)
          .eq('incident_id', incidentId);

      return true;
    } catch (e) {
      debugPrint('Update error incident status error: $e');
      return false;
    }
  }

  /// Track AI service failure with detailed context
  Future<void> trackAIServiceFailure({
    required String aiProvider,
    required String featureName,
    required String errorMessage,
    int? executionTimeMs,
    Map<String, dynamic>? additionalContext,
  }) async {
    try {
      await _client.from('error_tracking_incidents').insert({
        'error_type': 'ai_service_failure',
        'severity': 'high',
        'affected_feature': featureName,
        'error_message': '$aiProvider: $errorMessage',
        'stack_trace': null,
        'user_context': {
          'ai_provider': aiProvider,
          'execution_time_ms': executionTimeMs,
          ...?additionalContext,
        },
        'device_info': {},
        'status': 'open',
      });

      // Check if threshold exceeded for automated alerting
      await _checkAlertThresholds('ai_service_failure', aiProvider);
    } catch (e) {
      debugPrint('Track AI service failure error: $e');
    }
  }

  /// Check alert thresholds and trigger automated alerts
  Future<void> _checkAlertThresholds(String errorType, String context) async {
    try {
      // Get error count in last hour
      final oneHourAgo = DateTime.now().subtract(const Duration(hours: 1));
      final response = await _client
          .from('error_tracking_incidents')
          .select()
          .eq('error_type', errorType)
          .gte('occurred_at', oneHourAgo.toIso8601String());

      final errorCount = (response as List).length;

      // Critical thresholds
      if (errorType == 'app_crash' && errorCount > 10) {
        await _triggerCriticalAlert(
          'Critical: >10 crashes/minute',
          'App experiencing high crash rate: $errorCount crashes in last hour',
          'critical',
        );
      } else if (errorType == 'ai_service_failure' && errorCount > 5) {
        await _triggerHighAlert(
          'High: >5 AI service failures/hour',
          '$context AI service failing: $errorCount failures in last hour',
          'high',
        );
      }
    } catch (e) {
      debugPrint('Check alert thresholds error: $e');
    }
  }

  /// Trigger critical alert (Twilio SMS + Resend Email + Slack)
  Future<void> _triggerCriticalAlert(
    String title,
    String message,
    String severity,
  ) async {
    try {
      // Insert into automated alerting system
      await _client.from('active_alerts').insert({
        'alert_type': 'sentry_error',
        'severity': severity,
        'title': title,
        'message': message,
        'status': 'active',
        'notification_sent': true,
      });

      // Trigger Twilio SMS for critical alerts
      await _client.functions.invoke(
        'send-critical-alert-sms',
        body: {'title': title, 'message': message, 'severity': severity},
      );

      // Trigger Resend Email for critical alerts
      await _client.functions.invoke(
        'send-critical-alert-email',
        body: {'title': title, 'message': message, 'severity': severity},
      );

      // Trigger Slack notification to #vottery-errors channel
      await SlackNotificationService.instance.sendIncidentAlert(
        incident: {
          'incident_type': 'sentry_critical_error',
          'severity': severity,
          'title': title,
          'message': message,
          'error_summary': message,
          'affected_users_count': 0,
          'severity_level': severity,
          'timestamp': DateTime.now().toIso8601String(),
          'sentry_issue_url': 'https://sentry.io/organizations/vottery/issues/',
        },
      );
    } catch (e) {
      debugPrint('Trigger critical alert error: $e');
    }
  }

  /// Trigger high priority alert (Resend Email only)
  Future<void> _triggerHighAlert(
    String title,
    String message,
    String severity,
  ) async {
    try {
      // Insert into automated alerting system
      await _client.from('active_alerts').insert({
        'alert_type': 'sentry_error',
        'severity': severity,
        'title': title,
        'message': message,
        'status': 'active',
        'notification_sent': true,
      });

      // Trigger Resend Email for high priority alerts
      await _client.functions.invoke(
        'send-high-priority-alert-email',
        body: {'title': title, 'message': message, 'severity': severity},
      );
    } catch (e) {
      debugPrint('Trigger high alert error: $e');
    }
  }

  /// Track crash
  Future<void> trackCrash({
    required String errorMessage,
    required String stackTrace,
    String? affectedFeature,
    Map<String, dynamic>? userContext,
  }) async {
    await trackErrorIncident(
      errorType: 'crash',
      severity: 'critical',
      errorMessage: errorMessage,
      stackTrace: stackTrace,
      affectedFeature: affectedFeature,
      userContext: userContext,
    );
  }

  /// Get error incidents grouped by feature
  Future<Map<String, int>> getErrorIncidentsByFeatureCount() async {
    try {
      final response = await _client
          .from('error_tracking_incidents')
          .select('affected_feature')
          .gte(
            'occurred_at',
            DateTime.now().subtract(const Duration(days: 7)).toIso8601String(),
          );

      final incidents = List<Map<String, dynamic>>.from(response);
      final Map<String, int> featureCounts = {};

      for (final incident in incidents) {
        final feature = incident['affected_feature'] as String? ?? 'unknown';
        featureCounts[feature] = (featureCounts[feature] ?? 0) + 1;
      }

      return featureCounts;
    } catch (e) {
      debugPrint('Get error incidents by feature count error: $e');
      return {};
    }
  }

  Map<String, dynamic> _getDefaultErrorStats() {
    return {
      'total_incidents': 0,
      'critical_count': 0,
      'high_count': 0,
      'medium_count': 0,
      'low_count': 0,
      'open_count': 0,
      'resolved_count': 0,
      'error_rate': 0.0,
    };
  }
}
