import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/market_research_result.dart';
import '../../models/strategic_planning_report.dart';
import '../../models/threat_intelligence_report.dart';
import './ai_service_base.dart';

/// Perplexity Market Intelligence Service
/// Comprehensive market intelligence using Perplexity's web search capabilities
/// for threat intelligence, market research, and strategic planning
class PerplexityService extends AIServiceBase {
  static PerplexityService? _instance;
  static PerplexityService get instance => _instance ??= PerplexityService._();

  PerplexityService._();

  static final SupabaseClient supabase = Supabase.instance.client;

  /// Real-time threat intelligence with web search
  ///
  /// Analyzes current threat landscape using Perplexity's web search
  /// Provides 60-90 day threat forecasting with real-time data
  ///
  /// [forecastPeriod] - Forecast period (60_days or 90_days)
  ///
  /// Returns [ThreatIntelligenceReport] with threat analysis and forecasts
  static Future<ThreatIntelligenceReport> getThreatIntelligence({
    String forecastPeriod = '90_days',
  }) async {
    try {
      final response = await AIServiceBase.invokeAIFunction(
        'perplexity-threat-intelligence',
        {
          'forecast_period': forecastPeriod,
          'include_web_search': true,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      AIServiceBase.validateResponse(response, [
        'report_id',
        'threat_level',
        'emerging_threats',
      ]);

      return ThreatIntelligenceReport.fromJson(response);
    } catch (e) {
      throw AIServiceException(
        'Failed to get threat intelligence: ${e.toString()}',
        e,
      );
    }
  }

  /// Market research and sentiment analysis
  ///
  /// Conducts comprehensive market research using web search
  /// Analyzes market trends, sentiment, and competitive landscape
  ///
  /// [topics] - List of topics to research
  /// [timeframe] - Research timeframe (last_7_days, last_30_days, last_90_days)
  ///
  /// Returns [MarketResearchResult] with research findings and sentiment analysis
  static Future<MarketResearchResult> conductMarketResearch({
    required List<String> topics,
    String timeframe = 'last_30_days',
  }) async {
    try {
      final response =
          await AIServiceBase.invokeAIFunction('perplexity-market-research', {
            'topics': topics,
            'timeframe': timeframe,
            'include_sentiment': true,
            'timestamp': DateTime.now().toIso8601String(),
          });

      AIServiceBase.validateResponse(response, [
        'research_id',
        'topics',
        'sentiment_score',
      ]);

      return MarketResearchResult.fromJson(response);
    } catch (e) {
      throw AIServiceException(
        'Failed to conduct market research: ${e.toString()}',
        e,
      );
    }
  }

  /// Strategic planning with competitive analysis
  ///
  /// Generates strategic insights using comprehensive web research
  /// Includes competitive analysis, market opportunities, and risk assessment
  ///
  /// Returns [StrategicPlanningReport] with strategic recommendations
  static Future<StrategicPlanningReport> generateStrategicInsights() async {
    try {
      final response = await AIServiceBase.invokeAIFunction(
        'perplexity-strategic-planning',
        {
          'analysis_type': 'comprehensive',
          'include_competitive_analysis': true,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      AIServiceBase.validateResponse(response, [
        'report_id',
        'strategic_recommendations',
        'competitive_analysis',
      ]);

      return StrategicPlanningReport.fromJson(response);
    } catch (e) {
      throw AIServiceException(
        'Failed to generate strategic insights: ${e.toString()}',
        e,
      );
    }
  }

  /// Get real-time market trends
  ///
  /// Retrieves current market trends using web search
  /// [industry] - Industry to analyze
  ///
  /// Returns Map with trend data
  static Future<Map<String, dynamic>> getMarketTrends({
    required String industry,
  }) async {
    try {
      final response =
          await AIServiceBase.invokeAIFunction('perplexity-market-trends', {
            'industry': industry,
            'include_web_search': true,
            'timestamp': DateTime.now().toIso8601String(),
          });

      return response;
    } catch (e) {
      throw AIServiceException(
        'Failed to get market trends: ${e.toString()}',
        e,
      );
    }
  }

  /// Competitive intelligence analysis
  ///
  /// Analyzes competitors using web search and public data
  /// [competitors] - List of competitor names or domains
  ///
  /// Returns Map with competitive intelligence
  static Future<Map<String, dynamic>> analyzeCompetitors({
    required List<String> competitors,
  }) async {
    try {
      final response = await AIServiceBase.invokeAIFunction(
        'perplexity-competitive-analysis',
        {
          'competitors': competitors,
          'include_web_search': true,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      return response;
    } catch (e) {
      throw AIServiceException(
        'Failed to analyze competitors: ${e.toString()}',
        e,
      );
    }
  }

  /// Stream real-time threat updates
  ///
  /// Monitors threat intelligence updates in real-time
  /// Returns Stream of [ThreatIntelligenceReport]
  static Stream<ThreatIntelligenceReport> getThreatUpdates() {
    try {
      return supabase
          .from('threat_intelligence_reports')
          .stream(primaryKey: ['id'])
          .map((data) {
            if (data.isEmpty) {
              throw AIServiceException('No threat data available');
            }
            return ThreatIntelligenceReport.fromJson(data.first);
          })
          .handleError((error) {
            throw AIServiceException(
              'Threat stream error: ${error.toString()}',
              error,
            );
          });
    } catch (e) {
      throw AIServiceException(
        'Failed to create threat stream: ${e.toString()}',
        e,
      );
    }
  }

  /// Get historical market research
  ///
  /// Retrieves past market research reports
  /// [limit] - Maximum number of reports to return
  ///
  /// Returns List of historical [MarketResearchResult]
  static Future<List<MarketResearchResult>> getHistoricalResearch({
    int limit = 50,
  }) async {
    try {
      final response = await supabase
          .from('market_research_reports')
          .select()
          .order('created_at', ascending: false)
          .limit(limit);

      return (response as List<dynamic>)
          .map((e) => MarketResearchResult.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw AIServiceException(
        'Failed to fetch historical research: ${e.toString()}',
        e,
      );
    }
  }

  /// Check market intelligence service health
  ///
  /// Verifies that Perplexity services are operational
  /// Returns true if service is healthy
  static Future<bool> isMarketIntelligenceHealthy() async {
    try {
      final response = await AIServiceBase.invokeAIFunction('health-check', {
        'service': 'perplexity-market-intelligence',
      });

      return response['status'] == 'healthy';
    } catch (e) {
      return false;
    }
  }
}
