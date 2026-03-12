import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import './supabase_service.dart';
import './claude_service.dart';

/// Carousel Health & Scaling Service
/// Monitors infrastructure, auto-scaling, query optimization, and predictive alerts
class CarouselHealthScalingService {
  static CarouselHealthScalingService? _instance;
  static CarouselHealthScalingService get instance =>
      _instance ??= CarouselHealthScalingService._();

  CarouselHealthScalingService._();

  final SupabaseService _supabaseService = SupabaseService.instance;
  final ClaudeService _claudeService = ClaudeService.instance;

  // ============================================
  // INFRASTRUCTURE METRICS
  // ============================================

  /// Record infrastructure metric
  Future<void> recordMetric({
    required String category,
    required String metricName,
    required double value,
    double? thresholdWarning,
    double? thresholdCritical,
    String? unit,
  }) async {
    try {
      await _supabaseService.client
          .from('carousel_infrastructure_metrics')
          .insert({
            'metric_category': category,
            'metric_name': metricName,
            'metric_value': value,
            'threshold_warning': thresholdWarning,
            'threshold_critical': thresholdCritical,
            'unit': unit,
          });
    } catch (e) {
      debugPrint('Error recording metric: $e');
    }
  }

  /// Get infrastructure metrics by category
  Future<List<Map<String, dynamic>>> getMetricsByCategory({
    required String category,
    int hours = 24,
  }) async {
    try {
      final startTime = DateTime.now().subtract(Duration(hours: hours));

      final response = await _supabaseService.client
          .from('carousel_infrastructure_metrics')
          .select()
          .eq('metric_category', category)
          .gte('recorded_at', startTime.toIso8601String())
          .order('recorded_at', ascending: false);

      return (response as List<dynamic>).cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('Error getting metrics by category: $e');
      return [];
    }
  }

