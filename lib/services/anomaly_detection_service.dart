import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import './supabase_service.dart';
import './slack_notification_service.dart';
import './pagerduty_service.dart';

class AnomalyDetectionService {
  static AnomalyDetectionService? _instance;
  static AnomalyDetectionService get instance =>
      _instance ??= AnomalyDetectionService._();

  AnomalyDetectionService._();

  SupabaseClient get _client => SupabaseService.instance.client;

  /// Calculate performance baselines from historical data
  Future<bool> calculateBaselines({int periodDays = 30}) async {
    try {
      final endDate = DateTime.now();
      final startDate = endDate.subtract(Duration(days: periodDays));

      // Query datadog_traces table for historical data
      final traces = await _client
          .from('datadog_traces')
          .select()
          .gte('timestamp', startDate.toIso8601String())
          .lte('timestamp', endDate.toIso8601String())
          .inFilter('operation_type', [
            'api_call',
            'database_query',
            'ai_service_call',
          ]);

      if (traces.isEmpty) {
        debugPrint('No trace data found for baseline calculation');
        return false;
      }

      // Group by operation_name and calculate percentiles
      final operationGroups = <String, List<double>>{};
      final operationTypes = <String, String>{};

      for (final trace in traces) {
        final operationName = trace['operation_name'] as String;
        final operationType = trace['operation_type'] as String;
        final duration = (trace['duration_ms'] as num).toDouble();

        if (!operationGroups.containsKey(operationName)) {
          operationGroups[operationName] = [];
          operationTypes[operationName] = operationType;
        }
        operationGroups[operationName]!.add(duration);
      }

      // Calculate and store baselines
      for (final entry in operationGroups.entries) {
        final operationName = entry.key;
        final durations = entry.value..sort();
        final operationType = operationTypes[operationName]!;

        final p50 = _calculatePercentile(durations, 0.50);
        final p95 = _calculatePercentile(durations, 0.95);
        final p99 = _calculatePercentile(durations, 0.99);
        final sampleCount = durations.length;

        // Calculate confidence score
        final confidenceScore = await _client.rpc(
          'calculate_baseline_confidence',
          params: {'sample_count': sampleCount},
        );

        // Upsert baseline
        await _client.from('performance_baselines').upsert({
          'operation_name': operationName,
          'operation_type': operationType,
          'p50_baseline_ms': p50,
          'p95_baseline_ms': p95,
          'p99_baseline_ms': p99,
          'sample_count': sampleCount,
          'baseline_period_start': startDate.toIso8601String(),
          'baseline_period_end': endDate.toIso8601String(),
          'calculated_at': DateTime.now().toIso8601String(),
          'confidence_score': confidenceScore,
        });
      }

      debugPrint(
        'Baselines calculated for ${operationGroups.length} operations',
      );
      return true;
    } catch (e) {
      debugPrint('Calculate baselines error: $e');
      return false;
    }
  }

  /// Detect anomalies by comparing current performance against baselines
  Future<List<Map<String, dynamic>>> detectAnomalies() async {
    try {
      final fiveMinutesAgo = DateTime.now().subtract(
        const Duration(minutes: 5),
      );

      // Get recent traces
      final recentTraces = await _client
          .from('datadog_traces')
          .select()
          .gte('timestamp', fiveMinutesAgo.toIso8601String());

      if (recentTraces.isEmpty) {
        return [];
      }

      // Group by operation and calculate current P95
      final operationMetrics = <String, List<double>>{};

      for (final trace in recentTraces) {
        final operationName = trace['operation_name'] as String;
        final duration = (trace['duration_ms'] as num).toDouble();

        if (!operationMetrics.containsKey(operationName)) {
          operationMetrics[operationName] = [];
        }
        operationMetrics[operationName]!.add(duration);
      }

      final anomalies = <Map<String, dynamic>>[];

      // Compare against baselines
      for (final entry in operationMetrics.entries) {
        final operationName = entry.key;
        final durations = entry.value..sort();
        final currentP95 = _calculatePercentile(durations, 0.95);

        // Get baseline
        final baseline = await _client
            .from('performance_baselines')
            .select()
            .eq('operation_name', operationName)
            .maybeSingle();

        if (baseline == null) continue;

        final baselineP95 = (baseline['p95_baseline_ms'] as num).toDouble();
        final deviationPercentage =
            ((currentP95 - baselineP95) / baselineP95) * 100;

        // Check if deviation exceeds threshold (150%)
        if (deviationPercentage > 150) {
          // Determine severity
          final severity = await _client.rpc(
            'determine_anomaly_severity',
            params: {'deviation_percentage': deviationPercentage},
          );

          // Create anomaly record
          final anomaly = await _client
              .from('performance_anomalies')
              .insert({
                'operation_name': operationName,
                'detected_at': DateTime.now().toIso8601String(),
                'baseline_p95_ms': baselineP95,
                'current_p95_ms': currentP95,
                'deviation_percentage': deviationPercentage,
                'severity': severity,
                'alert_sent': false,
                'acknowledged': false,
                'affected_requests': durations.length,
              })
              .select()
              .single();

          anomalies.add(anomaly);

          // Send alerts based on severity
          await _routeAnomalyAlert(anomaly);
        }
      }

      return anomalies;
    } catch (e) {
      debugPrint('Detect anomalies error: $e');
      return [];
    }
  }

