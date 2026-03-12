import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import './supabase_service.dart';

class MLModelMonitoringService {
  static final MLModelMonitoringService _instance =
      MLModelMonitoringService._internal();
  factory MLModelMonitoringService() => _instance;
  MLModelMonitoringService._internal();

  final SupabaseClient _supabase = SupabaseService.instance.client;

  Future<Map<String, dynamic>> getModelOverview() async {
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);

      final predictions = await _supabase
          .from('model_predictions')
          .select()
          .gte('prediction_timestamp', startOfDay.toIso8601String());

      final latencyMetrics = await _supabase
          .from('model_latency_metrics')
          .select()
          .gte('timestamp', startOfDay.toIso8601String());

      final costTracking = await _supabase
          .from('model_cost_tracking')
          .select()
          .gte('timestamp', startOfDay.toIso8601String());

      final models = ['openai', 'anthropic', 'perplexity', 'gemini'];
      final modelStats = <String, Map<String, dynamic>>{};

      for (final model in models) {
        final modelPredictions = (predictions as List)
            .where((p) => p['model_name'] == model)
            .toList();
        final modelLatency = (latencyMetrics as List)
            .where((m) => m['model_name'] == model)
            .toList();
        final modelCosts = (costTracking as List)
            .where((c) => c['model_name'] == model)
            .toList();

        final avgAccuracy = modelPredictions.isEmpty
            ? 0.0
            : modelPredictions
                      .where((p) => p['accuracy_score'] != null)
                      .map((p) => (p['accuracy_score'] as num).toDouble())
                      .fold(0.0, (a, b) => a + b) /
                  modelPredictions
                      .where((p) => p['accuracy_score'] != null)
                      .length;

        final avgLatency = modelLatency.isEmpty
            ? 0
            : (modelLatency
                          .map((m) => m['latency_ms'] as int)
                          .fold(0, (a, b) => a + b) /
                      modelLatency.length)
                  .round();

        final dailyCost = modelCosts.isEmpty
            ? 0.0
            : modelCosts
                  .map((c) => (c['cost_usd'] as num).toDouble())
                  .fold(0.0, (a, b) => a + b);

        modelStats[model] = {
          'total_requests': modelPredictions.length,
          'avg_accuracy': avgAccuracy,
          'avg_latency': avgLatency,
          'daily_cost': dailyCost,
          'status': _getModelStatus(avgAccuracy, avgLatency),
        };
      }

