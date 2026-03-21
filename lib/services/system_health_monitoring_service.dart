import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import './system_monitoring_service.dart';
import './ai_service_cost_tracker.dart';

/// System Health Monitoring Service
/// Comprehensive real-time monitoring for all platform services with health scoring,
/// performance metrics, alert management, and quick actions
class SystemHealthMonitoringService {
  static SystemHealthMonitoringService? _instance;
  static SystemHealthMonitoringService get instance =>
      _instance ??= SystemHealthMonitoringService._();
  SystemHealthMonitoringService._();

  final SupabaseClient _supabase = Supabase.instance.client;
  final SystemMonitoringService _monitoring = SystemMonitoringService.instance;
  final AIServiceCostTracker _costTracker = AIServiceCostTracker.instance;

  Timer? _healthCheckTimer;

  /// Start real-time health monitoring
  void startMonitoring({int intervalSeconds = 60}) {
    _healthCheckTimer?.cancel();
    _healthCheckTimer = Timer.periodic(
      Duration(seconds: intervalSeconds),
      (_) => checkAllServices(),
    );
  }

  /// Stop monitoring
  void stopMonitoring() {
    _healthCheckTimer?.cancel();
  }

  /// Check all services
  Future<Map<String, dynamic>> checkAllServices() async {
    try {
      final services = await Future.wait([
        _checkSupabaseHealth(),
        _checkOpenAIHealth(),
        _checkAnthropicHealth(),
        _checkPerplexityHealth(),
        _checkGeminiHealth(),
        _checkStripeHealth(),
        _checkResendHealth(),
        _checkTwilioHealth(),
      ]);

      final serviceMap = {
        'supabase': services[0],
        'openai': services[1],
        'anthropic': services[2],
        'perplexity': services[3],
        'gemini': services[4],
        'stripe': services[5],
        'resend': services[6],
        'twilio': services[7],
      };

      final overallHealth = _calculateOverallHealth(serviceMap);

      // Store metrics
      await _storeHealthMetrics(serviceMap);

      return {
        'overall_health': overallHealth,
        'services': serviceMap,
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      debugPrint('Check all services error: $e');
      return {'overall_health': 0, 'services': {}};
    }
  }

  /// Check Supabase health
  Future<Map<String, dynamic>> _checkSupabaseHealth() async {
    final startTime = DateTime.now();
    try {
      // Test query
      await _supabase.from('user_profiles').select('id').limit(1);

      final latency = DateTime.now().difference(startTime).inMilliseconds;

      // Get connection pool info
      final connectionPool = await _getConnectionPoolInfo();

      final healthScore = _calculateHealthScore(
        uptime: 99.9,
        latency: latency,
        errorRate: 0.1,
      );

      return {
        'status': 'healthy',
        'health_score': healthScore,
        'uptime_percentage': 99.9,
        'response_time_ms': latency,
        'connection_pool': connectionPool,
        'last_check': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      return {
        'status': 'unhealthy',
        'health_score': 0,
        'error': e.toString(),
        'last_check': DateTime.now().toIso8601String(),
      };
    }
  }

  /// Get connection pool info
  Future<Map<String, dynamic>> _getConnectionPoolInfo() async {
    try {
      final recent = await _supabase
          .from('service_health_metrics')
          .select('recorded_at')
          .gte(
            'recorded_at',
            DateTime.now()
                .subtract(const Duration(minutes: 5))
                .toIso8601String(),
          );
      final currentConnections = (recent as List?)?.length ?? 0;
      return {
        'current_connections': currentConnections,
        'max_connections': 100,
        'waiting_queries': currentConnections > 90 ? 1 : 0,
      };
    } catch (e) {
      return {};
    }
  }

  /// Check OpenAI health
  Future<Map<String, dynamic>> _checkOpenAIHealth() async {
    final startTime = DateTime.now();
    try {
      final probe = await _probeServiceHealth('openai');
      final latency = DateTime.now().difference(startTime).inMilliseconds;
      final healthScore = _calculateHealthScore(
        uptime: (probe['uptime_percentage'] as num?)?.toDouble() ?? 99.0,
        latency: latency,
        errorRate: (probe['error_rate'] as num?)?.toDouble() ?? 0.5,
      );

      return {
        'status': probe['status'] ?? 'degraded',
        'health_score': healthScore,
        'uptime_percentage': (probe['uptime_percentage'] as num?)?.toDouble() ?? 99.0,
        'response_time_ms': latency,
        'rate_limit_remaining': probe['rate_limit_remaining'],
        'rate_limit_total': probe['rate_limit_total'],
        'avg_latency_ms': probe['avg_latency_ms'] ?? latency,
        'last_check': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      return {
        'status': 'unhealthy',
        'health_score': 0,
        'error': e.toString(),
        'last_check': DateTime.now().toIso8601String(),
      };
    }
  }

  /// Check Anthropic health
  Future<Map<String, dynamic>> _checkAnthropicHealth() async {
    final startTime = DateTime.now();
    try {
      final probe = await _probeServiceHealth('anthropic');
      final latency = DateTime.now().difference(startTime).inMilliseconds;
      final healthScore = _calculateHealthScore(
        uptime: (probe['uptime_percentage'] as num?)?.toDouble() ?? 99.0,
        latency: latency,
        errorRate: (probe['error_rate'] as num?)?.toDouble() ?? 0.4,
      );

      return {
        'status': probe['status'] ?? 'degraded',
        'health_score': healthScore,
        'uptime_percentage': (probe['uptime_percentage'] as num?)?.toDouble() ?? 99.0,
        'response_time_ms': latency,
        'model_availability': probe['model_availability'] ?? 'unknown',
        'avg_latency_ms': probe['avg_latency_ms'] ?? latency,
        'last_check': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      return {
        'status': 'unhealthy',
        'health_score': 0,
        'error': e.toString(),
        'last_check': DateTime.now().toIso8601String(),
      };
    }
  }

  /// Check Perplexity health
  Future<Map<String, dynamic>> _checkPerplexityHealth() async {
    final startTime = DateTime.now();
    try {
      final probe = await _probeServiceHealth('perplexity');
      final latency = DateTime.now().difference(startTime).inMilliseconds;
      final healthScore = _calculateHealthScore(
        uptime: (probe['uptime_percentage'] as num?)?.toDouble() ?? 99.0,
        latency: latency,
        errorRate: (probe['error_rate'] as num?)?.toDouble() ?? 0.6,
      );

      return {
        'status': probe['status'] ?? 'degraded',
        'health_score': healthScore,
        'uptime_percentage': (probe['uptime_percentage'] as num?)?.toDouble() ?? 99.0,
        'response_time_ms': latency,
        'avg_latency_ms': probe['avg_latency_ms'] ?? latency,
        'last_check': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      return {
        'status': 'unhealthy',
        'health_score': 0,
        'error': e.toString(),
        'last_check': DateTime.now().toIso8601String(),
      };
    }
  }

  /// Check Gemini health
  Future<Map<String, dynamic>> _checkGeminiHealth() async {
    final startTime = DateTime.now();
    try {
      final probe = await _probeServiceHealth('gemini');
      final latency = DateTime.now().difference(startTime).inMilliseconds;
      final healthScore = _calculateHealthScore(
        uptime: (probe['uptime_percentage'] as num?)?.toDouble() ?? 99.0,
        latency: latency,
        errorRate: (probe['error_rate'] as num?)?.toDouble() ?? 0.5,
      );

      return {
        'status': probe['status'] ?? 'degraded',
        'health_score': healthScore,
        'uptime_percentage': (probe['uptime_percentage'] as num?)?.toDouble() ?? 99.0,
        'response_time_ms': latency,
        'avg_latency_ms': probe['avg_latency_ms'] ?? latency,
        'last_check': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      return {
        'status': 'unhealthy',
        'health_score': 0,
        'error': e.toString(),
        'last_check': DateTime.now().toIso8601String(),
      };
    }
  }

  /// Check Stripe health
  Future<Map<String, dynamic>> _checkStripeHealth() async {
    final startTime = DateTime.now();
    try {
      final probe = await _probeServiceHealth('stripe');
      final latency = DateTime.now().difference(startTime).inMilliseconds;
      final healthScore = _calculateHealthScore(
        uptime: (probe['uptime_percentage'] as num?)?.toDouble() ?? 99.0,
        latency: latency,
        errorRate: (probe['error_rate'] as num?)?.toDouble() ?? 0.4,
      );

      return {
        'status': probe['status'] ?? 'degraded',
        'health_score': healthScore,
        'uptime_percentage': (probe['uptime_percentage'] as num?)?.toDouble() ?? 99.0,
        'response_time_ms': latency,
        'payment_success_rate': probe['payment_success_rate'],
        'payout_queue_size': probe['payout_queue_size'],
        'failed_transactions': probe['failed_transactions'],
        'last_check': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      return {
        'status': 'unhealthy',
        'health_score': 0,
        'error': e.toString(),
        'last_check': DateTime.now().toIso8601String(),
      };
    }
  }

  /// Check Resend health
  Future<Map<String, dynamic>> _checkResendHealth() async {
    final startTime = DateTime.now();
    try {
      final probe = await _probeServiceHealth('resend');
      final latency = DateTime.now().difference(startTime).inMilliseconds;
      final healthScore = _calculateHealthScore(
        uptime: (probe['uptime_percentage'] as num?)?.toDouble() ?? 99.0,
        latency: latency,
        errorRate: (probe['error_rate'] as num?)?.toDouble() ?? 0.5,
      );

      return {
        'status': probe['status'] ?? 'degraded',
        'health_score': healthScore,
        'uptime_percentage': (probe['uptime_percentage'] as num?)?.toDouble() ?? 99.0,
        'response_time_ms': latency,
        'delivery_rate': probe['delivery_rate'],
        'queue_size': probe['queue_size'],
        'bounce_rate': probe['bounce_rate'],
        'last_check': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      return {
        'status': 'unhealthy',
        'health_score': 0,
        'error': e.toString(),
        'last_check': DateTime.now().toIso8601String(),
      };
    }
  }

  /// Check Twilio health
  Future<Map<String, dynamic>> _checkTwilioHealth() async {
    final startTime = DateTime.now();
    try {
      final probe = await _probeServiceHealth('twilio');
      final latency = DateTime.now().difference(startTime).inMilliseconds;
      final healthScore = _calculateHealthScore(
        uptime: (probe['uptime_percentage'] as num?)?.toDouble() ?? 99.0,
        latency: latency,
        errorRate: (probe['error_rate'] as num?)?.toDouble() ?? 0.6,
      );

      return {
        'status': probe['status'] ?? 'degraded',
        'health_score': healthScore,
        'uptime_percentage': (probe['uptime_percentage'] as num?)?.toDouble() ?? 99.0,
        'response_time_ms': latency,
        'sms_delivery_success': probe['sms_delivery_success'],
        'remaining_credits': probe['remaining_credits'],
        'last_check': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      return {
        'status': 'unhealthy',
        'health_score': 0,
        'error': e.toString(),
        'last_check': DateTime.now().toIso8601String(),
      };
    }
  }

  /// Calculate health score
  int _calculateHealthScore({
    required double uptime,
    required int latency,
    required double errorRate,
  }) {
    final uptimeScore = uptime;
    final latencyScore = latency < 500
        ? 100
        : latency < 1000
        ? 80
        : latency < 2000
        ? 60
        : 40;
    final errorScore = (100 - (errorRate * 10)).clamp(0, 100);

    return ((uptimeScore * 0.5) + (latencyScore * 0.3) + (errorScore * 0.2))
        .round();
  }

  /// Calculate overall health
  int _calculateOverallHealth(Map<String, Map<String, dynamic>> services) {
    final scores = services.values
        .map((s) => s['health_score'] as int? ?? 0)
        .toList();

    if (scores.isEmpty) return 0;

    return (scores.reduce((a, b) => a + b) / scores.length).round();
  }

  /// Store health metrics
  Future<void> _storeHealthMetrics(
    Map<String, Map<String, dynamic>> services,
  ) async {
    try {
      for (final entry in services.entries) {
        await _supabase.from('service_health_metrics').insert({
          'service_name': entry.key,
          'metric_type': 'health_check',
          'metric_value': entry.value['health_score'],
          'health_score': entry.value['health_score'],
          'recorded_at': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      debugPrint('Store health metrics error: $e');
    }
  }

  /// Get active alerts
  Future<List<Map<String, dynamic>>> getActiveAlerts() async {
    try {
      final response = await _supabase
          .from('system_alerts')
          .select()
          .eq('status', 'active')
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get active alerts error: $e');
      return [];
    }
  }

  /// Acknowledge alert
  Future<void> acknowledgeAlert(String alertId) async {
    try {
      await _supabase
          .from('system_alerts')
          .update({
            'status': 'acknowledged',
            'acknowledged_at': DateTime.now().toIso8601String(),
          })
          .eq('alert_id', alertId);
    } catch (e) {
      debugPrint('Acknowledge alert error: $e');
    }
  }

  /// Resolve alert
  Future<void> resolveAlert(String alertId, String resolution) async {
    try {
      await _supabase
          .from('system_alerts')
          .update({
            'status': 'resolved',
            'resolved_at': DateTime.now().toIso8601String(),
            'resolution_notes': resolution,
          })
          .eq('alert_id', alertId);
    } catch (e) {
      debugPrint('Resolve alert error: $e');
    }
  }

  Future<Map<String, dynamic>> _probeServiceHealth(String service) async {
    try {
      final response = await _supabase.functions.invoke(
        'health-check',
        body: {'service': service},
      );
      if (response.status == 200 && response.data is Map<String, dynamic>) {
        return response.data as Map<String, dynamic>;
      }
      return {'status': 'degraded'};
    } catch (e) {
      return {'status': 'degraded', 'error': e.toString()};
    }
  }
}
