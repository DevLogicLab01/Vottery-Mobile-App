import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';
import './supabase_service.dart';
import './perplexity_service.dart';

class PredictiveAnalyticsService {
  static PredictiveAnalyticsService? _instance;
  static PredictiveAnalyticsService get instance =>
      _instance ??= PredictiveAnalyticsService._();

  PredictiveAnalyticsService._();

  SupabaseClient get _client => SupabaseService.instance.client;
  PerplexityService get _perplexity => PerplexityService.instance;

  /// Forecast traffic patterns for 30-90 days
  Future<Map<String, dynamic>> forecastTrafficPatterns() async {
    try {
      // Get historical traffic data from last 180 days
      final historicalData = await _getHistoricalTrafficData();

      if (historicalData.isEmpty) {
        return _getDefaultTrafficForecast();
      }

      // Construct Perplexity prompt
      final prompt =
          '''
Analyze this traffic data spanning 180 days: ${jsonEncode(historicalData)}.

Predict traffic patterns for next 30, 60, and 90 days. Consider:
1) Seasonal trends (weekday vs weekend, monthly patterns)
2) Growth trajectory (linear, exponential, plateau)
3) External factors (holidays, events, market trends)

Provide forecasted daily traffic with confidence intervals, peak load predictions, recommended infrastructure capacity, scaling trigger points.

Use extended reasoning to analyze complex patterns.

Respond in JSON format:
{
  "forecast_30d": [
    {
      "date": "YYYY-MM-DD",
      "expected_daily_traffic": 0,
      "confidence_interval_low": 0,
      "confidence_interval_high": 0,
      "peak_concurrent_users": 0,
      "recommended_server_capacity": 0,
      "scaling_triggers": ["trigger description"]
    }
  ],
  "forecast_60d": [...],
  "forecast_90d": [...],
  "seasonal_factors": {"weekday_pattern": "", "monthly_pattern": ""},
  "growth_trajectory": "linear|exponential|plateau",
  "confidence_score": 0.0-1.0
}
''';

      final response = await _perplexity.callPerplexityAPI(
        prompt,
        model: PerplexityService.reasoningModel,
      );

      final forecast = _parseTrafficForecast(response);
      await _storeForecast('traffic', forecast);

      return forecast;
    } catch (e) {
      debugPrint('Forecast traffic patterns error: $e');
      return _getDefaultTrafficForecast();
    }
  }

  /// Forecast fraud trends for 30-90 days
  Future<Map<String, dynamic>> forecastFraudTrends() async {
    try {
      // Get fraud history from last 90 days
      final fraudHistory = await _getFraudHistory();

      if (fraudHistory.isEmpty) {
        return _getDefaultFraudForecast();
      }

      final prompt =
          '''
Analyze this fraud data: ${jsonEncode(fraudHistory)}.

Predict fraud trends for next 30-90 days including:
1) Emerging attack vectors
2) Expected fraud volume and financial impact
3) Most vulnerable systems/features
4) Recommended prevention measures

Consider current threat intelligence and industry trends.

Respond in JSON format:
{
  "predicted_fraud_attempts_per_day": 0,
  "predicted_financial_impact": 0.0,
  "emerging_attack_types": [
    {"type": "", "description": "", "likelihood": 0.0-1.0}
  ],
  "vulnerable_systems": [
    {"system": "", "risk_level": "low|medium|high|critical"}
  ],
  "prevention_recommendations": [
    {"recommendation": "", "priority": "low|medium|high|critical"}
  ],
  "confidence_score": 0.0-1.0
}
''';

      final response = await _perplexity.callPerplexityAPI(
        prompt,
        model: PerplexityService.reasoningModel,
      );

      final forecast = _parseFraudForecast(response);
      await _storeForecast('fraud', forecast);

      return forecast;
    } catch (e) {
      debugPrint('Forecast fraud trends error: $e');
      return _getDefaultFraudForecast();
    }
  }

  /// Forecast infrastructure scaling needs
  Future<Map<String, dynamic>> forecastInfrastructureScaling(
    Map<String, dynamic> trafficForecast,
  ) async {
    try {
      // Get performance metrics from last 60 days
      final metricsHistory = await _getPerformanceMetrics();

      if (metricsHistory.isEmpty) {
        return _getDefaultInfrastructureForecast();
      }

      final prompt =
          '''
Based on this infrastructure usage data: ${jsonEncode(metricsHistory)}
and traffic forecast: ${jsonEncode(trafficForecast)},

Predict infrastructure scaling needs for 30-90 days. Recommend:
1) Database scaling timeline (when to scale up, by how much)
2) Server/compute requirements
3) Storage expansion needs
4) API rate limit adjustments
5) Cost implications

Consider growth projections and usage patterns.

Respond in JSON format:
{
  "scaling_recommendations": [
    {
      "date": "YYYY-MM-DD",
      "resource_type": "database|compute|storage|api",
      "action": "scale_up|scale_out",
      "capacity_increase_percentage": 0,
      "estimated_cost": 0.0,
      "justification": ""
    }
  ],
  "total_estimated_cost": 0.0,
  "confidence_score": 0.0-1.0
}
''';

      final response = await _perplexity.callPerplexityAPI(
        prompt,
        model: PerplexityService.reasoningModel,
      );

      final forecast = _parseInfrastructureForecast(response);
      await _storeForecast('infrastructure', forecast);

      return forecast;
    } catch (e) {
      debugPrint('Forecast infrastructure scaling error: $e');
      return _getDefaultInfrastructureForecast();
    }
  }