  /// Route anomaly alerts based on severity
  Future<void> _routeAnomalyAlert(Map<String, dynamic> anomaly) async {
    try {
      final severity = anomaly['severity'] as String;
      final anomalyId = anomaly['anomaly_id'] as String;

      if (severity == 'critical') {
        // Create PagerDuty incident for critical anomalies
        await PagerDutyService.instance.createPagerDutyIncident(
          incidentId: anomalyId,
          title: 'Critical Performance Anomaly: ${anomaly['operation_name']}',
          description:
              'P95 latency increased from ${anomaly['baseline_p95_ms']}ms to ${anomaly['current_p95_ms']}ms (+${anomaly['deviation_percentage'].toStringAsFixed(1)}%)',
          severity: 'critical',
          incidentData: {
            'incident_type': 'performance_anomaly',
            'affected_resource': anomaly['operation_name'],
            'anomaly_id': anomalyId,
          },
        );
      } else if (severity == 'high') {
        // Send Slack notification for high severity
        await SlackNotificationService.instance.sendPerformanceAlert(
          anomaly: anomaly,
        );
      }
      // Medium severity: log only, no immediate notification

      // Mark alert as sent
      await _client
          .from('performance_anomalies')
          .update({'alert_sent': true})
          .eq('anomaly_id', anomalyId);
    } catch (e) {
      debugPrint('Route anomaly alert error: $e');
    }
  }

  /// Calculate percentile from sorted list
  double _calculatePercentile(List<double> sortedValues, double percentile) {
    if (sortedValues.isEmpty) return 0;
    final index = (sortedValues.length * percentile).floor();
    return sortedValues[index.clamp(0, sortedValues.length - 1)];
  }

  /// Get active anomalies
  Future<List<Map<String, dynamic>>> getActiveAnomalies() async {
    try {
      final anomalies = await _client
          .from('performance_anomalies')
          .select()
          .eq('acknowledged', false)
          .order('detected_at', ascending: false)
          .limit(50);

      return List<Map<String, dynamic>>.from(anomalies);
    } catch (e) {
      debugPrint('Get active anomalies error: $e');
      return [];
    }
  }

  /// Acknowledge anomaly
  Future<bool> acknowledgeAnomaly(
    String anomalyId,
    String userId,
    String? notes,
  ) async {
    try {
      await _client
          .from('performance_anomalies')
          .update({
            'acknowledged': true,
            'acknowledged_by': userId,
            'acknowledged_at': DateTime.now().toIso8601String(),
            'root_cause_analysis': notes != null ? {'notes': notes} : null,
          })
          .eq('anomaly_id', anomalyId);

      return true;
    } catch (e) {
      debugPrint('Acknowledge anomaly error: $e');
      return false;
    }
  }

  /// Get baseline trends
  Future<List<Map<String, dynamic>>> getBaselineTrendsHistory(
    String operationName,
  ) async {
    try {
      final trends = await _client
          .from('performance_baselines')
          .select()
          .eq('operation_name', operationName)
          .order('calculated_at', ascending: false)
          .limit(30);

      return List<Map<String, dynamic>>.from(trends);
    } catch (e) {
      debugPrint('Get baseline trends error: $e');
      return [];
    }
  }

