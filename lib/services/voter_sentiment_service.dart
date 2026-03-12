import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import './supabase_service.dart';
import './auth_service.dart';

class VoterSentimentService {
  static VoterSentimentService? _instance;
  static VoterSentimentService get instance =>
      _instance ??= VoterSentimentService._();

  VoterSentimentService._();

  static const String anthropicApiKey = String.fromEnvironment(
    'ANTHROPIC_API_KEY',
  );
  static const String apiUrl = 'https://api.anthropic.com/v1/messages';
  static const String model = 'claude-sonnet-4-20250514';

  AuthService get _auth => AuthService.instance;
  dynamic get _client => SupabaseService.instance.client;

  /// Analyze voter sentiment for election
  Future<Map<String, dynamic>> analyzeElectionSentiment({
    required String electionId,
  }) async {
    try {
      if (anthropicApiKey.isEmpty ||
          anthropicApiKey == 'your-anthropic-api-key-here') {
        return _getDefaultSentimentAnalysis();
      }

      // Fetch election comments and reactions
      final comments = await _fetchElectionComments(electionId);
      final reactions = await _fetchElectionReactions(electionId);

      final prompt = _buildSentimentPrompt(comments, reactions);
      final response = await _callClaudeAPI(prompt);
      final analysis = _parseSentimentResponse(response);

      await _logSentimentAnalysis(electionId, analysis);
      return analysis;
    } catch (e) {
      debugPrint('Analyze election sentiment error: $e');
      return _getDefaultSentimentAnalysis();
    }
  }

  /// Analyze campaign reaction insights
  Future<Map<String, dynamic>> analyzeCampaignReactions({
    required String campaignId,
  }) async {
    try {
      if (anthropicApiKey.isEmpty ||
          anthropicApiKey == 'your-anthropic-api-key-here') {
        return _getDefaultCampaignReactions();
      }

      final campaignData = await _fetchCampaignData(campaignId);
      final prompt = _buildCampaignReactionPrompt(campaignData);
      final response = await _callClaudeAPI(prompt);
      final analysis = _parseCampaignReactionResponse(response);

      await _logCampaignReactionAnalysis(campaignId, analysis);
      return analysis;
    } catch (e) {
      debugPrint('Analyze campaign reactions error: $e');
      return _getDefaultCampaignReactions();
    }
  }

  /// Predict engagement trends
  Future<Map<String, dynamic>> predictEngagementTrends({
    required String contentId,
    required String contentType,
  }) async {
    try {
      if (anthropicApiKey.isEmpty ||
          anthropicApiKey == 'your-anthropic-api-key-here') {
        return _getDefaultEngagementPrediction();
      }

      final historicalData = await _fetchHistoricalEngagement(
        contentId,
        contentType,
      );
      final prompt = _buildEngagementPredictionPrompt(historicalData);
      final response = await _callClaudeAPI(prompt);
      final prediction = _parseEngagementPredictionResponse(response);

      await _logEngagementPrediction(contentId, contentType, prediction);
      return prediction;
    } catch (e) {
      debugPrint('Predict engagement trends error: $e');
      return _getDefaultEngagementPrediction();
    }
  }

