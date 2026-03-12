import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import './supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import './datadog_tracing_service.dart';

class PerplexityService {
  static PerplexityService? _instance;
  static PerplexityService get instance => _instance ??= PerplexityService._();

  PerplexityService._();

  static const String apiKey = String.fromEnvironment('PERPLEXITY_API_KEY');
  static const String apiUrl = 'https://api.perplexity.ai/chat/completions';
  static const String reasoningModel = 'sonar-reasoning';
  static const String proModel = 'sonar-pro';

  SupabaseClient get _client => SupabaseService.instance.client;

  final DatadogTracingService _tracing = DatadogTracingService.instance;

  /// Static method for threat intelligence analysis (used for health checks)
  static Future<Map<String, dynamic>> analyzeThreatIntelligence({
    required Map<String, dynamic> threatContext,
  }) async {
    return instance.analyzeThreatIntelligenceInstance(
      threatData: threatContext,
    );
  }

  Future<Map<String, dynamic>> analyzeThreatIntelligenceInstance({
    required Map<String, dynamic> threatData,
  }) async {
    try {
      if (apiKey.isEmpty || apiKey == 'your-perplexity-api-key-here') {
        return _getDefaultThreatAnalysis();
      }

      final prompt = _buildThreatPrompt(threatData);
      final response = await callPerplexityAPI(
        prompt,
        model: reasoningModel,
        searchRecencyFilter: 'week',
      );

      return _parseThreatResponse(
        response['choices']?[0]?['message']?['content'] ?? '',
      );
    } catch (e) {
      debugPrint('Perplexity threat analysis error: $e');
      return _getDefaultThreatAnalysis();
    }
  }

  Future<Map<String, dynamic>> analyzeMarketSentiment({
    required String topic,
    String? category,
  }) async {
    try {
      if (apiKey.isEmpty || apiKey == 'your-perplexity-api-key-here') {
        return _getDefaultSentimentAnalysis();
      }

      final prompt = _buildSentimentPrompt(topic, category);
      final response = await callPerplexityAPI(
        prompt,
        model: proModel,
        searchRecencyFilter: 'month',
      );

      return _parseSentimentResponse(
        response['choices']?[0]?['message']?['content'] ?? '',
      );
    } catch (e) {
      debugPrint('Perplexity sentiment analysis error: $e');
      return _getDefaultSentimentAnalysis();
    }
  }

  Future<Map<String, dynamic>> forecastFraudTrends({
    required List<Map<String, dynamic>> historicalData,
  }) async {
    try {
      if (apiKey.isEmpty || apiKey == 'your-perplexity-api-key-here') {
        return _getDefaultFraudForecast();
      }

      final prompt = _buildFraudForecastPrompt(historicalData);
      final response = await callPerplexityAPI(prompt, model: reasoningModel);

      return _parseFraudForecast(
        response['choices']?[0]?['message']?['content'] ?? '',
      );
    } catch (e) {
      debugPrint('Perplexity fraud forecast error: $e');
      return _getDefaultFraudForecast();
    }
  }

  Future<Map<String, dynamic>> generateStrategicPlan({
    required Map<String, dynamic> businessData,
  }) async {
    try {
      if (apiKey.isEmpty || apiKey == 'your-perplexity-api-key-here') {
        return _getDefaultStrategicPlan();
      }

      final prompt = _buildStrategicPrompt(businessData);
      final response = await callPerplexityAPI(prompt, model: reasoningModel);

      return _parseStrategicPlan(
        response['choices']?[0]?['message']?['content'] ?? '',
      );
    } catch (e) {
      debugPrint('Perplexity strategic planning error: $e');
      return _getDefaultStrategicPlan();
    }
  }

  /// Strategic planning with 60-90 day forecasting
  Future<Map<String, dynamic>> generateStrategicPlanWithForecasting({
    required Map<String, dynamic> businessData,
  }) async {
    try {
      if (apiKey.isEmpty || apiKey == 'your-perplexity-api-key-here') {
        return _getDefaultStrategicForecast();
      }

      final prompt = _buildStrategicForecastPrompt(businessData);
      final response = await callPerplexityAPI(prompt, model: reasoningModel);

      return _parseStrategicForecast(
        response['choices']?[0]?['message']?['content'] ?? '',
      );
    } catch (e) {
      debugPrint('Perplexity strategic forecasting error: $e');
      return _getDefaultStrategicForecast();
    }
  }

