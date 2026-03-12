import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import './supabase_service.dart';
import './claude_service.dart';
import 'dart:math';
import 'dart:convert'; // Add this import for jsonDecode

class ChartAnomalyAnalyzer {
  static ChartAnomalyAnalyzer? _instance;
  static ChartAnomalyAnalyzer get instance =>
      _instance ??= ChartAnomalyAnalyzer._();

  ChartAnomalyAnalyzer._();

  SupabaseClient get _client => SupabaseService.instance.client;

  /// Highlight anomalies in chart data using statistical analysis and Claude AI
  Future<List<Map<String, dynamic>>> highlightAnomalies({
    required String chartId,
    required List<Map<String, dynamic>> chartData,
    required String metricName,
    required String businessDomain,
  }) async {
    try {
      // Step 1: Calculate statistical measures
      final values = chartData.map((d) => (d['y'] as num).toDouble()).toList();

      if (values.isEmpty) return [];

      final mean = _calculateMean(values);
      final median = _calculateMedian(values);
      final stdDev = _calculateStandardDeviation(values, mean);

      // Step 2: Calculate z-scores for each data point
      final dataWithZScores = <Map<String, dynamic>>[];
      for (var i = 0; i < chartData.length; i++) {
        final value = (chartData[i]['y'] as num).toDouble();
        final zScore = (value - mean) / stdDev;

        dataWithZScores.add({
          ...chartData[i],
          'z_score': zScore,
          'is_anomaly': zScore.abs() > 2.0, // 2 standard deviations
        });
      }

      // Step 3: Filter anomalies
      final anomalies = dataWithZScores
          .where((d) => d['is_anomaly'] == true)
          .toList();

      if (anomalies.isEmpty) return [];

      // Step 4: Use Claude AI for contextual analysis
      final aiAnalysis = await _analyzeAnomaliesWithClaude(
        chartId: chartId,
        chartData: chartData,
        anomalies: anomalies,
        metricName: metricName,
        businessDomain: businessDomain,
        mean: mean,
        stdDev: stdDev,
      );

      // Step 5: Store anomalies in database
      for (final anomaly in aiAnalysis) {
        await _client.from('chart_anomalies').insert({
          'chart_id': chartId,
          'data_point_id': anomaly['data_point_id'],
          'data_point_timestamp': anomaly['timestamp'],
          'data_point_value': anomaly['value'],
          'anomaly_type': anomaly['anomaly_type'],
          'z_score': anomaly['z_score'],
          'explanation': anomaly['explanation'],
          'business_cause': anomaly['business_cause'],
          'confidence': anomaly['confidence'],
          'recommended_action': anomaly['recommended_action'],
        });
      }

      return aiAnalysis;
    } catch (e) {
      debugPrint('Highlight anomalies error: $e');
      return [];
    }
  }