  /// Get system capacity overview
  Future<Map<String, dynamic>> getSystemCapacityOverview() async {
    try {
      final databaseMetrics = await getMetricsByCategory(
        category: 'database',
        hours: 1,
      );
      final applicationMetrics = await getMetricsByCategory(
        category: 'application',
        hours: 1,
      );
      final cdnMetrics = await getMetricsByCategory(category: 'cdn', hours: 1);
      final cacheMetrics = await getMetricsByCategory(
        category: 'cache',
        hours: 1,
      );

      return {
        'database': _summarizeMetrics(databaseMetrics),
        'application': _summarizeMetrics(applicationMetrics),
        'cdn': _summarizeMetrics(cdnMetrics),
        'cache': _summarizeMetrics(cacheMetrics),
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      debugPrint('Error getting system capacity overview: $e');
      return {};
    }
  }

  Map<String, dynamic> _summarizeMetrics(List<Map<String, dynamic>> metrics) {
    if (metrics.isEmpty) {
      return {'status': 'no_data', 'metrics': []};
    }

    final summary = <String, dynamic>{};
    for (var metric in metrics) {
      final name = metric['metric_name'] as String;
      final value = (metric['metric_value'] as num).toDouble();
      final warningThreshold = (metric['threshold_warning'] as num?)
          ?.toDouble();
      final criticalThreshold = (metric['threshold_critical'] as num?)
          ?.toDouble();

      String status = 'healthy';
      if (criticalThreshold != null && value >= criticalThreshold) {
        status = 'critical';
      } else if (warningThreshold != null && value >= warningThreshold) {
        status = 'warning';
      }

      summary[name] = {
        'value': value,
        'status': status,
        'unit': metric['unit'],
      };
    }

    return summary;
  }

  // ============================================
  // AUTO-SCALING
  // ============================================

  /// Record auto-scaling event
  Future<void> recordScalingEvent({
    required String triggerMetric,
    required double triggerValue,
    required double thresholdValue,
    required String scalingAction,
    required String actionResult,
    Map<String, dynamic>? newCapacity,
    double? costImpact,
    String? errorMessage,
  }) async {
    try {
      await _supabaseService.client
          .from('carousel_auto_scaling_events')
          .insert({
            'trigger_metric': triggerMetric,
            'trigger_value': triggerValue,
            'threshold_value': thresholdValue,
            'scaling_action': scalingAction,
            'action_result': actionResult,
            'new_capacity': newCapacity,
            'cost_impact': costImpact,
            'completed_at': DateTime.now().toIso8601String(),
            'error_message': errorMessage,
          });
    } catch (e) {
      debugPrint('Error recording scaling event: $e');
    }
  }

  /// Get scaling history
  Future<List<Map<String, dynamic>>> getScalingHistory({int days = 7}) async {
    try {
      final startDate = DateTime.now().subtract(Duration(days: days));

      final response = await _supabaseService.client
          .from('carousel_auto_scaling_events')
          .select()
          .gte('triggered_at', startDate.toIso8601String())
          .order('triggered_at', ascending: false);

      return (response as List<dynamic>).cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('Error getting scaling history: $e');
      return [];
    }
  }

  // ============================================
  // QUERY OPTIMIZATION
  // ============================================

  /// Record query performance
  Future<void> recordQueryPerformance({
    required String queryText,
    String? queryType,
    required int executionTimeMs,
    int? p95ExecutionTimeMs,
  }) async {
    try {
      final existing = await _supabaseService.client
          .from('carousel_query_performance')
          .select()
          .eq('query_text', queryText)
          .maybeSingle();

      if (existing != null) {
        final callCount = (existing['call_count'] as int) + 1;
        final totalTime = (existing['total_time_ms'] as int) + executionTimeMs;
        final avgTime = (totalTime / callCount).round();

        await _supabaseService.client
            .from('carousel_query_performance')
            .update({
              'avg_execution_time_ms': avgTime,
              'p95_execution_time_ms': p95ExecutionTimeMs,
              'call_count': callCount,
              'total_time_ms': totalTime,
              'last_execution': DateTime.now().toIso8601String(),
            })
            .eq('query_id', existing['query_id']);
      } else {
        await _supabaseService.client
            .from('carousel_query_performance')
            .insert({
              'query_text': queryText,
              'query_type': queryType,
              'avg_execution_time_ms': executionTimeMs,
              'p95_execution_time_ms': p95ExecutionTimeMs,
              'call_count': 1,
              'total_time_ms': executionTimeMs,
              'last_execution': DateTime.now().toIso8601String(),
            });
      }
    } catch (e) {
      debugPrint('Error recording query performance: $e');
    }
  }

  /// Get slow queries
  Future<List<Map<String, dynamic>>> getSlowQueries({
    int thresholdMs = 500,
    int limit = 20,
  }) async {
    try {
      final response = await _supabaseService.client
          .from('carousel_query_performance')
          .select()
          .gte('avg_execution_time_ms', thresholdMs)
          .order('avg_execution_time_ms', ascending: false)
          .limit(limit);

      return (response as List<dynamic>).cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('Error getting slow queries: $e');
      return [];
    }
  }

  /// Get query optimization suggestions from Claude
  Future<Map<String, dynamic>> getQueryOptimizationSuggestions({
    required String queryText,
    required int avgExecutionTimeMs,
  }) async {
    try {
      final prompt =
          '''
Analyze this slow database query and provide optimization suggestions:

Query: $queryText
Average Execution Time: ${avgExecutionTimeMs}ms

Provide suggestions in JSON format:
{
  "suggested_indexes": ["CREATE INDEX idx_name ON table(column)"],
  "query_rewrite": "optimized query text",
  "expected_improvement": "percentage",
  "explanation": "why this optimization helps"
}
''';

      final response = await _claudeService.callClaudeAPI(prompt);
      return jsonDecode(response) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Error getting query optimization suggestions: $e');
      return {
        'suggested_indexes': [],
        'query_rewrite': queryText,
        'expected_improvement': '0%',
        'explanation': 'Unable to generate suggestions',
      };
    }
  }

  // ============================================
  // BOTTLENECK DETECTION
  // ============================================

  /// Record bottleneck
  Future<void> recordBottleneck({
    required String bottleneckType,
    String? carouselType,
    required String severity,
    int? affectedUsersEstimate,
    int? latencyP50,
    int? latencyP95,
    int? latencyP99,
    String? rootCause,
    Map<String, dynamic>? recommendedFixes,
  }) async {
    try {
      await _supabaseService.client.from('carousel_bottlenecks').insert({
        'bottleneck_type': bottleneckType,
        'carousel_type': carouselType,
        'severity': severity,
        'affected_users_estimate': affectedUsersEstimate,
        'latency_p50': latencyP50,
        'latency_p95': latencyP95,
        'latency_p99': latencyP99,
        'root_cause': rootCause,
        'recommended_fixes': recommendedFixes,
      });
    } catch (e) {
      debugPrint('Error recording bottleneck: $e');
    }
  }

  /// Get active bottlenecks
  Future<List<Map<String, dynamic>>> getActiveBottlenecks() async {
    try {
      final response = await _supabaseService.client
          .from('carousel_bottlenecks')
          .select()
          .isFilter('resolved_at', null)
          .order('severity', ascending: false)
          .order('detected_at', ascending: false);

      return (response as List<dynamic>).cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('Error getting active bottlenecks: $e');
      return [];
    }
  }

  // ============================================
  // PREDICTIVE ALERTS
  // ============================================

  /// Create predictive alert
  Future<void> createPredictiveAlert({
    required String alertType,
    required String metricName,
    required double currentValue,
    required double thresholdValue,
    DateTime? predictedViolationDate,
    double? confidenceLevel,
    Map<String, dynamic>? trendData,
    List<String>? recommendedActions,
  }) async {
    try {
      await _supabaseService.client.from('carousel_predictive_alerts').insert({
        'alert_type': alertType,
        'metric_name': metricName,
        'current_value': currentValue,
        'threshold_value': thresholdValue,
        'predicted_violation_date': predictedViolationDate?.toIso8601String(),
        'confidence_level': confidenceLevel,
        'trend_data': trendData,
        'recommended_actions': recommendedActions,
      });
    } catch (e) {
      debugPrint('Error creating predictive alert: $e');
    }
  }

  /// Get active predictive alerts
  Future<List<Map<String, dynamic>>> getActivePredictiveAlerts() async {
    try {
      final response = await _supabaseService.client
          .from('carousel_predictive_alerts')
          .select()
          .eq('status', 'active')
          .order('predicted_violation_date', ascending: true);

      return (response as List<dynamic>).cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('Error getting active predictive alerts: $e');
      return [];
    }
  }

  /// Analyze metric trends for prediction
  Future<Map<String, dynamic>> analyzeMetricTrends({
    required String metricName,
    required String category,
    int days = 7,
  }) async {
    try {
      final metrics = await getMetricsByCategory(
        category: category,
        hours: days * 24,
      );
      final relevantMetrics = metrics
          .where((m) => m['metric_name'] == metricName)
          .toList();

      if (relevantMetrics.length < 3) {
        return {'trend': 'insufficient_data'};
      }

      final values = relevantMetrics
          .map((m) => (m['metric_value'] as num).toDouble())
          .toList();

      final avgValue = values.reduce((a, b) => a + b) / values.length;
      final firstHalf = values.sublist(0, values.length ~/ 2);
      final secondHalf = values.sublist(values.length ~/ 2);
      final firstAvg = firstHalf.reduce((a, b) => a + b) / firstHalf.length;
      final secondAvg = secondHalf.reduce((a, b) => a + b) / secondHalf.length;

      final trendDirection = secondAvg > firstAvg ? 'increasing' : 'decreasing';
      final trendRate = ((secondAvg - firstAvg) / firstAvg * 100).abs();

      return {
        'metric_name': metricName,
        'trend_direction': trendDirection,
        'trend_rate': trendRate,
        'current_value': values.last,
        'avg_value': avgValue,
        'data_points': values.length,
      };
    } catch (e) {
      debugPrint('Error analyzing metric trends: $e');
      return {'trend': 'error'};
    }
  }

  // ============================================
  // HEALTH SCORES
  // ============================================

  /// Calculate overall health score
  Future<Map<String, dynamic>> calculateHealthScore() async {
    try {
      final capacityOverview = await getSystemCapacityOverview();
      final activeBottlenecks = await getActiveBottlenecks();
      final slowQueries = await getSlowQueries(limit: 10);

      double databaseScore = _calculateComponentScore(
        capacityOverview['database'] as Map<String, dynamic>? ?? {},
      );
      double applicationScore = _calculateComponentScore(
        capacityOverview['application'] as Map<String, dynamic>? ?? {},
      );
      double deliveryScore = _calculateComponentScore(
        capacityOverview['cdn'] as Map<String, dynamic>? ?? {},
      );

      // Penalize for bottlenecks
      final criticalBottlenecks = activeBottlenecks
          .where((b) => b['severity'] == 'critical')
          .length;
      final highBottlenecks = activeBottlenecks
          .where((b) => b['severity'] == 'high')
          .length;
      final bottleneckPenalty =
          (criticalBottlenecks * 10) + (highBottlenecks * 5);

      // Penalize for slow queries
      final queryPenalty = slowQueries.length * 2;

      final overallScore =
          ((databaseScore * 0.4) +
                  (applicationScore * 0.3) +
                  (deliveryScore * 0.3) -
                  bottleneckPenalty -
                  queryPenalty)
              .clamp(0, 100)
              .toDouble();

      return {
        'overall_score': overallScore,
        'database_score': databaseScore,
        'application_score': applicationScore,
        'delivery_score': deliveryScore,
        'active_bottlenecks': activeBottlenecks.length,
        'slow_queries': slowQueries.length,
        'status': _getHealthStatus(overallScore),
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      debugPrint('Error calculating health score: $e');
      return {'overall_score': 0, 'status': 'error'};
    }
  }

  double _calculateComponentScore(Map<String, dynamic> metrics) {
    if (metrics.isEmpty || metrics['status'] == 'no_data') {
      return 50.0; // Neutral score for no data
    }

    int healthyCount = 0;
    int warningCount = 0;
    int criticalCount = 0;
    int totalCount = 0;

    for (var entry in metrics.entries) {
      if (entry.value is Map && (entry.value as Map).containsKey('status')) {
        totalCount++;
        final status = (entry.value as Map)['status'] as String;
        if (status == 'healthy') healthyCount++;
        if (status == 'warning') warningCount++;
        if (status == 'critical') criticalCount++;
      }
    }

    if (totalCount == 0) return 50.0;

    return ((healthyCount * 100) + (warningCount * 60) + (criticalCount * 20)) /
        totalCount;
  }

  String _getHealthStatus(double score) {
    if (score >= 80) return 'healthy';
    if (score >= 60) return 'warning';
    return 'critical';
  }
}