  String _buildStrategicForecastPrompt(Map<String, dynamic> businessData) {
    return '''
Generate comprehensive strategic plan with 60-90 day forecasting:

Business Data:
${jsonEncode(businessData)}

Provide strategic forecast in JSON:
{
  "forecast_60d": {
    "user_growth": {"predicted": 0, "confidence": 0-1},
    "revenue_growth": {"predicted": 0, "confidence": 0-1},
    "engagement_rate": {"predicted": 0-100, "confidence": 0-1},
    "key_opportunities": ["..."]
  },
  "forecast_90d": {
    "user_growth": {"predicted": 0, "confidence": 0-1},
    "revenue_growth": {"predicted": 0, "confidence": 0-1},
    "engagement_rate": {"predicted": 0-100, "confidence": 0-1},
    "key_opportunities": ["..."]
  },
  "strategic_recommendations": [
    {
      "recommendation": "...",
      "priority": "high|medium|low",
      "expected_impact": 0-100,
      "implementation_timeline": "...",
      "resources_required": ["..."]
    }
  ],
  "market_trends": ["..."],
  "competitive_analysis": {"threats": ["..."], "opportunities": ["..."]},
  "risk_factors": [{"risk": "...", "probability": 0-1, "impact": 0-100}]
}
''';
  }

  Map<String, dynamic> _parseStrategicForecast(String response) {
    try {
      return jsonDecode(response) as Map<String, dynamic>;
    } catch (e) {
      return _getDefaultStrategicForecast();
    }
  }

  Map<String, dynamic> _getDefaultStrategicForecast() {
    return {
      'forecast_60d': {
        'user_growth': {'predicted': 0, 'confidence': 0.5},
        'revenue_growth': {'predicted': 0, 'confidence': 0.5},
      },
      'forecast_90d': {
        'user_growth': {'predicted': 0, 'confidence': 0.5},
        'revenue_growth': {'predicted': 0, 'confidence': 0.5},
      },
      'strategic_recommendations': [],
      'market_trends': [],
    };
  }

