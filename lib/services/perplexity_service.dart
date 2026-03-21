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

  bool get _perplexityConfigured =>
      apiKey.isNotEmpty && apiKey != 'your-perplexity-api-key-here';

  List<Map<String, dynamic>> _asMapList(dynamic raw) {
    if (raw is! List) return [];
    final out = <Map<String, dynamic>>[];
    for (final e in raw) {
      if (e is Map<String, dynamic>) {
        out.add(e);
      } else if (e is Map) {
        out.add(Map<String, dynamic>.from(e));
      }
    }
    return out;
  }

  /// Extract first JSON object from model output (handles ```json fences).
  Map<String, dynamic>? _parseJsonObjectFromModelContent(String response) {
    try {
      final cleaned = response
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();
      final match = RegExp(r'\{[\s\S]*\}').firstMatch(cleaned);
      if (match == null) return null;
      final decoded = jsonDecode(match.group(0)!);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } catch (e) {
      debugPrint('Perplexity JSON extract error: $e');
    }
    return null;
  }

  /// Live Supabase snapshot for fallbacks (same tables as Web `getInternalMarketResearchContext`).
  Future<Map<String, dynamic>> _fetchInternalRiskMetrics({int days = 30}) async {
    final since = DateTime.now().subtract(Duration(days: days)).toIso8601String();
    try {
      final fraud = await _client
          .from('fraud_alerts')
          .select('id, severity, user_id, created_at')
          .gte('created_at', since)
          .limit(500);
      final votes = await _client
          .from('votes')
          .select('id, user_id, created_at')
          .gte('created_at', since)
          .limit(5000);
      final moderation = await _client
          .from('content_moderation_results')
          .select('id, auto_removed, created_at')
          .gte('created_at', since)
          .limit(2000);
      final anomalies = await _client
          .from('revenue_anomalies')
          .select('id, severity, created_at')
          .gte('created_at', since)
          .limit(500);
      final flags = await _client
          .from('content_flags')
          .select('id, severity, status, created_at')
          .gte('created_at', since)
          .limit(500);

      final fraudList = _asMapList(fraud);
      final voteList = _asMapList(votes);
      final fraudUsers =
          fraudList.map((r) => r['user_id']).whereType<String>().toSet();
      var overlapUsers = 0;
      final voteUsers = <String>{};
      for (final v in voteList) {
        final uid = v['user_id']?.toString();
        if (uid == null) continue;
        voteUsers.add(uid);
        if (fraudUsers.contains(uid)) overlapUsers++;
      }

      final highFraud = fraudList.where((r) {
        final s = (r['severity'] ?? '').toString().toLowerCase();
        return s == 'high' || s == 'critical';
      }).length;

      return {
        'window_days': days,
        'since': since,
        'fraud_alerts': fraudList.length,
        'fraud_high_critical': highFraud,
        'votes': voteList.length,
        'moderation_results': _asMapList(moderation).length,
        'revenue_anomalies': _asMapList(anomalies).length,
        'content_flags': _asMapList(flags).length,
        'fraud_vote_user_overlap': overlapUsers,
        'distinct_voting_users_sample': voteUsers.length,
      };
    } catch (e) {
      debugPrint('Internal risk metrics error: $e');
      return {
        'window_days': days,
        'since': since,
        'fraud_alerts': 0,
        'fraud_high_critical': 0,
        'votes': 0,
        'moderation_results': 0,
        'revenue_anomalies': 0,
        'content_flags': 0,
        'fraud_vote_user_overlap': 0,
        'distinct_voting_users_sample': 0,
        'metrics_error': e.toString(),
      };
    }
  }

  Map<String, dynamic> _threatAnalysisFromMetrics(Map<String, dynamic> m) {
    final fraud = (m['fraud_alerts'] as int?) ?? 0;
    final votes = (m['votes'] as int?) ?? 0;
    final overlap = (m['fraud_vote_user_overlap'] as int?) ?? 0;
    final ratio = votes > 0 ? fraud / votes : 0.0;
    String level = 'low';
    if (fraud > 50 || ratio > 0.08 || overlap > 15) level = 'critical';
    else if (fraud > 20 || ratio > 0.04 || overlap > 5) level = 'high';
    else if (fraud > 5 || ratio > 0.015) level = 'medium';
    final p = (ratio * 3).clamp(0.0, 0.95);
    return {
      'threat_level': level,
      'emerging_vectors': <Map<String, dynamic>>[],
      'forecast_60d': {
        'threat_probability': p,
        'confidence': votes > 0 ? 0.55 : 0.25,
      },
      'forecast_90d': {
        'threat_probability': (p * 1.05).clamp(0.0, 0.95),
        'confidence': votes > 0 ? 0.45 : 0.2,
      },
      'seasonal_patterns': <String>[],
      'recommended_actions': [
        if (fraud > 0) 'Review open fraud_alerts for the selected window',
        if (overlap > 0)
          'Investigate users appearing in both fraud_alerts and votes',
      ],
      'source': 'supabase_internal_metrics',
      'internal_metrics': m,
    };
  }

  Map<String, dynamic> _fraudForecastFromMetrics(Map<String, dynamic> m) {
    final fraud = (m['fraud_alerts'] as int?) ?? 0;
    final votes = (m['votes'] as int?) ?? 0;
    final base = votes > 0 ? (fraud / votes).clamp(0.0, 1.0) : 0.0;
    return {
      'forecast_60d': {
        'fraud_probability': (base * 1.2).clamp(0.0, 0.95),
        'expected_incidents': fraud,
        'confidence': votes > 0 ? 0.5 : 0.2,
      },
      'forecast_90d': {
        'fraud_probability': (base * 1.35).clamp(0.0, 0.95),
        'expected_incidents': fraud,
        'confidence': votes > 0 ? 0.4 : 0.15,
      },
      'seasonal_analysis': {
        'high_risk_periods': <String>[],
        'patterns': <String>[],
      },
      'emerging_threats': <Map<String, dynamic>>[],
      'zone_vulnerability': <Map<String, dynamic>>[],
      'accuracy_metrics': {'historical_accuracy': 0.0},
      'source': 'supabase_internal_metrics',
      'internal_metrics': m,
    };
  }

  Map<String, dynamic> _strategicPlanFromMetrics(Map<String, dynamic> m) {
    return {
      'market_opportunities': <Map<String, dynamic>>[],
      'growth_strategies': <Map<String, dynamic>>[],
      'competitive_threats': <Map<String, dynamic>>[],
      'recommendations': [
        if (((m['content_flags'] as int?) ?? 0) > 0)
          {
            'action': 'Clear moderation backlog (content_flags)',
            'priority': 'high',
            'impact': 70,
          },
        if (((m['revenue_anomalies'] as int?) ?? 0) > 0)
          {
            'action': 'Reconcile revenue_anomalies',
            'priority': 'medium',
            'impact': 55,
          },
      ],
      'strategic_overview':
          'Perplexity Sonar unavailable — showing internal platform signals only: '
          '${m['fraud_alerts']} fraud_alerts, ${m['votes']} votes, '
          '${m['moderation_results']} moderation results in ${m['window_days']}d.',
      'source': 'supabase_internal_metrics',
      'internal_metrics': m,
    };
  }

  Map<String, dynamic> _strategicForecastFromMetrics(Map<String, dynamic> m) {
    final engagement =
        ((m['votes'] as int?) ?? 0) > 100 ? 65.0 : 40.0;
    return {
      'forecast_60d': {
        'user_growth': {'predicted': 0, 'confidence': 0.35},
        'revenue_growth': {'predicted': 0, 'confidence': 0.35},
        'engagement_rate': {'predicted': engagement, 'confidence': 0.4},
        'key_opportunities': <String>[],
      },
      'forecast_90d': {
        'user_growth': {'predicted': 0, 'confidence': 0.3},
        'revenue_growth': {'predicted': 0, 'confidence': 0.3},
        'engagement_rate': {'predicted': engagement, 'confidence': 0.35},
        'key_opportunities': <String>[],
      },
      'strategic_recommendations': <Map<String, dynamic>>[],
      'market_trends': <String>[],
      'source': 'supabase_internal_metrics',
      'internal_metrics': m,
    };
  }

  Map<String, dynamic> _emptySentimentFallback() {
    return {
      'overall_sentiment': {'positive': 0, 'neutral': 0, 'negative': 0},
      'brand_mentions': <Map<String, dynamic>>[],
      'demographic_breakdown': <String, dynamic>{},
      'emotional_response': <Map<String, dynamic>>[],
      'market_pulse':
          'External sentiment not available (configure PERPLEXITY_API_KEY or check network).',
      'source': 'unavailable',
    };
  }

  Future<Map<String, dynamic>> _internal90DayForecastFromDb() async {
    final m = await _fetchInternalRiskMetrics(days: 30);
    final fraud = (m['fraud_alerts'] as int?) ?? 0;
    final votes = (m['votes'] as int?) ?? 0;
    final base = votes > 0 ? (fraud / votes).clamp(0.0, 1.0) : 0.0;
    double p30 = (base * 2).clamp(0.0, 0.9);
    return {
      'forecast_30d': {
        'threat_probability': p30,
        'confidence': votes > 0 ? 0.45 : 0.2,
        'emerging_threats': <Map<String, dynamic>>[],
        'key_risks': <String>[
          if (fraud > 0) '$fraud fraud_alerts in last 30d',
        ],
      },
      'forecast_60d': {
        'threat_probability': (p30 * 1.1).clamp(0.0, 0.92),
        'confidence': votes > 0 ? 0.4 : 0.18,
        'emerging_threats': <Map<String, dynamic>>[],
        'key_risks': <String>[],
      },
      'forecast_90d': {
        'threat_probability': (p30 * 1.2).clamp(0.0, 0.95),
        'confidence': votes > 0 ? 0.35 : 0.15,
        'emerging_threats': <Map<String, dynamic>>[],
        'key_risks': <String>[],
      },
      'cross_zone_correlation': {'coordinated_patterns': <dynamic>[]},
      'seasonal_anomalies': <dynamic>[],
      'zone_vulnerabilities': <String, dynamic>{},
      'recommendations': <dynamic>[],
      'source': 'supabase_internal_metrics',
      'internal_metrics': m,
    };
  }

  Future<Map<String, dynamic>> _internalCrossZoneFromDb(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final m = await _fetchInternalRiskMetrics(days: 30);
    final start = startDate.toIso8601String();
    final end = endDate.toIso8601String();
    try {
      final fraud = await _client
          .from('fraud_alerts')
          .select('user_id, created_at')
          .gte('created_at', start)
          .lte('created_at', end)
          .limit(500);
      final votes = await _client
          .from('votes')
          .select('user_id, created_at')
          .gte('created_at', start)
          .lte('created_at', end)
          .limit(5000);
      final fList = _asMapList(fraud);
      final vList = _asMapList(votes);
      final fUsers = fList.map((e) => e['user_id']).whereType<String>().toSet();
      var overlap = 0;
      for (final v in vList) {
        final u = v['user_id']?.toString();
        if (u != null && fUsers.contains(u)) overlap++;
      }
      final detected = overlap > 3;
      return {
        'patterns_detected': detected,
        'pattern_type': detected ? 'coordinated_voting' : 'other',
        'affected_zones': <String>[],
        'confidence_score': vList.isEmpty
            ? 0.0
            : (overlap / vList.length).clamp(0.0, 1.0),
        'pattern_description': detected
            ? '$overlap vote events from users with fraud alerts in range'
            : 'No strong user-level overlap between fraud_alerts and votes',
        'coordinated_accounts': <dynamic>[],
        'synchronized_actions': <dynamic>[],
        'risk_assessment': detected ? 'medium' : 'low',
        'recommended_actions': <String>[
          if (detected) 'Manual review: fraud-flagged users with votes in window',
        ],
        'source': 'supabase_internal_heuristic',
        'internal_metrics': m,
      };
    } catch (e) {
      return {
        'patterns_detected': false,
        'pattern_type': 'none',
        'affected_zones': <String>[],
        'confidence_score': 0.0,
        'pattern_description': 'Cross-zone heuristic failed: $e',
        'coordinated_accounts': <dynamic>[],
        'synchronized_actions': <dynamic>[],
        'risk_assessment': 'low',
        'recommended_actions': <String>[],
        'source': 'error',
        'internal_metrics': m,
      };
    }
  }

  /// Static method for threat intelligence analysis (used for health checks)
  static Future<Map<String, dynamic>> analyzeThreatIntelligence({
    required Map<String, dynamic> threatContext,
  }) async {
    return instance.analyzeThreatIntelligenceInstance(
      threatData: threatContext,
    );
  }

  /// Parity with Web `perplexityMarketResearchService.getInternalMarketResearchContext`.
  static Future<Map<String, dynamic>> getInternalMarketResearchContext({
    int days = 30,
  }) async {
    final m = await instance._fetchInternalRiskMetrics(days: days);
    final err = m['metrics_error']?.toString();
    final body = {
      'windowDays': days,
      'since': m['since'],
      'fraudAlerts': m['fraud_alerts'],
      'fraudHighOrCritical': m['fraud_high_critical'],
      'votes': m['votes'],
      'moderationResults': m['moderation_results'],
      'revenueAnomalies': m['revenue_anomalies'],
      'contentFlags': m['content_flags'],
    };
    if (err != null && err.isNotEmpty) {
      return {'success': false, 'error': err, ...body};
    }
    return {'success': true, ...body};
  }

  Future<Map<String, dynamic>> analyzeThreatIntelligenceInstance({
    required Map<String, dynamic> threatData,
  }) async {
    try {
      if (!_perplexityConfigured) {
        final m = await _fetchInternalRiskMetrics();
        return _threatAnalysisFromMetrics(m);
      }

      final prompt = _buildThreatPrompt(threatData);
      final response = await callPerplexityAPI(
        prompt,
        model: reasoningModel,
        searchRecencyFilter: 'week',
      );

      final parsed = _parseThreatResponse(
        response['choices']?[0]?['message']?['content'] ?? '',
      );
      if (parsed['source'] == 'parse_failed') {
        final m = await _fetchInternalRiskMetrics();
        return {..._threatAnalysisFromMetrics(m), 'perplexity_parse_failed': true};
      }
      return parsed;
    } catch (e) {
      debugPrint('Perplexity threat analysis error: $e');
      final m = await _fetchInternalRiskMetrics();
      return {..._threatAnalysisFromMetrics(m), 'perplexity_error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> analyzeMarketSentiment({
    required String topic,
    String? category,
  }) async {
    try {
      if (!_perplexityConfigured) {
        final m = await _fetchInternalRiskMetrics();
        return {
          ..._emptySentimentFallback(),
          'topic': topic,
          'category': category,
          'internal_metrics': m,
        };
      }

      final prompt = _buildSentimentPrompt(topic, category);
      final response = await callPerplexityAPI(
        prompt,
        model: proModel,
        searchRecencyFilter: 'month',
      );

      final parsed = _parseSentimentResponse(
        response['choices']?[0]?['message']?['content'] ?? '',
      );
      if (parsed['source'] == 'parse_failed') {
        final m = await _fetchInternalRiskMetrics();
        return {
          ..._emptySentimentFallback(),
          'topic': topic,
          'internal_metrics': m,
          'perplexity_parse_failed': true,
        };
      }
      return parsed;
    } catch (e) {
      debugPrint('Perplexity sentiment analysis error: $e');
      final m = await _fetchInternalRiskMetrics();
      return {
        ..._emptySentimentFallback(),
        'topic': topic,
        'internal_metrics': m,
        'perplexity_error': e.toString(),
      };
    }
  }

  Future<Map<String, dynamic>> forecastFraudTrends({
    required List<Map<String, dynamic>> historicalData,
  }) async {
    try {
      if (!_perplexityConfigured) {
        final m = await _fetchInternalRiskMetrics();
        return _fraudForecastFromMetrics(m);
      }

      final prompt = _buildFraudForecastPrompt(historicalData);
      final response = await callPerplexityAPI(prompt, model: reasoningModel);

      final parsed = _parseFraudForecast(
        response['choices']?[0]?['message']?['content'] ?? '',
      );
      if (parsed['source'] == 'parse_failed') {
        final m = await _fetchInternalRiskMetrics();
        return {..._fraudForecastFromMetrics(m), 'perplexity_parse_failed': true};
      }
      return parsed;
    } catch (e) {
      debugPrint('Perplexity fraud forecast error: $e');
      final m = await _fetchInternalRiskMetrics();
      return {..._fraudForecastFromMetrics(m), 'perplexity_error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> generateStrategicPlan({
    required Map<String, dynamic> businessData,
  }) async {
    try {
      if (!_perplexityConfigured) {
        final m = await _fetchInternalRiskMetrics();
        return _strategicPlanFromMetrics(m);
      }

      final prompt = _buildStrategicPrompt(businessData);
      final response = await callPerplexityAPI(prompt, model: reasoningModel);

      final parsed = _parseStrategicPlan(
        response['choices']?[0]?['message']?['content'] ?? '',
      );
      if (parsed['source'] == 'parse_failed') {
        final m = await _fetchInternalRiskMetrics();
        return {..._strategicPlanFromMetrics(m), 'perplexity_parse_failed': true};
      }
      return parsed;
    } catch (e) {
      debugPrint('Perplexity strategic planning error: $e');
      final m = await _fetchInternalRiskMetrics();
      return {..._strategicPlanFromMetrics(m), 'perplexity_error': e.toString()};
    }
  }

  /// Strategic planning with 60-90 day forecasting
  Future<Map<String, dynamic>> generateStrategicPlanWithForecasting({
    required Map<String, dynamic> businessData,
  }) async {
    try {
      if (!_perplexityConfigured) {
        final m = await _fetchInternalRiskMetrics();
        return _strategicForecastFromMetrics(m);
      }

      final prompt = _buildStrategicForecastPrompt(businessData);
      final response = await callPerplexityAPI(prompt, model: reasoningModel);

      final parsed = _parseStrategicForecast(
        response['choices']?[0]?['message']?['content'] ?? '',
      );
      if (parsed['source'] == 'parse_failed') {
        final m = await _fetchInternalRiskMetrics();
        return {
          ..._strategicForecastFromMetrics(m),
          'perplexity_parse_failed': true,
        };
      }
      return parsed;
    } catch (e) {
      debugPrint('Perplexity strategic forecasting error: $e');
      final m = await _fetchInternalRiskMetrics();
      return {
        ..._strategicForecastFromMetrics(m),
        'perplexity_error': e.toString(),
      };
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
    final parsed = _parseJsonObjectFromModelContent(response);
    if (parsed != null) return parsed;
    return {
      'forecast_60d': {
        'user_growth': {'predicted': 0, 'confidence': 0.0},
        'revenue_growth': {'predicted': 0, 'confidence': 0.0},
      },
      'forecast_90d': {
        'user_growth': {'predicted': 0, 'confidence': 0.0},
        'revenue_growth': {'predicted': 0, 'confidence': 0.0},
      },
      'strategic_recommendations': <Map<String, dynamic>>[],
      'market_trends': <String>[],
      'source': 'parse_failed',
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
    final parsed = _parseJsonObjectFromModelContent(response);
    if (parsed != null) return parsed;
    return {
      'threat_level': 'low',
      'emerging_vectors': <Map<String, dynamic>>[],
      'forecast_60d': {'threat_probability': 0.0, 'confidence': 0.0},
      'source': 'parse_failed',
    };
  }

  Map<String, dynamic> _parseSentimentResponse(String response) {
    final parsed = _parseJsonObjectFromModelContent(response);
    if (parsed != null) return parsed;
    return {..._emptySentimentFallback(), 'source': 'parse_failed'};
  }

  Map<String, dynamic> _parseFraudForecast(String response) {
    final parsed = _parseJsonObjectFromModelContent(response);
    if (parsed != null) return parsed;
    return {
      'forecast_60d': {
        'fraud_probability': 0.0,
        'expected_incidents': 0,
        'confidence': 0.0,
      },
      'source': 'parse_failed',
    };
  }

  Map<String, dynamic> _parseStrategicPlan(String response) {
    final parsed = _parseJsonObjectFromModelContent(response);
    if (parsed != null) return parsed;
    return {
      'market_opportunities': <Map<String, dynamic>>[],
      'growth_strategies': <Map<String, dynamic>>[],
      'recommendations': <Map<String, dynamic>>[],
      'strategic_overview': 'Model output could not be parsed as JSON.',
      'source': 'parse_failed',
    };
  }

  /// Extended 90-day fraud forecasting with cross-zone analysis
  Future<Map<String, dynamic>> forecast90DayThreats({
    required List<Map<String, dynamic>> historicalData,
    List<String>? targetZones,
  }) async {
    try {
      if (!_perplexityConfigured) {
        return _internal90DayForecastFromDb();
      }

      final prompt = _build90DayForecastPrompt(historicalData, targetZones);
      final response = await callPerplexityAPI(
        prompt,
        model: reasoningModel,
        searchRecencyFilter: 'month',
      );

      var forecast = _parse90DayForecast(
        response['choices']?[0]?['message']?['content'] ?? '',
      );
      if (forecast['source'] == 'parse_failed') {
        forecast = await _internal90DayForecastFromDb();
        forecast['perplexity_parse_failed'] = true;
      }

      await _storeThreatForecast(forecast);

      return forecast;
    } catch (e) {
      debugPrint('Perplexity 90-day forecast error: $e');
      final f = await _internal90DayForecastFromDb();
      return {...f, 'perplexity_error': e.toString()};
    }
  }

  /// Detect coordinated voting patterns across zones
  Future<Map<String, dynamic>> detectCrossZonePatterns({
    required List<String> zones,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      if (!_perplexityConfigured) {
        return _internalCrossZoneFromDb(startDate, endDate);
      }

      final prompt = _buildCrossZonePrompt(zones, startDate, endDate);
      final response = await callPerplexityAPI(prompt, model: reasoningModel);

      var analysis = _parseCrossZoneAnalysis(
        response['choices']?[0]?['message']?['content'] ?? '',
      );

      if (analysis['source'] == 'parse_failed') {
        analysis = await _internalCrossZoneFromDb(startDate, endDate);
        analysis['perplexity_parse_failed'] = true;
      }

      if (analysis['patterns_detected'] == true) {
        await _storeCrossZonePattern(analysis);
      }

      return analysis;
    } catch (e) {
      debugPrint('Cross-zone pattern detection error: $e');
      final a = await _internalCrossZoneFromDb(startDate, endDate);
      return {...a, 'perplexity_error': e.toString()};
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
    final parsed = _parseJsonObjectFromModelContent(response);
    if (parsed != null) return parsed;
    return {
      'forecast_30d': {
        'threat_probability': 0.0,
        'confidence': 0.0,
        'emerging_threats': <Map<String, dynamic>>[],
      },
      'forecast_60d': {
        'threat_probability': 0.0,
        'confidence': 0.0,
        'emerging_threats': <Map<String, dynamic>>[],
      },
      'forecast_90d': {
        'threat_probability': 0.0,
        'confidence': 0.0,
        'emerging_threats': <Map<String, dynamic>>[],
      },
      'cross_zone_correlation': {'coordinated_patterns': <dynamic>[]},
      'seasonal_anomalies': <dynamic>[],
      'zone_vulnerabilities': <String, dynamic>{},
      'recommendations': <dynamic>[],
      'source': 'parse_failed',
    };
  }

  Map<String, dynamic> _parseCrossZoneAnalysis(String response) {
    final parsed = _parseJsonObjectFromModelContent(response);
    if (parsed != null) return parsed;
    return {
      'patterns_detected': false,
      'pattern_type': 'none',
      'affected_zones': <String>[],
      'confidence_score': 0.0,
      'pattern_description': 'Model output could not be parsed as JSON.',
      'coordinated_accounts': <dynamic>[],
      'synchronized_actions': <dynamic>[],
      'risk_assessment': 'low',
      'recommended_actions': <String>[],
      'source': 'parse_failed',
    };
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
    final raw = forecast['forecast_90d']?['threat_probability'];
    final threatProb = raw is num ? raw.toDouble() : 0.0;
    if (threatProb >= 0.8) return 'critical';
    if (threatProb >= 0.6) return 'high';
    if (threatProb >= 0.4) return 'medium';
    return 'low';
  }
}