  /// Analyze anomalies using Claude AI
  Future<List<Map<String, dynamic>>> _analyzeAnomaliesWithClaude({
    required String chartId,
    required List<Map<String, dynamic>> chartData,
    required List<Map<String, dynamic>> anomalies,
    required String metricName,
    required String businessDomain,
    required double mean,
    required double stdDev,
  }) async {
    try {
      final dataPointsStr = chartData
          .map((d) => '(${d['x']}, ${d['y']})')
          .join(', ');

      final anomaliesStr = anomalies
          .map(
            (a) =>
                '(${a['x']}, ${a['y']}, z-score: ${a['z_score'].toStringAsFixed(2)})',
          )
          .join(', ');

      final prompt =
          '''
Analyze this time series data for anomalies:

Chart: $chartId
Metric: $metricName
Business Domain: $businessDomain

Data points: $dataPointsStr

Statistical measures:
- Mean: ${mean.toStringAsFixed(2)}
- Standard Deviation: ${stdDev.toStringAsFixed(2)}

Detected anomalies (z-score > 2.0): $anomaliesStr

For each anomaly, provide:
1) Explanation: Why it's anomalous (z-score threshold, seasonal deviation, trend break)
2) Business Cause: Potential business reason (marketing campaign, system outage, data quality issue, seasonal event)
3) Confidence: 0-1 scale
4) Recommended Action: Specific investigation step

Return JSON array with format:
[
  {
    "data_point_id": "point_index",
    "timestamp": "ISO timestamp",
    "value": number,
    "z_score": number,
    "anomaly_type": "spike|drop|trend_change|outlier",
    "explanation": "string",
    "business_cause": "string",
    "confidence": number,
    "recommended_action": "string"
  }
]
''';

      final response = await ClaudeService.instance.callClaudeAPI(prompt);

      if (response.isEmpty) {
        return _getDefaultAnomalyAnalysis(anomalies);
      }

      // Parse Claude response
      try {
        // Extract JSON from response
        final jsonStart = response.indexOf('[');
        final jsonEnd = response.lastIndexOf(']') + 1;

        if (jsonStart == -1 || jsonEnd == 0) {
          return _getDefaultAnomalyAnalysis(anomalies);
        }

        final jsonStr = response.substring(jsonStart, jsonEnd);
        final List<dynamic> parsed = jsonDecode(jsonStr);

        return List<Map<String, dynamic>>.from(parsed);
      } catch (e) {
        debugPrint('Parse Claude response error: $e');
        return _getDefaultAnomalyAnalysis(anomalies);
      }
    } catch (e) {
      debugPrint('Analyze anomalies with Claude error: $e');
      return _getDefaultAnomalyAnalysis(anomalies);
    }
  }

  /// Get default anomaly analysis (fallback)
  List<Map<String, dynamic>> _getDefaultAnomalyAnalysis(
    List<Map<String, dynamic>> anomalies,
  ) {
    return anomalies.map((a) {
      final zScore = (a['z_score'] as num).toDouble();
      final anomalyType = zScore > 0 ? 'spike' : 'drop';

      return {
        'data_point_id': 'point_${a['x']}',
        'timestamp': DateTime.now().toIso8601String(),
        'value': a['y'],
        'z_score': zScore,
        'anomaly_type': anomalyType,
        'explanation':
            'Statistical anomaly detected: ${zScore.abs().toStringAsFixed(2)} standard deviations from mean',
        'business_cause': 'Unknown - requires investigation',
        'confidence': 0.75,
        'recommended_action': 'Verify data source and check for system events',
      };
    }).toList();
  }

  /// Calculate mean
  double _calculateMean(List<double> values) {
    if (values.isEmpty) return 0;
    return values.reduce((a, b) => a + b) / values.length;
  }

  /// Calculate median
  double _calculateMedian(List<double> values) {
    if (values.isEmpty) return 0;
    final sorted = List<double>.from(values)..sort();
    final middle = sorted.length ~/ 2;

    if (sorted.length % 2 == 0) {
      return (sorted[middle - 1] + sorted[middle]) / 2;
    } else {
      return sorted[middle];
    }
  }

  /// Calculate standard deviation
  double _calculateStandardDeviation(List<double> values, double mean) {
    if (values.isEmpty) return 0;

    final variance =
        values.map((v) => pow(v - mean, 2)).reduce((a, b) => a + b) /
        values.length;

    return sqrt(variance);
  }

  /// Get anomalies for chart
  Future<List<Map<String, dynamic>>> getChartAnomalies(String chartId) async {
    try {
      final response = await _client
          .from('chart_anomalies')
          .select()
          .eq('chart_id', chartId)
          .eq('investigated', false)
          .order('detected_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get chart anomalies error: $e');
      return [];
    }
  }

  /// Mark anomaly as investigated
  Future<bool> markAnomalyInvestigated({
    required String anomalyId,
    required String userId,
    String? notes,
  }) async {
    try {
      await _client
          .from('chart_anomalies')
          .update({
            'investigated': true,
            'investigated_by': userId,
            'investigated_at': DateTime.now().toIso8601String(),
            'investigation_notes': notes,
          })
          .eq('anomaly_id', anomalyId);

      return true;
    } catch (e) {
      debugPrint('Mark anomaly investigated error: $e');
      return false;
    }
  }
}
