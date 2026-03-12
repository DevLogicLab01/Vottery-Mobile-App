import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';

/// AI Health Monitor Service
/// Continuous health checks every 2 seconds for all AI services
class AIHealthMonitorService {
  static AIHealthMonitorService? _instance;
  static AIHealthMonitorService get instance =>
      _instance ??= AIHealthMonitorService._();

  AIHealthMonitorService._();

  static final SupabaseClient _supabase = Supabase.instance.client;
  Timer? _healthCheckTimer;
  final Map<String, ServiceHealthStatus> _currentHealth = {};
  final StreamController<Map<String, ServiceHealthStatus>> _healthStream =
      StreamController.broadcast();

  /// Start continuous health monitoring
  void startMonitoring() {
    _healthCheckTimer?.cancel();
    _healthCheckTimer = Timer.periodic(
      const Duration(seconds: 2),
      (_) => _performHealthChecks(),
    );
  }

  /// Stop health monitoring
  void stopMonitoring() {
    _healthCheckTimer?.cancel();
  }

  /// Perform health checks for all AI services
  Future<void> _performHealthChecks() async {
    final services = ['openai', 'anthropic', 'perplexity', 'gemini'];

    for (final service in services) {
      await _checkServiceHealth(service);
    }

    _healthStream.add(Map.from(_currentHealth));
  }

  /// Check individual service health
  Future<void> _checkServiceHealth(String serviceName) async {
    final stopwatch = Stopwatch()..start();

    try {
      final response = await _supabase.functions
          .invoke('$serviceName-health-check', body: {'ping': 'test'})
          .timeout(const Duration(seconds: 2));

      stopwatch.stop();
      final responseTime = stopwatch.elapsedMilliseconds;

      if (response.status == 200) {
        await _recordHealthSuccess(serviceName, responseTime);
      } else {
        await _recordHealthFailure(
          serviceName,
          responseTime,
          'HTTP ${response.status}',
        );
      }
    } on TimeoutException {
      stopwatch.stop();
      await _recordHealthFailure(
        serviceName,
        stopwatch.elapsedMilliseconds,
        'Timeout after 2 seconds',
      );
    } catch (e) {
      stopwatch.stop();
      await _recordHealthFailure(
        serviceName,
        stopwatch.elapsedMilliseconds,
        e.toString(),
      );
    }
  }

  /// Record successful health check
  Future<void> _recordHealthSuccess(
    String serviceName,
    int responseTime,
  ) async {
    final current = _currentHealth[serviceName];
    final consecutiveFailures = 0;

    final healthScore = await _calculateHealthScore(serviceName);

    final status = ServiceHealthStatus(
      serviceName: serviceName,
      status: healthScore >= 80 ? 'healthy' : 'degraded',
      responseTimeMs: responseTime,
      consecutiveFailures: consecutiveFailures,
      healthScore: healthScore,
      lastCheckTime: DateTime.now(),
      errorMessage: null,
    );

    _currentHealth[serviceName] = status;

    await _supabase.from('ai_service_health_log').insert({
      'service_name': serviceName,
      'status': status.status,
      'response_time_ms': responseTime,
      'consecutive_failures': consecutiveFailures,
      'health_score': healthScore,
      'error_message': null,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Record failed health check
  Future<void> _recordHealthFailure(
    String serviceName,
    int responseTime,
    String errorMessage,
  ) async {
    final current = _currentHealth[serviceName];
    final consecutiveFailures = (current?.consecutiveFailures ?? 0) + 1;

    final healthScore = await _calculateHealthScore(serviceName);

    final status = ServiceHealthStatus(
      serviceName: serviceName,
      status: healthScore < 50 ? 'down' : 'degraded',
      responseTimeMs: responseTime,
      consecutiveFailures: consecutiveFailures,
      healthScore: healthScore,
      lastCheckTime: DateTime.now(),
      errorMessage: errorMessage,
    );

    _currentHealth[serviceName] = status;

    await _supabase.from('ai_service_health_log').insert({
      'service_name': serviceName,
      'status': status.status,
      'response_time_ms': responseTime,
      'consecutive_failures': consecutiveFailures,
      'health_score': healthScore,
      'error_message': errorMessage,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Calculate health score over rolling 5-minute window
  Future<double> _calculateHealthScore(String serviceName) async {
    try {
      final response = await _supabase.rpc(
        'get_service_health_score',
        params: {'target_service': serviceName, 'time_window_minutes': 5},
      );

      return (response as num).toDouble();
    } catch (e) {
      return 100.0;
    }
  }

  /// Get current health status
  Map<String, ServiceHealthStatus> getCurrentHealth() {
    return Map.from(_currentHealth);
  }

  /// Get health stream
  Stream<Map<String, ServiceHealthStatus>> getHealthStream() {
    return _healthStream.stream;
  }

  /// Check if service should trigger failover
  bool shouldTriggerFailover(String serviceName) {
    final health = _currentHealth[serviceName];
    if (health == null) return false;

    // Trigger failover after 2 consecutive failures within 4 seconds
    if (health.consecutiveFailures >= 2) {
      final timeSinceLastCheck = DateTime.now()
          .difference(health.lastCheckTime)
          .inSeconds;
      return timeSinceLastCheck <= 4;
    }

    return false;
  }
}

/// Service Health Status Model
class ServiceHealthStatus {
  final String serviceName;
  final String status;
  final int responseTimeMs;
  final int consecutiveFailures;
  final double healthScore;
  final DateTime lastCheckTime;
  final String? errorMessage;

  ServiceHealthStatus({
    required this.serviceName,
    required this.status,
    required this.responseTimeMs,
    required this.consecutiveFailures,
    required this.healthScore,
    required this.lastCheckTime,
    this.errorMessage,
  });

  factory ServiceHealthStatus.fromJson(Map<String, dynamic> json) {
    return ServiceHealthStatus(
      serviceName: json['service_name'] ?? '',
      status: json['status'] ?? 'unknown',
      responseTimeMs: json['response_time_ms'] ?? 0,
      consecutiveFailures: json['consecutive_failures'] ?? 0,
      healthScore: (json['health_score'] ?? 100.0).toDouble(),
      lastCheckTime: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
      errorMessage: json['error_message'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'service_name': serviceName,
      'status': status,
      'response_time_ms': responseTimeMs,
      'consecutive_failures': consecutiveFailures,
      'health_score': healthScore,
      'timestamp': lastCheckTime.toIso8601String(),
      'error_message': errorMessage,
    };
  }
}
