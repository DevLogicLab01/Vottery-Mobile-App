import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:sentry_flutter/sentry_flutter.dart';

/// Error Tracking Service with Sentry integration and Slack alerts for critical errors
/// Provides crash reporting, AI service failure tracking, and real-time error monitoring
class ErrorTrackingService {
  static ErrorTrackingService? _instance;
  static ErrorTrackingService get instance =>
      _instance ??= ErrorTrackingService._();
  ErrorTrackingService._();

  bool _isInitialized = false;

  /// Initialize Sentry error tracking
  Future<void> initialize() async {
    try {
      const sentryDsn = String.fromEnvironment('SENTRY_DSN');

      if (sentryDsn.isEmpty) {
        debugPrint('Sentry DSN not configured. Error tracking disabled.');
        return;
      }

      await SentryFlutter.init((options) {
        options.dsn = sentryDsn;
        options.tracesSampleRate = 1.0;
        options.environment = kDebugMode ? 'development' : 'production';
        options.enableAutoSessionTracking = true;
        options.attachScreenshot = true;
        options.attachViewHierarchy = true;
        options.beforeSend = (event, hint) {
          // Filter out non-critical errors in development
          if (kDebugMode && event.level == SentryLevel.info) {
            return null;
          }
          return event;
        };
      });

      _isInitialized = true;
      debugPrint('Sentry error tracking initialized');
    } catch (e) {
      debugPrint('Sentry initialization error: $e');
    }
  }

