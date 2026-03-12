import 'package:sentry_flutter/sentry_flutter.dart';

import './supabase_service.dart';

class SentryService {
  static final SentryService _instance = SentryService._internal();
  factory SentryService() => _instance;
  SentryService._internal();

  final SupabaseService _supabaseService = SupabaseService.instance;

  /// Initialize Sentry
  static Future<void> initialize() async {
    const sentryDsn = String.fromEnvironment('SENTRY_DSN');

    if (sentryDsn.isEmpty) {
      print('⚠️ SENTRY_DSN not configured. Error tracking disabled.');
      return;
    }

    await SentryFlutter.init((options) {
      options.dsn = sentryDsn;
      options.environment = const String.fromEnvironment(
        'ENVIRONMENT',
        defaultValue: 'production',
      );
      options.tracesSampleRate = 1.0;
      options.enableAutoSessionTracking = true;
      options.attachScreenshot = true;
      options.attachViewHierarchy = true;

      // Filter sensitive data
      options.beforeSend = (event, hint) {
        // Remove sensitive user data
        if (event.user != null) {
          event = event.copyWith(
            user: event.user?.copyWith(email: null, ipAddress: null),
          );
        }
        return event;
      };
    });
  }

  /// Capture exception with context
  Future<void> captureException(
    dynamic exception,
    StackTrace? stackTrace, {
    String? context,
    Map<String, dynamic>? extra,
    SentryLevel level = SentryLevel.error,
  }) async {
    try {
      await Sentry.captureException(
        exception,
        stackTrace: stackTrace,
        hint: Hint.withMap({'context': context, ...?extra}),
      );

      // Also log to Supabase for admin dashboard
      await _logToSupabase(
        exception: exception,
        stackTrace: stackTrace,
        context: context,
        level: level,
        extra: extra,
      );
    } catch (e) {
      print('Error capturing exception: $e');
    }
  }

  /// Add breadcrumb for tracking user actions
  void addBreadcrumb({
    required String message,
    String? category,
    Map<String, dynamic>? data,
    SentryLevel level = SentryLevel.info,
  }) {
    Sentry.addBreadcrumb(
      Breadcrumb(
        message: message,
        category: category,
        data: data,
        level: level,
        timestamp: DateTime.now(),
      ),
    );
  }

  /// Set user context
  void setUser(String userId, {String? email, String? username}) {
    Sentry.configureScope((scope) {
      scope.setUser(SentryUser(id: userId, email: email, username: username));
    });
  }

  /// Clear user context
  void clearUser() {
    Sentry.configureScope((scope) {
      scope.setUser(null);
    });
  }

  /// Start transaction for performance monitoring
  ISentrySpan startTransaction(String operation, String description) {
    return Sentry.startTransaction(operation, description, bindToScope: true);
  }

  /// Log to Supabase for admin dashboard
  Future<void> _logToSupabase({
    required dynamic exception,
    StackTrace? stackTrace,
    String? context,
    SentryLevel level = SentryLevel.error,
    Map<String, dynamic>? extra,
  }) async {
    try {
      final userId = _supabaseService.client.auth.currentUser?.id;

      await _supabaseService.client.from('error_tracking_logs').insert({
        'user_id': userId,
        'error_type': exception.runtimeType.toString(),
        'error_message': exception.toString(),
        'stack_trace': stackTrace?.toString(),
        'severity': _mapSentryLevelToString(level),
        'screen_name': context,
        'device_info': extra?['device_info'],
        'app_version': extra?['app_version'],
        'status': 'new',
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error logging to Supabase: $e');
    }
  }

  String _mapSentryLevelToString(SentryLevel level) {
    switch (level) {
      case SentryLevel.fatal:
        return 'fatal';
      case SentryLevel.error:
        return 'error';
      case SentryLevel.warning:
        return 'warning';
      case SentryLevel.info:
        return 'info';
      case SentryLevel.debug:
        return 'debug';
      default:
        return 'info';
    }
  }
}