  /// Generate actionable recommendations
  Future<List<Map<String, dynamic>>> generateActionableRecommendations({
    required Map<String, dynamic> trafficForecast,
    required Map<String, dynamic> fraudForecast,
    required Map<String, dynamic> infrastructureForecast,
  }) async {
    try {
      final recommendations = <Map<String, dynamic>>[];

      // Traffic-based recommendations
      final trafficRecs = _extractTrafficRecommendations(trafficForecast);
      recommendations.addAll(trafficRecs);

      // Fraud-based recommendations
      final fraudRecs = _extractFraudRecommendations(fraudForecast);
      recommendations.addAll(fraudRecs);

      // Infrastructure-based recommendations
      final infraRecs = _extractInfrastructureRecommendations(
        infrastructureForecast,
      );
      recommendations.addAll(infraRecs);

      // Sort by priority
      recommendations.sort((a, b) {
        final priorityOrder = {'critical': 0, 'high': 1, 'medium': 2, 'low': 3};
        return priorityOrder[a['priority']]!.compareTo(
          priorityOrder[b['priority']]!,
        );
      });

      // Store recommendations
      for (final rec in recommendations) {
        await _storeRecommendation(rec);
      }

      return recommendations;
    } catch (e) {
      debugPrint('Generate recommendations error: $e');
      return [];
    }
  }

  /// Get stored recommendations
  Future<List<Map<String, dynamic>>> getRecommendations({
    String? status,
    String? priority,
  }) async {
    try {
      var query = _client.from('predictive_recommendations').select();

      if (status != null) {
        query = query.eq('implementation_status', status);
      }
      if (priority != null) {
        query = query.eq('priority', priority);
      }

      final response = await query.order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get recommendations error: $e');
      return [];
    }
  }

  /// Update recommendation status
  Future<bool> updateRecommendationStatus({
    required String recommendationId,
    required String status,
  }) async {
    try {
      await _client
          .from('predictive_recommendations')
          .update({
            'implementation_status': status,
            'implemented_at': status == 'completed'
                ? DateTime.now().toIso8601String()
                : null,
          })
          .eq('id', recommendationId);

      return true;
    } catch (e) {
      debugPrint('Update recommendation status error: $e');
      return false;
    }
  }

  // Private helper methods