  /// Notify Slack when critical errors exceed threshold (webhook URL from env)
  Future<void> _notifySlackCriticalError({
    required String title,
    required String message,
    SentryLevel level = SentryLevel.error,
  }) async {
    if (_severityRank(level) < _severityRank(SentryLevel.error)) return;
    const slackUrl = String.fromEnvironment('SLACK_WEBHOOK_URL', defaultValue: '');
    if (slackUrl.isEmpty) return;
    try {
      await http.post(
        Uri.parse(slackUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'text': '🚨 Vottery Mobile Critical Error',
          'blocks': [
            {'type': 'section', 'text': {'type': 'mrkdwn', 'text': '*$title*'}},
            {'type': 'section', 'text': {'type': 'mrkdwn', 'text': message}},
            {'type': 'context', 'elements': [{'type': 'mrkdwn', 'text': 'Level: ${level.name}'}]},
          ],
        }),
      );
    } catch (e) {
      debugPrint('Slack notification error: $e');
    }
  }

  int _severityRank(SentryLevel level) {
    switch (level) {
      case SentryLevel.debug:
        return 0;
      case SentryLevel.info:
        return 1;
      case SentryLevel.warning:
        return 2;
      case SentryLevel.error:
        return 3;
      case SentryLevel.fatal:
        return 4;
      default:
        return 3;
    }
  }

  /// Capture exception with context; notifies Slack for critical errors
  Future<void> captureException(
    dynamic exception, {
    dynamic stackTrace,
    String? context,
    Map<String, dynamic>? extras,
  }) async {
    if (!_isInitialized) return;

    try {
      await Sentry.captureException(
        exception,
        stackTrace: stackTrace,
        hint: Hint.withMap({'context': context ?? 'Unknown', ...?extras}),
      );
      await _notifySlackCriticalError(
        title: 'Exception: ${context ?? "Unknown"}',
        message: exception.toString(),
        level: SentryLevel.error,
      );
    } catch (e) {
      debugPrint('Capture exception error: $e');
    }
  }

  /// Track AI service failure
  Future<void> trackAIServiceFailure({
    required String serviceName,
    required String operation,
    required String errorMessage,
    Map<String, dynamic>? additionalData,
  }) async {
    if (!_isInitialized) return;

    try {
      await Sentry.captureMessage(
        'AI Service Failure: $serviceName - $operation',
        level: SentryLevel.error,
        hint: Hint.withMap({
          'service_name': serviceName,
          'operation': operation,
          'error_message': errorMessage,
          'timestamp': DateTime.now().toIso8601String(),
          ...?additionalData,
        }),
      );
      await _notifySlackCriticalError(
        title: 'AI Service Failure: $serviceName',
        message: errorMessage,
        level: SentryLevel.error,
      );
    } catch (e) {
      debugPrint('Track AI service failure error: $e');
    }
  }

  /// Track database error
  Future<void> trackDatabaseError({
    required String operation,
    required String table,
    required String errorMessage,
  }) async {
    if (!_isInitialized) return;

    try {
      await Sentry.captureMessage(
        'Database Error: $table - $operation',
        level: SentryLevel.error,
        hint: Hint.withMap({
          'operation': operation,
          'table': table,
          'error_message': errorMessage,
          'timestamp': DateTime.now().toIso8601String(),
        }),
      );
    } catch (e) {
      debugPrint('Track database error error: $e');
    }
  }

  /// Track network error
  Future<void> trackNetworkError({
    required String endpoint,
    required int statusCode,
    required String errorMessage,
  }) async {
    if (!_isInitialized) return;

    try {
      await Sentry.captureMessage(
        'Network Error: $endpoint',
        level: SentryLevel.warning,
        hint: Hint.withMap({
          'endpoint': endpoint,
          'status_code': statusCode,
          'error_message': errorMessage,
          'timestamp': DateTime.now().toIso8601String(),
        }),
      );
    } catch (e) {
      debugPrint('Track network error error: $e');
    }
  }

  /// Track authentication error
  Future<void> trackAuthenticationError({
    required String operation,
    required String errorMessage,
  }) async {
    if (!_isInitialized) return;

    try {
      await Sentry.captureMessage(
        'Authentication Error: $operation',
        level: SentryLevel.error,
        hint: Hint.withMap({
          'operation': operation,
          'error_message': errorMessage,
          'timestamp': DateTime.now().toIso8601String(),
        }),
      );
    } catch (e) {
      debugPrint('Track authentication error error: $e');
    }
  }

  /// Track payment error
  Future<void> trackPaymentError({
    required String paymentMethod,
    required String errorMessage,
    double? amount,
  }) async {
    if (!_isInitialized) return;

    try {
      await Sentry.captureMessage(
        'Payment Error: $paymentMethod',
        level: SentryLevel.error,
        hint: Hint.withMap({
          'payment_method': paymentMethod,
          'error_message': errorMessage,
          'amount': amount,
          'timestamp': DateTime.now().toIso8601String(),
        }),
      );
    } catch (e) {
      debugPrint('Track payment error error: $e');
    }
  }

  /// Set user context
  Future<void> setUserContext({
    required String userId,
    String? email,
    String? username,
  }) async {
    if (!_isInitialized) return;

    try {
      await Sentry.configureScope((scope) {
        scope.setUser(SentryUser(id: userId, email: email, username: username));
      });
    } catch (e) {
      debugPrint('Set user context error: $e');
    }
  }

  /// Add breadcrumb for debugging
  Future<void> addBreadcrumb({
    required String message,
    required String category,
    Map<String, dynamic>? data,
  }) async {
    if (!_isInitialized) return;

    try {
      await Sentry.addBreadcrumb(
        Breadcrumb(
          message: message,
          category: category,
          data: data,
          timestamp: DateTime.now(),
        ),
      );
    } catch (e) {
      debugPrint('Add breadcrumb error: $e');
    }
  }

  /// Track performance transaction
  Future<void> trackPerformance({
    required String operation,
    required Duration duration,
    Map<String, dynamic>? data,
  }) async {
    if (!_isInitialized) return;

    try {
      final transaction = Sentry.startTransaction(operation, 'performance');

      await Future.delayed(duration);

      if (data != null) {
        transaction.setData('custom_data', data);
      }

      await transaction.finish();
    } catch (e) {
      debugPrint('Track performance error: $e');
    }
  }
}