  /// Get sentiment trends over time
  Future<List<Map<String, dynamic>>> getSentimentTrends({
    required String electionId,
    int days = 30,
  }) async {
    try {
      final response = await _client
          .from('voter_sentiment_analysis')
          .select()
          .eq('election_id', electionId)
          .gte(
            'analyzed_at',
            DateTime.now().subtract(Duration(days: days)).toIso8601String(),
          )
          .order('analyzed_at', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get sentiment trends error: $e');
      return [];
    }
  }

  /// Get top positive and negative themes
  Future<Map<String, dynamic>> getSentimentThemes({
    required String electionId,
  }) async {
    try {
      final analysis = await analyzeElectionSentiment(electionId: electionId);
      return {
        'positive_themes': analysis['positive_themes'] ?? [],
        'negative_themes': analysis['negative_themes'] ?? [],
        'neutral_themes': analysis['neutral_themes'] ?? [],
      };
    } catch (e) {
      debugPrint('Get sentiment themes error: $e');
      return {
        'positive_themes': [],
        'negative_themes': [],
        'neutral_themes': [],
      };
    }
  }

  /// Fetch election comments
  Future<List<Map<String, dynamic>>> _fetchElectionComments(
    String electionId,
  ) async {
    try {
      final response = await _client
          .from('election_comments')
          .select('comment_text, created_at')
          .eq('election_id', electionId)
          .order('created_at', ascending: false)
          .limit(100);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Fetch election comments error: $e');
      return [];
    }
  }

  /// Fetch election reactions
  Future<Map<String, int>> _fetchElectionReactions(String electionId) async {
    try {
      final response = await _client
          .from('election_reactions')
          .select('reaction_type')
          .eq('election_id', electionId);

      final reactions = <String, int>{};
      for (final record in response) {
        final type = record['reaction_type'] as String;
        reactions[type] = (reactions[type] ?? 0) + 1;
      }

      return reactions;
    } catch (e) {
      debugPrint('Fetch election reactions error: $e');
      return {};
    }
  }

  /// Fetch campaign data
  Future<Map<String, dynamic>> _fetchCampaignData(String campaignId) async {
    try {
      final response = await _client
          .from('participatory_ads_campaigns')
          .select('*, participatory_ads_analytics(*)')
          .eq('id', campaignId)
          .single();

      return response;
    } catch (e) {
      debugPrint('Fetch campaign data error: $e');
      return {};
    }
  }

  /// Fetch historical engagement data
  Future<List<Map<String, dynamic>>> _fetchHistoricalEngagement(
    String contentId,
    String contentType,
  ) async {
    try {
      final response = await _client.rpc(
        'get_historical_engagement',
        params: {
          'p_content_id': contentId,
          'p_content_type': contentType,
          'p_days': 30,
        },
      );

      return List<Map<String, dynamic>>.from(response ?? []);
    } catch (e) {
      debugPrint('Fetch historical engagement error: $e');
      return [];
    }
  }

  /// Call Claude API
  Future<String> _callClaudeAPI(String prompt) async {
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': anthropicApiKey,
          'anthropic-version': '2023-06-01',
        },
        body: jsonEncode({
          'model': model,
          'max_tokens': 2048,
          'messages': [
            {'role': 'user', 'content': prompt},
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['content'][0]['text'] as String;
      } else {
        debugPrint('Claude API error: ${response.statusCode} ${response.body}');
        return '';
      }
    } catch (e) {
      debugPrint('Claude API call error: $e');
      return '';
    }
  }

  /// Build sentiment analysis prompt
  String _buildSentimentPrompt(
    List<Map<String, dynamic>> comments,
    Map<String, int> reactions,
  ) {
    return '''
Analyze voter sentiment for this election based on comments and reactions:

Comments:
${jsonEncode(comments)}

Reactions:
${jsonEncode(reactions)}

Provide analysis in JSON format:
{
  "overall_sentiment": "positive|neutral|negative",
  "sentiment_score": 0-100,
  "positive_percentage": 0-100,
  "neutral_percentage": 0-100,
  "negative_percentage": 0-100,
  "positive_themes": ["theme1", "theme2"],
  "negative_themes": ["theme1", "theme2"],
  "neutral_themes": ["theme1", "theme2"],
  "key_insights": ["insight1", "insight2"],
  "engagement_quality": "high|medium|low",
  "controversy_level": 0-100,
  "confidence": 0-1
}
''';
  }

  /// Build campaign reaction prompt
  String _buildCampaignReactionPrompt(Map<String, dynamic> campaignData) {
    return '''
Analyze campaign reactions and audience sentiment:

Campaign Data:
${jsonEncode(campaignData)}

Provide analysis in JSON format:
{
  "audience_sentiment": "positive|neutral|negative",
  "engagement_quality": "high|medium|low",
  "brand_perception": "positive|neutral|negative",
  "viral_potential": 0-100,
  "controversy_risk": 0-100,
  "key_reactions": [{"type": "...", "count": 0, "sentiment": "..."}],
  "improvement_suggestions": ["suggestion1", "suggestion2"],
  "target_audience_alignment": 0-100,
  "confidence": 0-1
}
''';
  }

  /// Build engagement prediction prompt
  String _buildEngagementPredictionPrompt(
    List<Map<String, dynamic>> historicalData,
  ) {
    return '''
Predict engagement trends based on historical data:

Historical Engagement:
${jsonEncode(historicalData)}

Provide prediction in JSON format:
{
  "predicted_engagement_7d": 0,
  "predicted_engagement_14d": 0,
  "predicted_engagement_30d": 0,
  "trend_direction": "increasing|stable|decreasing",
  "growth_rate": 0-100,
  "peak_engagement_time": "...",
  "engagement_factors": [{"factor": "...", "impact": 0-100}],
  "recommendations": ["recommendation1", "recommendation2"],
  "confidence": 0-1
}
''';
  }

  /// Parse sentiment response
  Map<String, dynamic> _parseSentimentResponse(String response) {
    try {
      return jsonDecode(response);
    } catch (e) {
      debugPrint('Parse sentiment response error: $e');
      return _getDefaultSentimentAnalysis();
    }
  }

  /// Parse campaign reaction response
  Map<String, dynamic> _parseCampaignReactionResponse(String response) {
    try {
      return jsonDecode(response);
    } catch (e) {
      debugPrint('Parse campaign reaction response error: $e');
      return _getDefaultCampaignReactions();
    }
  }

  /// Parse engagement prediction response
  Map<String, dynamic> _parseEngagementPredictionResponse(String response) {
    try {
      return jsonDecode(response);
    } catch (e) {
      debugPrint('Parse engagement prediction response error: $e');
      return _getDefaultEngagementPrediction();
    }
  }

  /// Log sentiment analysis
  Future<void> _logSentimentAnalysis(
    String electionId,
    Map<String, dynamic> analysis,
  ) async {
    try {
      await _client.from('voter_sentiment_analysis').insert({
        'election_id': electionId,
        'overall_sentiment': analysis['overall_sentiment'],
        'sentiment_score': analysis['sentiment_score'],
        'positive_percentage': analysis['positive_percentage'],
        'neutral_percentage': analysis['neutral_percentage'],
        'negative_percentage': analysis['negative_percentage'],
        'positive_themes': analysis['positive_themes'],
        'negative_themes': analysis['negative_themes'],
        'key_insights': analysis['key_insights'],
        'engagement_quality': analysis['engagement_quality'],
        'controversy_level': analysis['controversy_level'],
        'confidence': analysis['confidence'],
        'analyzed_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Log sentiment analysis error: $e');
    }
  }

  /// Log campaign reaction analysis
  Future<void> _logCampaignReactionAnalysis(
    String campaignId,
    Map<String, dynamic> analysis,
  ) async {
    try {
      await _client.from('campaign_reaction_analysis').insert({
        'campaign_id': campaignId,
        'audience_sentiment': analysis['audience_sentiment'],
        'engagement_quality': analysis['engagement_quality'],
        'brand_perception': analysis['brand_perception'],
        'viral_potential': analysis['viral_potential'],
        'controversy_risk': analysis['controversy_risk'],
        'improvement_suggestions': analysis['improvement_suggestions'],
        'target_audience_alignment': analysis['target_audience_alignment'],
        'confidence': analysis['confidence'],
        'analyzed_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Log campaign reaction analysis error: $e');
    }
  }

  /// Log engagement prediction
  Future<void> _logEngagementPrediction(
    String contentId,
    String contentType,
    Map<String, dynamic> prediction,
  ) async {
    try {
      await _client.from('engagement_predictions').insert({
        'content_id': contentId,
        'content_type': contentType,
        'predicted_engagement_7d': prediction['predicted_engagement_7d'],
        'predicted_engagement_14d': prediction['predicted_engagement_14d'],
        'predicted_engagement_30d': prediction['predicted_engagement_30d'],
        'trend_direction': prediction['trend_direction'],
        'growth_rate': prediction['growth_rate'],
        'recommendations': prediction['recommendations'],
        'confidence': prediction['confidence'],
        'predicted_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Log engagement prediction error: $e');
    }
  }

  Map<String, dynamic> _getDefaultSentimentAnalysis() {
    return {
      'overall_sentiment': 'neutral',
      'sentiment_score': 50,
      'positive_percentage': 33,
      'neutral_percentage': 34,
      'negative_percentage': 33,
      'positive_themes': [],
      'negative_themes': [],
      'neutral_themes': [],
      'key_insights': ['Sentiment analysis unavailable'],
      'engagement_quality': 'medium',
      'controversy_level': 0,
      'confidence': 0.0,
    };
  }

  Map<String, dynamic> _getDefaultCampaignReactions() {
    return {
      'audience_sentiment': 'neutral',
      'engagement_quality': 'medium',
      'brand_perception': 'neutral',
      'viral_potential': 50,
      'controversy_risk': 0,
      'key_reactions': [],
      'improvement_suggestions': [],
      'target_audience_alignment': 50,
      'confidence': 0.0,
    };
  }

  Map<String, dynamic> _getDefaultEngagementPrediction() {
    return {
      'predicted_engagement_7d': 0,
      'predicted_engagement_14d': 0,
      'predicted_engagement_30d': 0,
      'trend_direction': 'stable',
      'growth_rate': 0,
      'peak_engagement_time': 'Unknown',
      'engagement_factors': [],
      'recommendations': [],
      'confidence': 0.0,
    };
  }
}