  Future<List<Map<String, dynamic>>> _getHistoricalTrafficData() async {
    try {
      final startDate = DateTime.now()
          .subtract(const Duration(days: 180))
          .toIso8601String();

      final response = await _client
          .from('traffic_metrics')
          .select()
          .gte('date', startDate)
          .order('date', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get historical traffic data error: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _getFraudHistory() async {
    try {
      final startDate = DateTime.now()
          .subtract(const Duration(days: 90))
          .toIso8601String();

      final response = await _client
          .from('fraud_alerts')
          .select()
          .gte('created_at', startDate)
          .order('created_at', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get fraud history error: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _getPerformanceMetrics() async {
    try {
      final startDate = DateTime.now()
          .subtract(const Duration(days: 60))
          .toIso8601String();

      final response = await _client
          .from('performance_metrics')
          .select()
          .gte('timestamp', startDate)
          .order('timestamp', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get performance metrics error: $e');
      return [];
    }
  }

  Map<String, dynamic> _parseTrafficForecast(Map<String, dynamic> response) {
    try {
      // Check if response contains 'choices' array (API response format)
      if (response.containsKey('choices') &&
          response['choices'] is List &&
          (response['choices'] as List).isNotEmpty) {
        final firstChoice = (response['choices'] as List)[0];
        if (firstChoice is Map && firstChoice.containsKey('message')) {
          final message = firstChoice['message'];
          if (message is Map && message.containsKey('content')) {
            return jsonDecode(message['content'] as String)
                as Map<String, dynamic>;
          }
        }
      }
      // If response is already the forecast data
      return response;
    } catch (e) {
      return _getDefaultTrafficForecast();
    }
  }

  Map<String, dynamic> _parseFraudForecast(Map<String, dynamic> response) {
    try {
      // Check if response contains 'choices' array (API response format)
      if (response.containsKey('choices') &&
          response['choices'] is List &&
          (response['choices'] as List).isNotEmpty) {
        final firstChoice = (response['choices'] as List)[0];
        if (firstChoice is Map && firstChoice.containsKey('message')) {
          final message = firstChoice['message'];
          if (message is Map && message.containsKey('content')) {
            return jsonDecode(message['content'] as String)
                as Map<String, dynamic>;
          }
        }
      }
      // If response is already the forecast data
      return response;
    } catch (e) {
      return _getDefaultFraudForecast();
    }
  }

  Map<String, dynamic> _parseInfrastructureForecast(
    Map<String, dynamic> response,
  ) {
    try {
      // Check if response contains 'choices' array (API response format)
      if (response.containsKey('choices') &&
          response['choices'] is List &&
          (response['choices'] as List).isNotEmpty) {
        final firstChoice = (response['choices'] as List)[0];
        if (firstChoice is Map && firstChoice.containsKey('message')) {
          final message = firstChoice['message'];
          if (message is Map && message.containsKey('content')) {
            return jsonDecode(message['content'] as String)
                as Map<String, dynamic>;
          }
        }
      }
      // If response is already the forecast data
      return response;
    } catch (e) {
      return _getDefaultInfrastructureForecast();
    }
  }

  Future<void> _storeForecast(
    String type,
    Map<String, dynamic> forecast,
  ) async {
    try {
      await _client.from('predictive_forecasts').insert({
        'forecast_type': type,
        'forecast_data': forecast,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Store forecast error: $e');
    }
  }

  Future<void> _storeRecommendation(Map<String, dynamic> recommendation) async {
    try {
      await _client.from('predictive_recommendations').insert({
        'recommendation_text': recommendation['recommendation'],
        'category': recommendation['category'],
        'priority': recommendation['priority'],
        'estimated_implementation_time':
            recommendation['estimated_implementation_time'],
        'expected_benefit': recommendation['expected_benefit'],
        'implementation_steps': recommendation['implementation_steps'],
        'implementation_status': 'pending',
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Store recommendation error: $e');
    }
  }

  List<Map<String, dynamic>> _extractTrafficRecommendations(
    Map<String, dynamic> forecast,
  ) {
    final recommendations = <Map<String, dynamic>>[];

    // Example: Extract scaling triggers from forecast
    final forecast30d = forecast['forecast_30d'] as List? ?? [];
    for (final day in forecast30d) {
      final triggers = day['scaling_triggers'] as List? ?? [];
      for (final trigger in triggers) {
        recommendations.add({
          'recommendation': trigger,
          'category': 'traffic',
          'priority': 'high',
          'estimated_implementation_time': '2 hours',
          'expected_benefit': 'Handle traffic spike',
          'implementation_steps': ['Review trigger', 'Apply scaling'],
        });
      }
    }

    return recommendations;
  }

  List<Map<String, dynamic>> _extractFraudRecommendations(
    Map<String, dynamic> forecast,
  ) {
    final recommendations = <Map<String, dynamic>>[];

    final preventionRecs =
        forecast['prevention_recommendations'] as List? ?? [];
    for (final rec in preventionRecs) {
      recommendations.add({
        'recommendation': rec['recommendation'],
        'category': 'fraud',
        'priority': rec['priority'],
        'estimated_implementation_time': '4 hours',
        'expected_benefit': 'Prevent fraud attempts',
        'implementation_steps': ['Analyze pattern', 'Implement prevention'],
      });
    }

    return recommendations;
  }

  List<Map<String, dynamic>> _extractInfrastructureRecommendations(
    Map<String, dynamic> forecast,
  ) {
    final recommendations = <Map<String, dynamic>>[];

    final scalingRecs = forecast['scaling_recommendations'] as List? ?? [];
    for (final rec in scalingRecs) {
      recommendations.add({
        'recommendation':
            '${rec['action']} ${rec['resource_type']} by ${rec['capacity_increase_percentage']}%',
        'category': 'infrastructure',
        'priority': 'high',
        'estimated_implementation_time': '1 hour',
        'expected_benefit': rec['justification'],
        'implementation_steps': ['Review capacity', 'Apply scaling'],
      });
    }

    return recommendations;
  }

  Map<String, dynamic> _getDefaultTrafficForecast() {
    return {
      'forecast_30d': [],
      'forecast_60d': [],
      'forecast_90d': [],
      'seasonal_factors': {},
      'growth_trajectory': 'linear',
      'confidence_score': 0.5,
    };
  }

  Map<String, dynamic> _getDefaultFraudForecast() {
    return {
      'predicted_fraud_attempts_per_day': 0,
      'predicted_financial_impact': 0.0,
      'emerging_attack_types': [],
      'vulnerable_systems': [],
      'prevention_recommendations': [],
      'confidence_score': 0.5,
    };
  }

  Map<String, dynamic> _getDefaultInfrastructureForecast() {
    return {
      'scaling_recommendations': [],
      'total_estimated_cost': 0.0,
      'confidence_score': 0.5,
    };
  }
}
