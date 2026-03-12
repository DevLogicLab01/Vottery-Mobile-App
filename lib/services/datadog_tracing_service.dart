import 'package:flutter/foundation.dart';
import 'package:datadog_flutter_plugin/datadog_flutter_plugin.dart';
import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';

class DatadogTracingService {
  static DatadogTracingService? _instance;
  static DatadogTracingService get instance =>
      _instance ??= DatadogTracingService._();

  DatadogTracingService._();

  final Map<String, DateTime> _spanStartTimes = {};
  final Map<String, Map<String, String>> _spanTags = {};
  final Map<String, String> _activeScreenTraces = {};

  // SLA thresholds per screen type
  static const Map<String, double> _slaThresholds = {
    'admin': 3000.0,
    'dashboard': 2500.0,
    'feed': 2000.0,
    'default': 3000.0,
  };

  /// Initialize Datadog RUM
  Future<void> initializeDatadog() async {
    try {
      const clientToken = String.fromEnvironment('DATADOG_CLIENT_TOKEN');
      const applicationId = String.fromEnvironment('DATADOG_APPLICATION_ID');
      const environment = String.fromEnvironment(
        'ENVIRONMENT',
        defaultValue: 'production',
      );

      if (clientToken.isEmpty || applicationId.isEmpty) {
        debugPrint('Datadog credentials not configured');
        return;
      }

      final configuration = DatadogConfiguration(
        clientToken: clientToken,
        env: environment,
        site: DatadogSite.us1,
        nativeCrashReportEnabled: true,
        loggingConfiguration: DatadogLoggingConfiguration(),
        rumConfiguration: DatadogRumConfiguration(
          applicationId: applicationId,
          sessionSamplingRate: 100.0,
          traceSampleRate: 100.0,
        ),
      );

      await DatadogSdk.instance.initialize(
        configuration,
        TrackingConsent.granted,
      );
      debugPrint('Datadog initialized successfully');
    } catch (e) {
      debugPrint('Datadog initialization error: $e');
    }
  }

  /// Start a custom span for Supabase queries
  Future<String> startSupabaseQuerySpan(String table, String operation) async {
    return startSpan(
      'supabase.query',
      resourceName: '$operation $table',
      tags: {'service': 'supabase', 'table': table, 'operation': operation},
    );
  }

  /// Start a custom span for Stripe payments
  Future<String> startStripePaymentSpan(
    String operation,
    String? paymentIntentId,
  ) async {
    return startSpan(
      'stripe.payment',
      resourceName: operation,
      tags: {
        'service': 'stripe',
        'operation': operation,
        if (paymentIntentId != null) 'payment_intent_id': paymentIntentId,
      },
    );
  }

  /// Start a custom span for AI service calls
  Future<String> startAIServiceSpan(
    String service,
    String model,
    int? promptTokens,
  ) async {
    return startSpan(
      'ai.$service.request',
      resourceName: model,
      tags: {
        'service': service,
        'model': model,
        if (promptTokens != null) 'prompt_tokens': promptTokens.toString(),
      },
    );
  }

  /// Finish span with AI service metrics
  Future<void> finishAIServiceSpan(
    String spanId,
    int completionTokens,
    double cost,
  ) async {
    await finishSpan(
      spanId,
      tags: {
        'completion_tokens': completionTokens.toString(),
        'cost': cost.toStringAsFixed(4),
      },
    );
  }

  /// Track slow query (>1000ms)
  Future<void> trackSlowQuery(String query, int durationMs) async {
    if (durationMs > 1000) {
      // Create a logger to log the warning
      final logger = DatadogSdk.instance.logs?.createLogger(
        DatadogLoggerConfiguration(),
      );
      logger?.warn(
        'Slow query detected: ${query.substring(0, min(100, query.length))}',
        attributes: {
          'duration_ms': durationMs,
          'query': query,
          'threshold': 1000,
        },
      );
    }
  }

  /// Start a custom span
  Future<String> startSpan(
    String operationName, {
    String? resourceName,
    Map<String, String>? tags,
  }) async {
    try {
      final spanId = _generateSpanId();
      _spanStartTimes[spanId] = DateTime.now();
      _spanTags[spanId] = tags ?? {};

      // Add span tags
      if (tags != null) {
        for (final entry in tags.entries) {
          DatadogSdk.instance.rum?.addAttribute(entry.key, entry.value);
        }
      }

      // Start user action for span
      DatadogSdk.instance.rum?.startAction(RumActionType.custom, operationName);

      return spanId;
    } catch (e) {
      debugPrint('Start span error: $e');
      return '';
    }
  }

