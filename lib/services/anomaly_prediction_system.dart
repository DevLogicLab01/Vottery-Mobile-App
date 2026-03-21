import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/perplexity_service.dart';

class AnomalyPredictionSystem {
  static final AnomalyPredictionSystem _instance =
      AnomalyPredictionSystem._internal();
  factory AnomalyPredictionSystem() => _instance;
  AnomalyPredictionSystem._internal();

  final _supabase = Supabase.instance.client;
  final _perplexityService = PerplexityService.instance;

  /// Predict anomalies for next 24-48 hours using time series analysis
  Future<List<Map<String, dynamic>>> predictAnomalies(
    List<Map<String, dynamic>> logs,
  ) async {
    final predictions = <Map<String, dynamic>>[];

    // 1. Time series analysis
    final timeSeriesPredictions = await _timeSeriesAnalysis(logs);
    predictions.addAll(timeSeriesPredictions);

    // 2. Statistical anomaly detection
    final statisticalPredictions = await _statisticalAnomalyDetection(logs);
    predictions.addAll(statisticalPredictions);

    // 3. Perplexity AI prediction
    final aiPredictions = await _perplexityPrediction(logs);
    predictions.addAll(aiPredictions);

    return predictions;
  }

  /// Time series analysis for volume forecasting
  Future<List<Map<String, dynamic>>> _timeSeriesAnalysis(
    List<Map<String, dynamic>> logs,
  ) async {
    final predictions = <Map<String, dynamic>>[];

    // Group logs by hour
    final hourlyVolumes = <int, int>{};
    for (final log in logs) {
      final timestamp = DateTime.parse(log['timestamp']);
      final hour = timestamp.hour;
      hourlyVolumes[hour] = (hourlyVolumes[hour] ?? 0) + 1;
    }

    // Calculate statistics
    final volumes = hourlyVolumes.values.toList();
    if (volumes.isEmpty) return predictions;

    final mean = volumes.reduce((a, b) => a + b) / volumes.length;
    final stdDev = _calculateStdDev(volumes, mean);

    // Detect volume spikes
    for (final entry in hourlyVolumes.entries) {
      final hour = entry.key;
      final volume = entry.value;

      if (volume > mean + 2 * stdDev) {
        predictions.add({
          'predicted_threat_type': 'Volume Spike',
          'likelihood_percentage': 75,
          'predicted_timeframe': 'Next 24 hours around $hour:00',
          'warning_signs': [
            'Historical volume spike at hour $hour',
            'Current volume: $volume (mean: ${mean.toStringAsFixed(1)}, threshold: ${(mean + 2 * stdDev).toStringAsFixed(1)})',
          ],
          'target_systems': ['logging', 'monitoring'],
          'preventive_actions': [
            'Scale infrastructure proactively',
            'Enable additional monitoring',
            'Prepare incident response team',
          ],
        });
      }
    }

    // Identify seasonal patterns
    final weekdayVolumes = <int>[];
    final weekendVolumes = <int>[];

    for (final log in logs) {
      final timestamp = DateTime.parse(log['timestamp']);
      if (timestamp.weekday >= 6) {
        weekendVolumes.add(1);
      } else {
        weekdayVolumes.add(1);
      }
    }

    if (weekdayVolumes.length > weekendVolumes.length * 1.5) {
      predictions.add({
        'predicted_threat_type': 'Weekend Activity Anomaly',
        'likelihood_percentage': 60,
        'predicted_timeframe': 'Next weekend',
        'warning_signs': [
          'Unusual weekend activity pattern detected',
          'Weekday volume: ${weekdayVolumes.length}, Weekend volume: ${weekendVolumes.length}',
        ],
        'target_systems': ['user_activity', 'authentication'],
        'preventive_actions': [
          'Monitor weekend activity closely',
          'Review authentication logs',
          'Check for automated bot activity',
        ],
      });
    }

    // Forecast future volumes using simple trend extrapolation
    final trend = _calculateTrend(volumes);
    if (trend > 0.2) {
      final forecastedVolume = mean * (1 + trend);
      predictions.add({
        'predicted_threat_type': 'Increasing Load Trend',
        'likelihood_percentage': 70,
        'predicted_timeframe': 'Next 24-48 hours',
        'warning_signs': [
          'Upward trend detected: ${(trend * 100).toStringAsFixed(1)}% increase',
          'Forecasted volume: ${forecastedVolume.toStringAsFixed(0)} events/hour',
        ],
        'target_systems': ['infrastructure', 'database'],
        'preventive_actions': [
          'Scale database resources',
          'Optimize query performance',
          'Enable caching mechanisms',
        ],
      });
    }

    return predictions;
  }

