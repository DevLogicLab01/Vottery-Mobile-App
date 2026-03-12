import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Enhanced AI Orchestration Service with Automatic Failover
/// Manages AI service health, automatic Gemini failover, and zero-downtime switching
class EnhancedAIOrchestratorService {
  static EnhancedAIOrchestratorService? _instance;
  static EnhancedAIOrchestratorService get instance =>
      _instance ??= EnhancedAIOrchestratorService._();

  EnhancedAIOrchestratorService._();

  static final SupabaseClient supabase = Supabase.instance.client;

  // Failover configuration
  static const int failureDetectionThresholdMs = 2000; // 2 seconds
  static const int geminiFailoverMs =
      500; // Instant Gemini fallback within 500ms
  static const int maxRetries = 5;
  static const List<int> exponentialBackoffMs = [
    1000,
    2000,
    4000,
    8000,
    16000,
  ]; // 1s, 2s, 4s, 8s, 16s

  // Circuit breaker thresholds
  static const int circuitBreakerErrorThreshold = 3; // 3 consecutive failures
  static const double errorRateThreshold = 0.25; // 25% error rate
  static const int responseTimeThreshold = 10000; // 10 seconds

  // Service health tracking
  static final Map<String, ServiceHealthStatus> _serviceHealth = {
    'openai': ServiceHealthStatus(
      provider: 'openai',
      status: 'healthy',
      lastCheckTime: DateTime.now(),
      consecutiveFailures: 0,
      errorRate: 0.0,
      avgResponseTimeMs: 0,
    ),
    'anthropic': ServiceHealthStatus(
      provider: 'anthropic',
      status: 'healthy',
      lastCheckTime: DateTime.now(),
      consecutiveFailures: 0,
      errorRate: 0.0,
      avgResponseTimeMs: 0,
    ),
    'perplexity': ServiceHealthStatus(
      provider: 'perplexity',
      status: 'healthy',
      lastCheckTime: DateTime.now(),
      consecutiveFailures: 0,
      errorRate: 0.0,
      avgResponseTimeMs: 0,
    ),
    'gemini': ServiceHealthStatus(
      provider: 'gemini',
      status: 'healthy',
      lastCheckTime: DateTime.now(),
      consecutiveFailures: 0,
      errorRate: 0.0,
      avgResponseTimeMs: 0,
    ),
  };

  static final StreamController<Map<String, ServiceHealthStatus>>
  _healthStreamController = StreamController.broadcast();

  static final List<FailoverEvent> _failoverHistory = [];
  static final Map<String, int> _requestCounts = {};
  static final Map<String, int> _errorCounts = {};

  // Request queue for zero-downtime switching
  static final List<PendingRequest> _requestQueue = [];

  /// Universal AI request with automatic failover
  ///
  /// Detects failures within 2 seconds and auto-switches to Gemini within 500ms
  /// Implements exponential backoff retry logic (1s, 2s, 4s, 8s, 16s)
  static Future<Map<String, dynamic>> invokeWithFailover({
    required String provider,
    required String functionName,
    required Map<String, dynamic> params,
    bool enableAutoFailover = true,
  }) async {
    final startTime = DateTime.now();
    int retryCount = 0;

    // Add to request queue for zero-downtime switching
    final requestId = DateTime.now().millisecondsSinceEpoch.toString();
    _requestQueue.add(
      PendingRequest(
        id: requestId,
        provider: provider,
        functionName: functionName,
        params: params,
        timestamp: startTime,
      ),
    );

    while (retryCount < maxRetries) {
      try {
        // Circuit breaker check
        if (_isCircuitBreakerOpen(provider)) {
          if (enableAutoFailover) {
            return await _executeGeminiFailover(
              originalProvider: provider,
              functionName: functionName,
              params: params,
              reason: 'Circuit breaker open',
            );
          }
          throw AIServiceException('Circuit breaker open for $provider');
        }

        // Check if provider is healthy
        if (!_isProviderHealthy(provider)) {
          if (enableAutoFailover) {
            return await _executeGeminiFailover(
              originalProvider: provider,
              functionName: functionName,
              params: params,
              reason: 'Provider unhealthy',
            );
          }
          throw AIServiceException('Provider $provider is unhealthy');
        }

        // Execute request with 2-second timeout detection
        final response = await _executeWithTimeout(
          provider: provider,
          functionName: functionName,
          params: params,
          timeoutMs: failureDetectionThresholdMs,
        );

        // Update health status on success
        final latency = DateTime.now().difference(startTime).inMilliseconds;
        await _updateServiceHealth(
          provider: provider,
          status: 'healthy',
          latencyMs: latency,
          success: true,
        );

        // Remove from request queue
        _requestQueue.removeWhere((req) => req.id == requestId);

        return response;
      } on TimeoutException {
        retryCount++;

        // Log timeout event
        await _logFailoverEvent(
          provider: provider,
          eventType: 'timeout',
          error: 'Request exceeded ${failureDetectionThresholdMs}ms threshold',
          retryCount: retryCount,
        );

        // Update health status on timeout
        await _updateServiceHealth(
          provider: provider,
          status: 'degraded',
          latencyMs: failureDetectionThresholdMs,
          success: false,
        );

        if (retryCount >= maxRetries) {
          if (enableAutoFailover) {
            return await _executeGeminiFailover(
              originalProvider: provider,
              functionName: functionName,
              params: params,
              reason: 'Timeout after $maxRetries retries',
            );
          }
          rethrow;
        }

        // Exponential backoff retry
        await Future.delayed(
          Duration(milliseconds: exponentialBackoffMs[retryCount - 1]),
        );
      } catch (e) {
        retryCount++;

        // Log error event
        await _logFailoverEvent(
          provider: provider,
          eventType: 'error',
          error: e.toString(),
          retryCount: retryCount,
        );

        // Update health status on failure
        await _updateServiceHealth(
          provider: provider,
          status: 'unhealthy',
          latencyMs: failureDetectionThresholdMs,
          success: false,
        );

        if (retryCount >= maxRetries) {
          if (enableAutoFailover) {
            return await _executeGeminiFailover(
              originalProvider: provider,
              functionName: functionName,
              params: params,
              reason: 'Error after $maxRetries retries: ${e.toString()}',
            );
          }
          rethrow;
        }

        // Exponential backoff retry
        await Future.delayed(
          Duration(milliseconds: exponentialBackoffMs[retryCount - 1]),
        );
      }
    }

    throw AIServiceException('Max retries exceeded for provider: $provider');
  }