      return modelStats;
    } catch (e) {
      throw Exception('Failed to fetch model overview: $e');
    }
  }

  String _getModelStatus(double accuracy, int latency) {
    if (accuracy >= 0.8 && latency < 1000) return 'good';
    if (accuracy >= 0.6 && latency < 2000) return 'degraded';
    return 'poor';
  }

  Future<Map<String, dynamic>> getAccuracyMetrics({
    required String modelName,
    int days = 30,
  }) async {
    try {
      final startDate = DateTime.now().subtract(Duration(days: days));

      final predictions = await _supabase
          .from('model_predictions')
          .select()
          .eq('model_name', modelName)
          .gte('prediction_timestamp', startDate.toIso8601String())
          .order('prediction_timestamp');

      final accuracyOverTime = <Map<String, dynamic>>[];
      final byOperationType = <String, List<double>>{};
      final failedPredictions = <Map<String, dynamic>>[];

      for (final pred in predictions as List) {
        if (pred['accuracy_score'] != null) {
          accuracyOverTime.add({
            'date': pred['prediction_timestamp'],
            'accuracy': pred['accuracy_score'],
          });

          final opType = pred['operation_type'] as String;
          byOperationType.putIfAbsent(opType, () => []);
          byOperationType[opType]!.add(
            (pred['accuracy_score'] as num).toDouble(),
          );

          if ((pred['accuracy_score'] as num) < 0.5) {
            failedPredictions.add(pred);
          }
        }
      }

      final avgByOperation = <String, double>{};
      byOperationType.forEach((key, values) {
        avgByOperation[key] = values.fold(0.0, (a, b) => a + b) / values.length;
      });

      return {
        'accuracy_over_time': accuracyOverTime,
        'by_operation_type': avgByOperation,
        'failed_predictions': failedPredictions.take(10).toList(),
      };
    } catch (e) {
      throw Exception('Failed to fetch accuracy metrics: $e');
    }
  }

  Future<Map<String, dynamic>> getLatencyTrends({
    required String modelName,
    int days = 30,
  }) async {
    try {
      final startDate = DateTime.now().subtract(Duration(days: days));

      final metrics = await _supabase
          .from('model_latency_metrics')
          .select()
          .eq('model_name', modelName)
          .gte('timestamp', startDate.toIso8601String())
          .order('timestamp');

      final latencies =
          (metrics as List).map((m) => m['latency_ms'] as int).toList()..sort();

      final p50 = latencies.isEmpty
          ? 0
          : latencies[(latencies.length * 0.5).floor()];
      final p95 = latencies.isEmpty
          ? 0
          : latencies[(latencies.length * 0.95).floor()];
      final p99 = latencies.isEmpty
          ? 0
          : latencies[(latencies.length * 0.99).floor()];

      final latencyOverTime = metrics
          .map((m) => {'date': m['timestamp'], 'latency': m['latency_ms']})
          .toList();

      final byOperation = <String, List<int>>{};
      for (final m in metrics) {
        final opType = m['operation_type'] as String;
        byOperation.putIfAbsent(opType, () => []);
        byOperation[opType]!.add(m['latency_ms'] as int);
      }

      final avgByOperation = <String, int>{};
      byOperation.forEach((key, values) {
        avgByOperation[key] = (values.fold(0, (a, b) => a + b) / values.length)
            .round();
      });

      return {
        'p50': p50,
        'p95': p95,
        'p99': p99,
        'latency_over_time': latencyOverTime,
        'by_operation': avgByOperation,
      };
    } catch (e) {
      throw Exception('Failed to fetch latency trends: $e');
    }
  }

  Future<Map<String, dynamic>> getCostAnalytics({
    required String modelName,
    int days = 30,
  }) async {
    try {
      final startDate = DateTime.now().subtract(Duration(days: days));

      final costs = await _supabase
          .from('model_cost_tracking')
          .select()
          .eq('model_name', modelName)
          .gte('timestamp', startDate.toIso8601String())
          .order('timestamp');

      final dailyCosts = <String, double>{};
      final byOperation = <String, double>{};

      for (final cost in costs as List) {
        final date = DateTime.parse(
          cost['timestamp'],
        ).toIso8601String().split('T')[0];
        final costValue = (cost['cost_usd'] as num).toDouble();
        final opType = cost['operation_type'] as String;

        dailyCosts[date] = (dailyCosts[date] ?? 0.0) + costValue;
        byOperation[opType] = (byOperation[opType] ?? 0.0) + costValue;
      }

      final totalCost = costs.isEmpty
          ? 0.0
          : costs
                .map((c) => (c['cost_usd'] as num).toDouble())
                .fold(0.0, (a, b) => a + b);

      return {
        'total_cost': totalCost,
        'daily_costs': dailyCosts,
        'by_operation': byOperation,
        'cost_trends': dailyCosts.entries
            .map((e) => {'date': e.key, 'cost': e.value})
            .toList(),
      };
    } catch (e) {
      throw Exception('Failed to fetch cost analytics: $e');
    }
  }

  Future<Map<String, dynamic>> getModelHealth() async {
    try {
      final health = await _supabase
          .from('model_health_status')
          .select()
          .order('last_check', ascending: false);

      return {'models': health};
    } catch (e) {
      throw Exception('Failed to fetch model health: $e');
    }
  }
}