  Future<Map<String, dynamic>> callPerplexityAPI(
    String prompt, {
    String model = proModel,
    String? searchRecencyFilter,
  }) async {
    // Start Datadog span
    final spanId = await _tracing.startSpan(
      'perplexity_api_call',
      resourceName: model,
      tags: {
        'perplexity.model': model,
        'perplexity.prompt_length': prompt.length.toString(),
        'perplexity.operation': 'api_call',
      },
    );

    final stopwatch = Stopwatch()..start();

    try {
      final response = await http
          .post(
            Uri.parse(apiUrl),
            headers: {
              'Authorization': 'Bearer $apiKey',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'model': model,
              'messages': [
                {'role': 'user', 'content': prompt},
              ],
              if (searchRecencyFilter != null)
                'search_recency_filter': searchRecencyFilter,
            }),
          )
          .timeout(const Duration(seconds: 30));

      stopwatch.stop();

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Finish span successfully
        await _tracing.finishSpan(
          spanId,
          tags: {
            'perplexity.success': 'true',
            'perplexity.response_length': response.body.length.toString(),
            'perplexity.duration_ms': stopwatch.elapsedMilliseconds.toString(),
            'perplexity.status_code': response.statusCode.toString(),
          },
        );

        return data;
      } else {
        // Finish span with error
        await _tracing.finishSpan(
          spanId,
          error: 'HTTP ${response.statusCode}: ${response.body}',
        );

        throw Exception('Perplexity API error: ${response.statusCode}');
      }
    } catch (e) {
      stopwatch.stop();

      // Finish span with error
      await _tracing.finishSpan(
        spanId,
        error: e.toString(),
        tags: {
          'perplexity.error': 'true',
          'perplexity.duration_ms': stopwatch.elapsedMilliseconds.toString(),
        },
      );

      debugPrint('Perplexity API call error: $e');
      rethrow;
    }
  }

  String _buildThreatPrompt(Map<String, dynamic> threatData) {
    return '''
Analyze current threat landscape and provide 60-90 day forecast:

Threat Data:
${jsonEncode(threatData)}

Provide analysis in JSON:
{
  "threat_level": "low|medium|high|critical",
  "emerging_vectors": [{"type": "...", "likelihood": 0-1, "impact": 0-1}],
  "forecast_60d": {"threat_probability": 0-1, "confidence": 0-1},
  "forecast_90d": {"threat_probability": 0-1, "confidence": 0-1},
  "seasonal_patterns": ["..."],
  "recommended_actions": ["..."],
  "related_questions": ["..."]
}
''';
  }

  String _buildSentimentPrompt(String topic, String? category) {
    return '''
Analyze market sentiment and brand perception for:

Topic: $topic
Category: ${category ?? 'general'}

Provide comprehensive sentiment analysis in JSON:
{
  "overall_sentiment": {"positive": 0-100, "neutral": 0-100, "negative": 0-100},
  "brand_mentions": [{"brand": "...", "sentiment_score": -1 to 1, "mention_count": 0}],
  "demographic_breakdown": {"age_groups": {...}, "regions": {...}},
  "emotional_response": [{"emotion": "...", "intensity": 0-1}],
  "trend_forecast_30d": {"direction": "up|down|stable", "confidence": 0-1},
  "competitive_intelligence": [{"competitor": "...", "market_share": 0-100}],
  "market_pulse": "..."
}
''';
  }

  String _buildFraudForecastPrompt(List<Map<String, dynamic>> historicalData) {
    return '''
Analyze fraud patterns and forecast future trends:

Historical Data:
${jsonEncode(historicalData)}

Provide forecast in JSON:
{
  "forecast_60d": {"fraud_probability": 0-1, "expected_incidents": 0, "confidence": 0-1},
  "forecast_90d": {"fraud_probability": 0-1, "expected_incidents": 0, "confidence": 0-1},
  "seasonal_analysis": {"high_risk_periods": ["..."], "patterns": ["..."]},
  "emerging_threats": [{"type": "...", "likelihood": 0-1}],
  "zone_vulnerability": [{"region": "...", "risk_score": 0-100}],
  "accuracy_metrics": {"historical_accuracy": 0-1}
}
''';
  }

  String _buildStrategicPrompt(Map<String, dynamic> businessData) {
    return '''
Generate strategic business plan based on market intelligence:

Business Data:
${jsonEncode(businessData)}

Provide strategic plan in JSON:
{
  "market_opportunities": [{"opportunity": "...", "potential_impact": 0-100, "feasibility": 0-1}],
  "growth_strategies": [{"strategy": "...", "expected_roi": 0-100, "timeline": "..."}],
  "competitive_threats": [{"threat": "...", "severity": 0-100, "mitigation": "..."}],
  "recommendations": [{"action": "...", "priority": "high|medium|low", "impact": 0-100}],
  "strategic_overview": "..."
}
''';
  }

  Map<String, dynamic> _parseThreatResponse(String response) {
    try {
      return jsonDecode(response) as Map<String, dynamic>;
    } catch (e) {
      return _getDefaultThreatAnalysis();
    }
  }

  Map<String, dynamic> _parseSentimentResponse(String response) {
    try {
      return jsonDecode(response) as Map<String, dynamic>;
    } catch (e) {
      return _getDefaultSentimentAnalysis();
    }
  }

  Map<String, dynamic> _parseFraudForecast(String response) {
    try {
      return jsonDecode(response) as Map<String, dynamic>;
    } catch (e) {
      return _getDefaultFraudForecast();
    }
  }

  Map<String, dynamic> _parseStrategicPlan(String response) {
    try {
      return jsonDecode(response) as Map<String, dynamic>;
    } catch (e) {
      return _getDefaultStrategicPlan();
    }
  }

  /// Extended 90-day fraud forecasting with cross-zone analysis
  Future<Map<String, dynamic>> forecast90DayThreats({
    required List<Map<String, dynamic>> historicalData,
    List<String>? targetZones,
  }) async {
    try {
      if (apiKey.isEmpty || apiKey == 'your-perplexity-api-key-here') {
        return _getDefault90DayForecast();
      }

      final prompt = _build90DayForecastPrompt(historicalData, targetZones);
      final response = await callPerplexityAPI(
        prompt,
        model: reasoningModel,
        searchRecencyFilter: 'month',
      );

      final forecast = _parse90DayForecast(
        response['choices']?[0]?['message']?['content'] ?? '',
      );

      // Store forecast in database
      await _storeThreatForecast(forecast);

      return forecast;
    } catch (e) {
      debugPrint('Perplexity 90-day forecast error: $e');
      return _getDefault90DayForecast();
    }
  }

  /// Detect coordinated voting patterns across zones
  Future<Map<String, dynamic>> detectCrossZonePatterns({
    required List<String> zones,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      if (apiKey.isEmpty || apiKey == 'your-perplexity-api-key-here') {
        return _getDefaultCrossZoneAnalysis();
      }

      final prompt = _buildCrossZonePrompt(zones, startDate, endDate);
      final response = await callPerplexityAPI(prompt, model: reasoningModel);

      final analysis = _parseCrossZoneAnalysis(
        response['choices']?[0]?['message']?['content'] ?? '',
      );

      // Store pattern detection
      if (analysis['patterns_detected'] == true) {
        await _storeCrossZonePattern(analysis);
      }

      return analysis;
    } catch (e) {
      debugPrint('Cross-zone pattern detection error: $e');
      return _getDefaultCrossZoneAnalysis();
    }
  }

  /// Get threat forecasting reports
  Future<List<Map<String, dynamic>>> getThreatForecastingReports({
    String? forecastPeriod,
    int limit = 10,
  }) async {
    try {
      var query = _client
          .from('threat_forecasting_reports')
          .select()
          .order('generated_at', ascending: false)
          .limit(limit);

      if (forecastPeriod != null) {
        query = _client
            .from('threat_forecasting_reports')
            .select()
            .eq('forecast_period', forecastPeriod)
            .order('generated_at', ascending: false)
            .limit(limit);
      }

      final response = await query;
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get threat forecasting reports error: $e');
      return [];
    }
  }

  /// Get cross-zone fraud patterns
  Future<List<Map<String, dynamic>>> getCrossZoneFraudPatterns({
    String? riskAssessment,
    int limit = 20,
  }) async {
    try {
      var query = _client
          .from('cross_zone_fraud_patterns')
          .select()
          .order('detection_timestamp', ascending: false)
          .limit(limit);

      if (riskAssessment != null) {
        query = _client
            .from('cross_zone_fraud_patterns')
            .select()
            .eq('risk_assessment', riskAssessment)
            .order('detection_timestamp', ascending: false)
            .limit(limit);
      }

      final response = await query;
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get cross-zone fraud patterns error: $e');
      return [];
    }
  }

  String _build90DayForecastPrompt(
    List<Map<String, dynamic>> historicalData,
    List<String>? targetZones,
  ) {
    return '''
Generate comprehensive 90-day fraud threat forecast with cross-zone analysis:

Historical Fraud Data:
${jsonEncode(historicalData)}

Target Zones: ${targetZones?.join(', ') ?? 'All 8 zones (US_Canada, Western_Europe, Eastern_Europe, Africa, Latin_America, Middle_East_Asia, Australasia, China_Hong_Kong)'}

Provide detailed forecast in JSON:
{
  "forecast_30d": {
    "threat_probability": 0-1,
    "confidence": 0-1,
    "emerging_threats": [{"type": "...", "zones": [...], "likelihood": 0-1}],
    "key_risks": ["..."]
  },
  "forecast_60d": {
    "threat_probability": 0-1,
    "confidence": 0-1,
    "emerging_threats": [{"type": "...", "zones": [...], "likelihood": 0-1}],
    "key_risks": ["..."]
  },
  "forecast_90d": {
    "threat_probability": 0-1,
    "confidence": 0-1,
    "emerging_threats": [{"type": "...", "zones": [...], "likelihood": 0-1}],
    "key_risks": ["..."]
  },
  "cross_zone_correlation": {
    "coordinated_patterns": [{"zones": [...], "pattern_type": "...", "confidence": 0-1}],
    "synchronized_activities": ["..."]
  },
  "seasonal_anomalies": [
    {"quarter": "Q1|Q2|Q3|Q4", "anomaly_type": "...", "expected_impact": 0-100}
  ],
  "zone_vulnerabilities": {
    "US_Canada": {"risk_score": 0-100, "vulnerabilities": ["..."]},
    "Western_Europe": {"risk_score": 0-100, "vulnerabilities": ["..."]}
  },
  "recommendations": [
    {"priority": "high|medium|low", "action": "...", "target_zones": [...]}
  ]
}
''';
  }

  String _buildCrossZonePrompt(
    List<String> zones,
    DateTime startDate,
    DateTime endDate,
  ) {
    return '''
Analyze coordinated fraud patterns across multiple purchasing power zones:

Zones: ${zones.join(', ')}
Time Period: ${startDate.toIso8601String()} to ${endDate.toIso8601String()}

Detect and analyze:
1. Synchronized account creation patterns
2. Coordinated voting attempts
3. Cross-border fraud correlation
4. Timing-based attack patterns

Provide analysis in JSON:
{
  "patterns_detected": true|false,
  "pattern_type": "synchronized_accounts|coordinated_voting|timing_attack|other",
  "affected_zones": [...],
  "confidence_score": 0-1,
  "pattern_description": "...",
  "coordinated_accounts": [{"account_id": "...", "zone": "...", "created_at": "..."}],
  "synchronized_actions": [{"action_type": "...", "timestamp": "...", "accounts": [...]}],
  "risk_assessment": "low|medium|high|critical",
  "recommended_actions": ["..."]
}
''';
  }

  Map<String, dynamic> _parse90DayForecast(String response) {
    try {
      return jsonDecode(response) as Map<String, dynamic>;
    } catch (e) {
      return _getDefault90DayForecast();
    }
  }

  Map<String, dynamic> _parseCrossZoneAnalysis(String response) {
    try {
      return jsonDecode(response) as Map<String, dynamic>;
    } catch (e) {
      return _getDefaultCrossZoneAnalysis();
    }
  }

  Future<void> _storeThreatForecast(Map<String, dynamic> forecast) async {
    try {
      await _client.from('threat_forecasting_reports').insert({
        'forecast_period': '90_days',
        'threat_level': _determineThreatLevel(forecast),
        'confidence_score': forecast['forecast_90d']?['confidence'] ?? 0.5,
        'emerging_threats': forecast['forecast_90d']?['emerging_threats'] ?? [],
        'zone_vulnerabilities': forecast['zone_vulnerabilities'] ?? {},
        'coordinated_patterns':
            forecast['cross_zone_correlation']?['coordinated_patterns'] ?? [],
        'seasonal_anomalies': forecast['seasonal_anomalies'] ?? [],
        'cross_zone_correlation': forecast['cross_zone_correlation'] ?? {},
        'recommendations': forecast['recommendations'] ?? [],
        'perplexity_raw_response': forecast,
      });
    } catch (e) {
      debugPrint('Store threat forecast error: $e');
    }
  }

  Future<void> _storeCrossZonePattern(Map<String, dynamic> analysis) async {
    try {
      await _client.from('cross_zone_fraud_patterns').insert({
        'pattern_type': analysis['pattern_type'] ?? 'unknown',
        'affected_zones': analysis['affected_zones'] ?? [],
        'confidence_score': analysis['confidence_score'] ?? 0.0,
        'pattern_description': analysis['pattern_description'] ?? '',
        'coordinated_accounts': analysis['coordinated_accounts'] ?? [],
        'synchronized_actions': analysis['synchronized_actions'] ?? [],
        'risk_assessment': analysis['risk_assessment'] ?? 'medium',
      });
    } catch (e) {
      debugPrint('Store cross-zone pattern error: $e');
    }
  }

  String _determineThreatLevel(Map<String, dynamic> forecast) {
    final threatProb = forecast['forecast_90d']?['threat_probability'] ?? 0.0;
    if (threatProb >= 0.8) return 'critical';
    if (threatProb >= 0.6) return 'high';
    if (threatProb >= 0.4) return 'medium';
    return 'low';
  }

  Map<String, dynamic> _getDefault90DayForecast() {
    return {
      'forecast_30d': {
        'threat_probability': 0.3,
        'confidence': 0.5,
        'emerging_threats': [],
      },
      'forecast_60d': {
        'threat_probability': 0.35,
        'confidence': 0.5,
        'emerging_threats': [],
      },
      'forecast_90d': {
        'threat_probability': 0.4,
        'confidence': 0.5,
        'emerging_threats': [],
      },
      'cross_zone_correlation': {'coordinated_patterns': []},
      'seasonal_anomalies': [],
      'zone_vulnerabilities': {},
      'recommendations': [],
    };
  }

  Map<String, dynamic> _getDefaultCrossZoneAnalysis() {
    return {
      'patterns_detected': false,
      'pattern_type': 'none',
      'affected_zones': [],
      'confidence_score': 0.0,
      'pattern_description': 'No patterns detected',
      'coordinated_accounts': [],
      'synchronized_actions': [],
      'risk_assessment': 'low',
      'recommended_actions': [],
    };
  }

  Map<String, dynamic> _getDefaultThreatAnalysis() {
    return {
      'threat_level': 'low',
      'emerging_vectors': [],
      'forecast_60d': {'threat_probability': 0.0, 'confidence': 0.0},
    };
  }

  Map<String, dynamic> _getDefaultSentimentAnalysis() {
    return {
      'overall_sentiment': {'positive': 50, 'neutral': 30, 'negative': 20},
      'brand_mentions': [],
      'market_pulse': 'Unable to analyze sentiment',
    };
  }

  Map<String, dynamic> _getDefaultFraudForecast() {
    return {
      'forecast_60d': {
        'fraud_probability': 0.0,
        'expected_incidents': 0,
        'confidence': 0.0,
      },
    };
  }

  Map<String, dynamic> _getDefaultStrategicPlan() {
    return {
      'market_opportunities': [],
      'growth_strategies': [],
      'recommendations': [],
      'strategic_overview': 'Unable to generate strategic plan',
    };
  }
}