  /// Execute Gemini failover within 500ms
  static Future<Map<String, dynamic>> _executeGeminiFailover({
    required String originalProvider,
    required String functionName,
    required Map<String, dynamic> params,
    required String reason,
  }) async {
    final failoverStartTime = DateTime.now();

    try {
      // Log failover event
      await _logFailoverEvent(
        provider: originalProvider,
        eventType: 'failover_to_gemini',
        error: reason,
        retryCount: 0,
      );

      // Execute with Gemini within 500ms
      final response = await _executeWithTimeout(
        provider: 'gemini',
        functionName: functionName,
        params: params,
        timeoutMs: geminiFailoverMs,
      );

      final failoverLatency = DateTime.now()
          .difference(failoverStartTime)
          .inMilliseconds;

      // Log successful failover
      await _logFailoverEvent(
        provider: 'gemini',
        eventType: 'failover_success',
        error: 'Failover completed in ${failoverLatency}ms',
        retryCount: 0,
      );

      return response;
    } catch (e) {
      // Gemini failover failed
      await _logFailoverEvent(
        provider: 'gemini',
        eventType: 'failover_failed',
        error: e.toString(),
        retryCount: 0,
      );

      throw AIServiceException('Gemini failover failed: ${e.toString()}');
    }
  }

  /// Execute request with timeout detection
  static Future<Map<String, dynamic>> _executeWithTimeout({
    required String provider,
    required String functionName,
    required Map<String, dynamic> params,
    required int timeoutMs,
  }) async {
    return await supabase.functions
        .invoke(functionName, body: {'provider': provider, ...params})
        .timeout(
          Duration(milliseconds: timeoutMs),
          onTimeout: () {
            throw TimeoutException(
              'Request timeout after ${timeoutMs}ms',
              Duration(milliseconds: timeoutMs),
            );
          },
        )
        .then((response) => response.data as Map<String, dynamic>);
  }

  /// Check if circuit breaker is open
  static bool _isCircuitBreakerOpen(String provider) {
    final health = _serviceHealth[provider];
    if (health == null) return false;

    // Circuit breaker opens if:
    // 1. 3 consecutive failures
    // 2. Error rate > 25%
    // 3. Response time > 10 seconds
    return health.consecutiveFailures >= circuitBreakerErrorThreshold ||
        health.errorRate > errorRateThreshold ||
        health.avgResponseTimeMs > responseTimeThreshold;
  }

  /// Check if provider is healthy
  static bool _isProviderHealthy(String provider) {
    final health = _serviceHealth[provider];
    if (health == null) return false;
    return health.status == 'healthy' || health.status == 'degraded';
  }

  /// Update service health status
  static Future<void> _updateServiceHealth({
    required String provider,
    required String status,
    required int latencyMs,
    required bool success,
  }) async {
    final health = _serviceHealth[provider];
    if (health == null) return;

    // Update request counts
    _requestCounts[provider] = (_requestCounts[provider] ?? 0) + 1;
    if (!success) {
      _errorCounts[provider] = (_errorCounts[provider] ?? 0) + 1;
    }

    // Calculate error rate
    final totalRequests = _requestCounts[provider] ?? 1;
    final totalErrors = _errorCounts[provider] ?? 0;
    final errorRate = totalErrors / totalRequests;

    // Update consecutive failures
    final consecutiveFailures = success ? 0 : health.consecutiveFailures + 1;

    // Calculate average response time
    final avgResponseTimeMs =
        ((health.avgResponseTimeMs * (totalRequests - 1)) + latencyMs) ~/
        totalRequests;

    // Update health status
    _serviceHealth[provider] = ServiceHealthStatus(
      provider: provider,
      status: status,
      lastCheckTime: DateTime.now(),
      consecutiveFailures: consecutiveFailures,
      errorRate: errorRate,
      avgResponseTimeMs: avgResponseTimeMs,
    );

    // Broadcast health update
    _healthStreamController.add(_serviceHealth);

    // Persist to database
    try {
      await supabase.from('ai_service_health').upsert({
        'provider': provider,
        'status': status,
        'last_check_time': DateTime.now().toIso8601String(),
        'consecutive_failures': consecutiveFailures,
        'error_rate': errorRate,
        'avg_response_time_ms': avgResponseTimeMs,
      });
    } catch (e) {
      // Ignore database errors
    }
  }