  /// Statistical anomaly detection using isolation forest approach
  Future<List<Map<String, dynamic>>> _statisticalAnomalyDetection(
    List<Map<String, dynamic>> logs,
  ) async {
    final predictions = <Map<String, dynamic>>[];

    // Extract features for analysis
    final features = _extractFeatures(logs);

    // Calculate anomaly scores
    final anomalyScores = _calculateAnomalyScores(features);

    // Threshold-based alerting
    for (var i = 0; i < anomalyScores.length; i++) {
      final score = anomalyScores[i];
      if (score > 0.8) {
        final feature = features[i];
        predictions.add({
          'predicted_threat_type': 'Statistical Anomaly',
          'likelihood_percentage': (score * 100).toInt(),
          'predicted_timeframe': 'Immediate (detected in current data)',
          'warning_signs': [
            'Anomaly score: ${score.toStringAsFixed(2)}',
            'Event frequency: ${feature['event_frequency']}',
            'Unique users: ${feature['unique_users']}',
            'Error rate: ${feature['error_rate'].toStringAsFixed(2)}',
          ],
          'target_systems': ['monitoring', 'alerting'],
          'preventive_actions': [
            'Investigate anomalous activity',
            'Review recent system changes',
            'Check for security incidents',
          ],
        });
      }
    }

    return predictions;
  }

  /// Perplexity AI-powered prediction
  Future<List<Map<String, dynamic>>> _perplexityPrediction(
    List<Map<String, dynamic>> logs,
  ) async {
    try {
      // Get historical fraud data
      final historicalData = await _getHistoricalFraudData();

      // Build prediction prompt
      final prompt = _buildPredictionPrompt(logs, historicalData);

      // Call Perplexity API
      final response = await _perplexityService.callPerplexityAPI(
        prompt,
        model: 'sonar-pro',
      );

      // Parse predictions from response
      return _parsePredictionResponse(
        response['choices']?[0]?['message']?['content'] as String? ?? '',
      );
    } catch (e) {
      debugPrint('Perplexity prediction failed: $e');
      return [];
    }
  }

  /// Build prediction prompt for Perplexity
  String _buildPredictionPrompt(
    List<Map<String, dynamic>> logs,
    Map<String, dynamic> historicalData,
  ) {
    // Aggregate current patterns
    final eventTypes = <String, int>{};
    final severityCounts = <String, int>{};

    for (final log in logs) {
      final eventType = log['event_type'] as String?;
      final severity = log['severity'] as String?;

      if (eventType != null) {
        eventTypes[eventType] = (eventTypes[eventType] ?? 0) + 1;
      }
      if (severity != null) {
        severityCounts[severity] = (severityCounts[severity] ?? 0) + 1;
      }
    }

    return '''
Based on current attack patterns and historical data, predict security threats for the next 24-48 hours.

**Current Indicators**:
${eventTypes.entries.map((e) => '- ${e.key}: ${e.value} events').join('\n')}

**Severity Distribution**:
${severityCounts.entries.map((e) => '- ${e.key}: ${e.value} events').join('\n')}

**Historical Trends**:
${historicalData['recent_incidents'] ?? 'No recent incidents'}

**Seasonal Patterns**:
${historicalData['seasonal_trends'] ?? 'No seasonal data'}

**Known Attack Campaigns**:
${historicalData['attack_campaigns'] ?? 'No active campaigns'}

Predict:
1. **Attack types** most likely to occur
2. **Target areas** (authentication, payments, user data, elections, content)
3. **Timing windows** when attacks are expected
4. **Attack sophistication** level
5. **Confidence levels** for predictions
6. **Early warning indicators** to monitor

Provide actionable threat forecasts with specific timeframes and recommended preventive measures.

Return predictions in this format:
- Threat: [type]
- Likelihood: [percentage]
- Timeframe: [when]
- Indicators: [what to watch]
- Prevention: [actions to take]
''';
  }

  /// Parse prediction response from Perplexity
  List<Map<String, dynamic>> _parsePredictionResponse(String response) {
    final predictions = <Map<String, dynamic>>[];

    // Simple parsing - extract threat predictions
    final lines = response.split('\n');
    Map<String, dynamic>? currentPrediction;

    for (final line in lines) {
      if (line.startsWith('- Threat:')) {
        if (currentPrediction != null) {
          predictions.add(currentPrediction);
        }
        currentPrediction = {
          'predicted_threat_type': line.replaceFirst('- Threat:', '').trim(),
          'warning_signs': <String>[],
          'target_systems': <String>[],
          'preventive_actions': <String>[],
        };
      } else if (currentPrediction != null) {
        if (line.startsWith('- Likelihood:')) {
          final likelihoodStr = line.replaceFirst('- Likelihood:', '').trim();
          final match = RegExp(r'(\d+)').firstMatch(likelihoodStr);
          if (match != null) {
            currentPrediction['likelihood_percentage'] = int.parse(
              match.group(1)!,
            );
          }
        } else if (line.startsWith('- Timeframe:')) {
          currentPrediction['predicted_timeframe'] = line
              .replaceFirst('- Timeframe:', '')
              .trim();
        } else if (line.startsWith('- Indicators:')) {
          (currentPrediction['warning_signs'] as List).add(
            line.replaceFirst('- Indicators:', '').trim(),
          );
        } else if (line.startsWith('- Prevention:')) {
          (currentPrediction['preventive_actions'] as List).add(
            line.replaceFirst('- Prevention:', '').trim(),
          );
        }
      }
    }

    if (currentPrediction != null) {
      predictions.add(currentPrediction);
    }

    return predictions;
  }

