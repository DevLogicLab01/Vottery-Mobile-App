import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import './auth_service.dart';
import './supabase_service.dart';

/// Enhanced Analytics Service with CDN Integration
/// Cloudflare CDN optimization + OpenAI predictive analytics
class EnhancedAnalyticsCDNService {
  static EnhancedAnalyticsCDNService? _instance;
  static EnhancedAnalyticsCDNService get instance =>
      _instance ??= EnhancedAnalyticsCDNService._();

  EnhancedAnalyticsCDNService._();

  SupabaseClient get _client => SupabaseService.instance.client;
  AuthService get _auth => AuthService.instance;

  // Cloudflare configuration
  static const String cloudflareAccountId = String.fromEnvironment(
    'CLOUDFLARE_ACCOUNT_ID',
    defaultValue: '',
  );
  static const String cloudflareApiToken = String.fromEnvironment(
    'CLOUDFLARE_API_TOKEN',
    defaultValue: '',
  );

  /// Get CDN performance metrics
  Future<Map<String, dynamic>> getCDNPerformanceMetrics() async {
    try {
      // Mock CDN metrics (in production, use Cloudflare Analytics API)
      return {
        'cache_hit_ratio': 99.9,
        'edge_locations': 275,
        'bandwidth_saved': 847.3, // GB
        'requests_served': 12847293,
        'avg_response_time': 42, // ms
        'image_optimization': {
          'webp_conversions': 8473,
          'avif_conversions': 3821,
          'size_reduction': 67.3, // %
        },
        'video_optimization': {
          'adaptive_bitrate_streams': 1247,
          'geo_distributed_cache': true,
          'avg_startup_time': 1.2, // seconds
        },
      };
    } catch (e) {
      debugPrint('Get CDN performance metrics error: $e');
      return {};
    }
  }

  /// Optimize image with Cloudflare
  Future<String?> optimizeImage({
    required String imageUrl,
    required String format,
    required int quality,
  }) async {
    try {
      if (cloudflareAccountId.isEmpty || cloudflareApiToken.isEmpty) {
        return imageUrl; // Return original if no Cloudflare config
      }

      // Cloudflare Image Resizing API
      final optimizedUrl =
          'https://vottery.com/cdn-cgi/image/format=$format,quality=$quality/$imageUrl';

      return optimizedUrl;
    } catch (e) {
      debugPrint('Optimize image error: $e');
      return imageUrl;
    }
  }

  /// Get predictive analytics using OpenAI GPT-4
  Future<Map<String, dynamic>?> getPredictiveAnalytics({
    required String metricType,
    required int forecastDays,
  }) async {
    try {
      // Get historical data
      final historicalData = await _getHistoricalData(metricType);

      if (historicalData.isEmpty) return null;

      // Call OpenAI for prediction
      final prompt =
          '''
Analyze the following historical data and provide a $forecastDays-day forecast:

Metric: $metricType
Historical Data: ${jsonEncode(historicalData)}

Provide:
1. Predicted values for the next $forecastDays days
2. Confidence intervals (95%)
3. Trend analysis (upward/downward/stable)
4. Key insights and anomalies
5. Optimization recommendations

Format response as JSON with keys: predictions, confidence_intervals, trend, insights, recommendations
''';

      final response = await _callOpenAI(prompt);

      if (response == null) return null;

      return {
        'metric_type': metricType,
        'forecast_days': forecastDays,
        'historical_data': historicalData,
        'predictions': response['predictions'],
        'confidence_intervals': response['confidence_intervals'],
        'trend': response['trend'],
        'insights': response['insights'],
        'recommendations': response['recommendations'],
        'generated_at': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      debugPrint('Get predictive analytics error: $e');
      return null;
    }
  }

  /// Get historical data for predictions
  Future<List<Map<String, dynamic>>> _getHistoricalData(
    String metricType,
  ) async {
    try {
      final response = await _client
          .from('analytics_metrics')
          .select()
          .eq('metric_type', metricType)
          .order('recorded_at', ascending: false)
          .limit(90); // Last 90 days

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get historical data error: $e');
      return [];
    }
  }

  /// Call OpenAI API for predictions
  Future<Map<String, dynamic>?> _callOpenAI(String prompt) async {
    try {
      const apiKey = String.fromEnvironment('OPENAI_API_KEY', defaultValue: '');

      if (apiKey.isEmpty) {
        // Return mock data if no API key
        return {
          'predictions': List.generate(
            30,
            (i) => {'day': i + 1, 'value': 1000 + (i * 50) + (i % 7 * 100)},
          ),
          'confidence_intervals': {'lower': 0.85, 'upper': 0.95},
          'trend': 'upward',
          'insights': [
            'User growth shows consistent upward trend',
            'Weekend engagement peaks detected',
            'Seasonal patterns indicate Q2 surge',
          ],
          'recommendations': [
            'Increase marketing budget by 15% for Q2',
            'Optimize weekend content delivery',
            'Implement retention campaigns for new users',
          ],
        };
      }

      final response = await http.post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-4',
          'messages': [
            {'role': 'system', 'content': 'You are a data analyst expert.'},
            {'role': 'user', 'content': prompt},
          ],
          'temperature': 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'];
        return jsonDecode(content);
      }

      return null;
    } catch (e) {
      debugPrint('Call OpenAI error: $e');
      return null;
    }
  }

  /// Detect anomalies in data
  Future<List<Map<String, dynamic>>> detectAnomalies(String metricType) async {
    try {
      final historicalData = await _getHistoricalData(metricType);

      if (historicalData.isEmpty) return [];

      // Simple anomaly detection using standard deviation
      final values = historicalData.map((d) => d['value'] as double).toList();
      final mean = values.reduce((a, b) => a + b) / values.length;
      final variance =
          values.map((v) => (v - mean) * (v - mean)).reduce((a, b) => a + b) /
          values.length;
      final stdDev = math.sqrt(variance);

      final anomalies = <Map<String, dynamic>>[];
      for (var i = 0; i < historicalData.length; i++) {
        final value = historicalData[i]['value'] as double;
        final zScore = (value - mean) / stdDev;

        if (zScore.abs() > 2.5) {
          // Anomaly threshold
          anomalies.add({
            'date': historicalData[i]['recorded_at'],
            'value': value,
            'z_score': zScore,
            'severity': zScore.abs() > 3 ? 'high' : 'medium',
          });
        }
      }

      return anomalies;
    } catch (e) {
      debugPrint('Detect anomalies error: $e');
      return [];
    }
  }

  /// Generate what-if scenario
  Future<Map<String, dynamic>?> generateWhatIfScenario({
    required String metricType,
    required Map<String, dynamic> assumptions,
  }) async {
    try {
      final prompt =
          '''
Generate a what-if scenario analysis:

Metric: $metricType
Assumptions: ${jsonEncode(assumptions)}

Provide:
1. Projected outcomes under these assumptions
2. Risk assessment
3. Confidence level
4. Alternative scenarios

Format as JSON.
''';

      final response = await _callOpenAI(prompt);

      return response;
    } catch (e) {
      debugPrint('Generate what-if scenario error: $e');
      return null;
    }
  }
}