  /// Log failover event
  static Future<void> _logFailoverEvent({
    required String provider,
    required String eventType,
    required String error,
    required int retryCount,
  }) async {
    final event = FailoverEvent(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      provider: provider,
      eventType: eventType,
      error: error,
      retryCount: retryCount,
      timestamp: DateTime.now(),
    );

    _failoverHistory.add(event);

    // Keep only last 100 events in memory
    if (_failoverHistory.length > 100) {
      _failoverHistory.removeAt(0);
    }

    // Persist to database
    try {
      await supabase.from('ai_failover_events').insert({
        'provider': provider,
        'event_type': eventType,
        'error': error,
        'retry_count': retryCount,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      // Ignore database errors
    }
  }

  /// Get current service health
  static Map<String, ServiceHealthStatus> getCurrentHealth() {
    return Map.from(_serviceHealth);
  }

  /// Get health stream
  static Stream<Map<String, ServiceHealthStatus>> getHealthStream() {
    return _healthStreamController.stream;
  }

  /// Get failover history
  static Future<List<FailoverEvent>> getFailoverHistory({
    int limit = 20,
  }) async {
    try {
      final response = await supabase
          .from('ai_failover_events')
          .select()
          .order('timestamp', ascending: false)
          .limit(limit);

      return (response as List).map((e) => FailoverEvent.fromJson(e)).toList();
    } catch (e) {
      return _failoverHistory.take(limit).toList();
    }
  }

  /// Get traffic statistics
  static Future<Map<String, dynamic>> getTrafficStats() async {
    final totalRequests = _requestCounts.values.fold(0, (a, b) => a + b);
    final totalErrors = _errorCounts.values.fold(0, (a, b) => a + b);

    return {
      'total_requests': totalRequests,
      'total_errors': totalErrors,
      'error_rate': totalRequests > 0 ? totalErrors / totalRequests : 0.0,
      'provider_requests': Map.from(_requestCounts),
      'provider_errors': Map.from(_errorCounts),
      'pending_requests': _requestQueue.length,
    };
  }

  /// Perform health check on all providers
  static Future<void> performHealthCheck() async {
    for (var provider in ['openai', 'anthropic', 'perplexity', 'gemini']) {
      try {
        final startTime = DateTime.now();
        await _executeWithTimeout(
          provider: provider,
          functionName: 'health-check',
          params: {},
          timeoutMs: 5000,
        );
        final latency = DateTime.now().difference(startTime).inMilliseconds;

        await _updateServiceHealth(
          provider: provider,
          status: 'healthy',
          latencyMs: latency,
          success: true,
        );
      } catch (e) {
        await _updateServiceHealth(
          provider: provider,
          status: 'unhealthy',
          latencyMs: 5000,
          success: false,
        );
      }
    }
  }
}

/// Service health status model
class ServiceHealthStatus {
  final String provider;
  final String status; // healthy, degraded, unhealthy
  final DateTime lastCheckTime;
  final int consecutiveFailures;
  final double errorRate;
  final int avgResponseTimeMs;

  ServiceHealthStatus({
    required this.provider,
    required this.status,
    required this.lastCheckTime,
    required this.consecutiveFailures,
    required this.errorRate,
    required this.avgResponseTimeMs,
  });
}

/// Failover event model
class FailoverEvent {
  final String id;
  final String provider;
  final String eventType;
  final String error;
  final int retryCount;
  final DateTime timestamp;

  FailoverEvent({
    required this.id,
    required this.provider,
    required this.eventType,
    required this.error,
    required this.retryCount,
    required this.timestamp,
  });

  factory FailoverEvent.fromJson(Map<String, dynamic> json) {
    return FailoverEvent(
      id: json['id'] ?? '',
      provider: json['provider'] ?? '',
      eventType: json['event_type'] ?? '',
      error: json['error'] ?? '',
      retryCount: json['retry_count'] ?? 0,
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}

/// Pending request model
class PendingRequest {
  final String id;
  final String provider;
  final String functionName;
  final Map<String, dynamic> params;
  final DateTime timestamp;

  PendingRequest({
    required this.id,
    required this.provider,
    required this.functionName,
    required this.params,
    required this.timestamp,
  });
}

/// AI service exception
class AIServiceException implements Exception {
  final String message;
  AIServiceException(this.message);

  @override
  String toString() => 'AIServiceException: $message';
}