  /// Get detection statistics
  Future<Map<String, dynamic>> getDetectionStatistics() async {
    try {
      final response = await _client.rpc('get_detection_statistics');
      return response ??
          {
            'anomalies_detected_today': 0,
            'critical_anomalies': 0,
            'detection_status': 'unknown',
            'last_check': DateTime.now().toIso8601String(),
          };
    } catch (e) {
      debugPrint('Get detection statistics error: $e');
      return {
        'anomalies_detected_today': 0,
        'critical_anomalies': 0,
        'detection_status': 'unknown',
        'last_check': DateTime.now().toIso8601String(),
      };
    }
  }

  /// Schedule baseline recalculation (weekly cron job simulation)
  Future<void> scheduleBaselineRecalculation() async {
    try {
      // In production, this would be a cron job
      // For now, we'll check if it's Sunday and recalculate
      final now = DateTime.now();
      if (now.weekday == DateTime.sunday) {
        await calculateBaselines(periodDays: 30);
      }
    } catch (e) {
      debugPrint('Schedule baseline recalculation error: $e');
    }
  }

  /// Get baseline trends over time
  Future<List<Map<String, dynamic>>> getBaselineTrends({
    required String operationName,
    int days = 90,
  }) async {
    try {
      final response = await _client
          .from('performance_baselines_history')
          .select()
          .eq('operation_name', operationName)
          .gte(
            'effective_date',
            DateTime.now().subtract(Duration(days: days)).toIso8601String(),
          )
          .order('effective_date', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get baseline trends error: $e');
      return [];
    }
  }

  /// Get anomaly frequency per operation
  Future<Map<String, int>> getAnomalyFrequency({int days = 30}) async {
    try {
      final response = await _client
          .from('performance_anomalies')
          .select('operation_name')
          .gte(
            'detected_at',
            DateTime.now().subtract(Duration(days: days)).toIso8601String(),
          );

      final frequency = <String, int>{};
      for (final anomaly in response) {
        final operationName = anomaly['operation_name'] as String;
        frequency[operationName] = (frequency[operationName] ?? 0) + 1;
      }

      return frequency;
    } catch (e) {
      debugPrint('Get anomaly frequency error: $e');
      return {};
    }
  }

  /// Get related anomalies (same time window)
  Future<List<Map<String, dynamic>>> getRelatedAnomalies(
    String anomalyId,
  ) async {
    try {
      // Get the anomaly timestamp
      final anomaly = await _client
          .from('performance_anomalies')
          .select()
          .eq('anomaly_id', anomalyId)
          .single();

      final detectedAt = DateTime.parse(anomaly['detected_at'] as String);
      final windowStart = detectedAt.subtract(const Duration(minutes: 10));
      final windowEnd = detectedAt.add(const Duration(minutes: 10));

      // Find other anomalies in the same time window
      final related = await _client
          .from('performance_anomalies')
          .select()
          .neq('anomaly_id', anomalyId)
          .gte('detected_at', windowStart.toIso8601String())
          .lte('detected_at', windowEnd.toIso8601String())
          .order('detected_at', ascending: false);

      return List<Map<String, dynamic>>.from(related);
    } catch (e) {
      debugPrint('Get related anomalies error: $e');
      return [];
    }
  }

  /// Get anomaly history (resolved anomalies)
  Future<List<Map<String, dynamic>>> getAnomalyHistory({
    DateTime? startDate,
    DateTime? endDate,
    String? severity,
    int limit = 100,
  }) async {
    try {
      var query = _client
          .from('performance_anomalies')
          .select()
          .eq('acknowledged', true);

      if (startDate != null) {
        query = query.gte('detected_at', startDate.toIso8601String());
      }

      if (endDate != null) {
        query = query.lte('detected_at', endDate.toIso8601String());
      }

      if (severity != null) {
        query = query.eq('severity', severity);
      }

      final response = await query
          .order('detected_at', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get anomaly history error: $e');
      return [];
    }
  }

  /// Dismiss anomaly as false positive
  Future<bool> dismissAnomalyAsFalsePositive(
    String anomalyId,
    String userId,
    String reason,
  ) async {
    try {
      await _client
          .from('performance_anomalies')
          .update({
            'acknowledged': true,
            'acknowledged_by': userId,
            'acknowledged_at': DateTime.now().toIso8601String(),
            'resolution_actions': [
              {'action': 'dismissed_as_false_positive', 'reason': reason},
            ],
          })
          .eq('anomaly_id', anomalyId);

      return true;
    } catch (e) {
      debugPrint('Dismiss anomaly error: $e');
      return false;
    }
  }
}