  /// Finish a span
  Future<void> finishSpan(
    String spanId, {
    String? error,
    Map<String, String>? tags,
  }) async {
    try {
      final startTime = _spanStartTimes[spanId];
      if (startTime == null) return;

      final duration = DateTime.now().difference(startTime);

      // Add duration as timing
      DatadogSdk.instance.rum?.addTiming('span_duration_ms');

      // Add final tags
      if (tags != null) {
        for (final entry in tags.entries) {
          DatadogSdk.instance.rum?.addAttribute(entry.key, entry.value);
        }
      }

      // Add error if present
      if (error != null) {
        DatadogSdk.instance.rum?.addError(
          error,
          RumErrorSource.custom,
          attributes: _spanTags[spanId] ?? {},
        );
      }

      // Stop action
      DatadogSdk.instance.rum?.stopAction(RumActionType.custom, '');

      // Cleanup
      _spanStartTimes.remove(spanId);
      _spanTags.remove(spanId);
    } catch (e) {
      debugPrint('Finish span error: $e');
    }
  }

  /// Start a custom span with screen context
  Future<String> startTrace(
    String operationName, {
    String? screenName,
    String? screenRoute,
    String? screenType,
    String? userTier,
    String? resourceName,
    Map<String, String>? tags,
  }) async {
    final allTags = <String, String>{
      ...?tags,
      if (screenName != null) 'screen_name': screenName,
      if (screenRoute != null) 'screen_route': screenRoute,
      if (screenType != null) 'screen_type': screenType,
      if (userTier != null) 'user_tier': userTier,
    };
    final spanId = await startSpan(
      operationName,
      resourceName: resourceName ?? screenName,
      tags: allTags,
    );
    if (screenName != null) {
      _activeScreenTraces[screenName] = spanId;
    }
    return spanId;
  }

  /// Stop a screen trace
  Future<void> stopTrace(String screenName, {String? error}) async {
    final spanId = _activeScreenTraces[screenName];
    if (spanId != null) {
      final startTime = _spanStartTimes[spanId];
      if (startTime != null) {
        final durationMs = DateTime.now().difference(startTime).inMilliseconds;
        await finishSpan(
          spanId,
          error: error,
          tags: {'duration_ms': durationMs.toString()},
        );
        // Check SLA violation
        await _checkSLAViolation(
          screenName: screenName,
          durationMs: durationMs,
        );
      }
      _activeScreenTraces.remove(screenName);
    }
  }

  /// Check if screen load time violates SLA
  Future<void> _checkSLAViolation({
    required String screenName,
    required int durationMs,
  }) async {
    try {
      final screenType = _getScreenType(screenName);
      final threshold =
          _slaThresholds[screenType] ?? _slaThresholds['default']!;
      if (durationMs > threshold) {
        await Supabase.instance.client
            .from('screen_performance_metrics')
            .insert({
              'screen_name': screenName,
              'screen_type': screenType,
              'load_time_ms': durationMs,
              'sla_threshold_ms': threshold,
              'sla_violated': true,
              'recorded_at': DateTime.now().toIso8601String(),
            });
        debugPrint(
          'SLA violation: $screenName loaded in ${durationMs}ms (threshold: ${threshold}ms)',
        );
      } else {
        await Supabase.instance.client
            .from('screen_performance_metrics')
            .insert({
              'screen_name': screenName,
              'screen_type': screenType,
              'load_time_ms': durationMs,
              'sla_threshold_ms': threshold,
              'sla_violated': false,
              'recorded_at': DateTime.now().toIso8601String(),
            });
      }
    } catch (e) {
      debugPrint('SLA check error: $e');
    }
  }

  String _getScreenType(String screenName) {
    if (screenName.contains('admin') || screenName.contains('dashboard')) {
      return 'admin';
    }
    if (screenName.contains('feed') || screenName.contains('home')) {
      return 'feed';
    }
    if (screenName.contains('analytics') || screenName.contains('monitor')) {
      return 'dashboard';
    }
    return 'default';
  }

  /// Generate unique span ID
  String _generateSpanId() {
    return '${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(10000)}';
  }

  /// Start RUM view (screen) tracking for session/load analytics
  void startRumView(String key, {String? name}) {
    try {
      DatadogSdk.instance.rum?.startView(key, name ?? key);
    } catch (e) {
      debugPrint('Datadog startView error: $e');
    }
  }

  /// Stop RUM view (screen) tracking
  void stopRumView(String key) {
    try {
      DatadogSdk.instance.rum?.stopView(key);
    } catch (e) {
      debugPrint('Datadog stopView error: $e');
    }
  }

  /// Track custom metric
  Future<void> trackCustomMetric(
    String metricName,
    double value,
    Map<String, String>? tags,
  ) async {
    try {
      DatadogSdk.instance.rum?.addAttribute(metricName, value);
      if (tags != null) {
        for (final entry in tags.entries) {
          DatadogSdk.instance.rum?.addAttribute(entry.key, entry.value);
        }
      }
    } catch (e) {
      debugPrint('Track custom metric error: $e');
    }
  }
}