  /// Get historical fraud data
  Future<Map<String, dynamic>> _getHistoricalFraudData() async {
    try {
      // Get recent fraud incidents
      final recentIncidents = await _supabase
          .from('fraud_detection_log')
          .select()
          .order('created_at', ascending: false)
          .limit(20);

      // Get recent analysis results
      await _supabase
          .from('fraud_analysis_results')
          .select()
          .order('analysis_timestamp', ascending: false)
          .limit(10);

      return {
        'recent_incidents': (recentIncidents as List)
            .map((i) => '${i['detection_type']}: ${i['confidence_score']}')
            .join(', '),
        'seasonal_trends': 'Historical pattern analysis',
        'attack_campaigns': 'No active campaigns detected',
      };
    } catch (e) {
      return {
        'recent_incidents': 'Unable to fetch',
        'seasonal_trends': 'Unable to fetch',
        'attack_campaigns': 'Unable to fetch',
      };
    }
  }

  /// Extract features for anomaly detection
  List<Map<String, dynamic>> _extractFeatures(List<Map<String, dynamic>> logs) {
    // Group logs by 1-hour windows
    final windows = <DateTime, List<Map<String, dynamic>>>{};

    for (final log in logs) {
      final timestamp = DateTime.parse(log['timestamp']);
      final windowStart = DateTime(
        timestamp.year,
        timestamp.month,
        timestamp.day,
        timestamp.hour,
      );
      windows.putIfAbsent(windowStart, () => []).add(log);
    }

    // Extract features for each window
    final features = <Map<String, dynamic>>[];
    for (final entry in windows.entries) {
      final windowLogs = entry.value;
      final uniqueUsers = windowLogs.map((l) => l['user_id']).toSet().length;
      final errorCount = windowLogs
          .where((l) => l['event_type'] == 'error')
          .length;
      final errorRate = windowLogs.isEmpty
          ? 0.0
          : errorCount / windowLogs.length;

      features.add({
        'timestamp': entry.key,
        'event_frequency': windowLogs.length,
        'unique_users': uniqueUsers,
        'error_rate': errorRate,
      });
    }

    return features;
  }

  /// Calculate anomaly scores using simple isolation forest approach
  List<double> _calculateAnomalyScores(List<Map<String, dynamic>> features) {
    if (features.isEmpty) return [];

    // Normalize features
    final frequencies = features
        .map((f) => f['event_frequency'] as int)
        .toList();
    final users = features.map((f) => f['unique_users'] as int).toList();
    final errorRates = features.map((f) => f['error_rate'] as double).toList();

    final freqMean = frequencies.reduce((a, b) => a + b) / frequencies.length;
    final freqStdDev = _calculateStdDev(frequencies, freqMean);

    final userMean = users.reduce((a, b) => a + b) / users.length;
    final userStdDev = _calculateStdDev(users, userMean);

    final errorMean = errorRates.reduce((a, b) => a + b) / errorRates.length;
    final errorStdDev = _calculateStdDevDouble(errorRates, errorMean);

    // Calculate anomaly scores
    final scores = <double>[];
    for (var i = 0; i < features.length; i++) {
      final freqScore = freqStdDev == 0
          ? 0.0
          : ((frequencies[i] - freqMean) / freqStdDev).abs();
      final userScore = userStdDev == 0
          ? 0.0
          : ((users[i] - userMean) / userStdDev).abs();
      final errorScore = errorStdDev == 0
          ? 0.0
          : ((errorRates[i] - errorMean) / errorStdDev).abs();

      // Combined anomaly score
      final combinedScore = (freqScore + userScore + errorScore) / 3;
      scores.add((combinedScore / 3).clamp(0.0, 1.0)); // Normalize to 0-1
    }

    return scores;
  }

  /// Calculate standard deviation
  double _calculateStdDev(List<int> values, double mean) {
    if (values.isEmpty) return 0.0;
    final variance =
        values.map((v) => pow(v - mean, 2)).reduce((a, b) => a + b) /
        values.length;
    return sqrt(variance);
  }

  /// Calculate standard deviation for doubles
  double _calculateStdDevDouble(List<double> values, double mean) {
    if (values.isEmpty) return 0.0;
    final variance =
        values.map((v) => pow(v - mean, 2)).reduce((a, b) => a + b) /
        values.length;
    return sqrt(variance);
  }

  /// Calculate trend (simple linear regression slope)
  double _calculateTrend(List<int> values) {
    if (values.length < 2) return 0.0;

    final n = values.length;
    final x = List.generate(n, (i) => i.toDouble());
    final y = values.map((v) => v.toDouble()).toList();

    final xMean = x.reduce((a, b) => a + b) / n;
    final yMean = y.reduce((a, b) => a + b) / n;

    var numerator = 0.0;
    var denominator = 0.0;

    for (var i = 0; i < n; i++) {
      numerator += (x[i] - xMean) * (y[i] - yMean);
      denominator += pow(x[i] - xMean, 2);
    }

    return denominator == 0 ? 0.0 : numerator / denominator;
  }
}
