import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../framework/shared_constants.dart';
import './claude_service.dart';
import './perplexity_service.dart';
import './supabase_service.dart';
import './auth_service.dart';

class AIRecommendationsService {
  static AIRecommendationsService? _instance;
  static AIRecommendationsService get instance =>
      _instance ??= AIRecommendationsService._();

  AIRecommendationsService._();

  SupabaseClient get _client => SupabaseService.instance.client;
  AuthService get _auth => AuthService.instance;
  ClaudeService get _claude => ClaudeService.instance;
  PerplexityService get _perplexity => PerplexityService.instance;

  /// Get personalized content recommendations
  Future<List<Map<String, dynamic>>> getContentRecommendations({
    required String screenContext,
    int limit = 10,
  }) async {
    final sw = Stopwatch()..start();
    try {
      if (!_auth.isAuthenticated) return _getDefaultRecommendations();

      final userData = await _getUserPreferences();
      final recommendations = await _claude.getContextualRecommendations(
        screenContext: screenContext,
        userData: userData,
      );

      await _logRecommendations(screenContext, recommendations);
      return recommendations;
    } catch (e) {
      debugPrint('Get content recommendations error: $e');
      return _getDefaultRecommendations();
    } finally {
      final within =
          sw.elapsedMilliseconds <= SharedConstants.recommendationLatencyBudgetMs;
      debugPrint(
        'AIRecommendationsService.getContentRecommendations context=$screenContext latencyMs=${sw.elapsedMilliseconds} budgetMs=${SharedConstants.recommendationLatencyBudgetMs} withinBudget=$within',
      );
    }
  }

  /// Get election recommendations based on user interests
  Future<List<Map<String, dynamic>>> getElectionRecommendations() async {
    try {
      if (!_auth.isAuthenticated) return [];

      final response = await _client.rpc(
        'get_personalized_elections',
        params: {'user_id': _auth.currentUser!.id, 'limit_count': 10},
      );

      return List<Map<String, dynamic>>.from(response ?? []);
    } catch (e) {
      debugPrint('Get election recommendations error: $e');
      return [];
    }
  }

  /// Get trending topics with AI sentiment analysis
  Future<List<Map<String, dynamic>>> getTrendingTopics() async {
    try {
      final topics = await _client
          .from('trending_topics')
          .select()
          .order('trend_score', ascending: false)
          .limit(10);

      final enrichedTopics = <Map<String, dynamic>>[];
      for (var topic in topics) {
        final sentiment = await _perplexity.analyzeMarketSentiment(
          topic: topic['topic_name'] ?? '',
          category: topic['category'],
        );

        enrichedTopics.add({...topic, 'sentiment_analysis': sentiment});
      }

      return enrichedTopics;
    } catch (e) {
      debugPrint('Get trending topics error: $e');
      return [];
    }
  }

  /// Get predictive insights for user engagement
  Future<Map<String, dynamic>> getPredictiveInsights() async {
    try {
      if (!_auth.isAuthenticated) return _getDefaultInsights();

      final response = await _client.rpc(
        'get_predictive_insights',
        params: {'user_id': _auth.currentUser!.id},
      );

      return response ?? _getDefaultInsights();
    } catch (e) {
      debugPrint('Get predictive insights error: $e');
      return _getDefaultInsights();
    }
  }

  /// Get friend recommendations based on voting patterns
  Future<List<Map<String, dynamic>>> getFriendRecommendations() async {
    try {
      if (!_auth.isAuthenticated) return [];

      final response = await _client.rpc(
        'get_friend_recommendations',
        params: {'user_id': _auth.currentUser!.id, 'limit_count': 20},
      );

      return List<Map<String, dynamic>>.from(response ?? []);
    } catch (e) {
      debugPrint('Get friend recommendations error: $e');
      return [];
    }
  }

  /// Get content recommendations for Jolts feed
  Future<List<Map<String, dynamic>>> getJoltsRecommendations() async {
    try {
      if (!_auth.isAuthenticated) return [];

      final response = await _client.rpc(
        'get_jolts_recommendations',
        params: {'user_id': _auth.currentUser!.id, 'limit_count': 15},
      );

      return List<Map<String, dynamic>>.from(response ?? []);
    } catch (e) {
      debugPrint('Get Jolts recommendations error: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> _getUserPreferences() async {
    try {
      final profile = await _client
          .from('user_profiles')
          .select()
          .eq('id', _auth.currentUser!.id)
          .maybeSingle();

      final votingHistory = await _client
          .from('votes')
          .select('election_id, created_at')
          .eq('user_id', _auth.currentUser!.id)
          .order('created_at', ascending: false)
          .limit(50);

      return {
        'profile': profile ?? {},
        'voting_history': votingHistory,
        'preferences': profile?['preferences'] ?? {},
      };
    } catch (e) {
      debugPrint('Get user preferences error: $e');
      return {};
    }
  }

  Future<void> _logRecommendations(
    String context,
    List<Map<String, dynamic>> recommendations,
  ) async {
    try {
      if (!_auth.isAuthenticated) return;

      await _client.from('recommendation_logs').insert({
        'user_id': _auth.currentUser!.id,
        'context': context,
        'recommendation_count': recommendations.length,
        'recommendations': recommendations,
      });
    } catch (e) {
      debugPrint('Log recommendations error: $e');
    }
  }

  List<Map<String, dynamic>> _getDefaultRecommendations() {
    return [
      {
        'id': '1',
        'type': 'election',
        'title': 'Explore Trending Elections',
        'description': 'Discover popular elections in your area',
        'relevance_score': 0.8,
      },
      {
        'id': '2',
        'type': 'prediction',
        'title': 'Join Prediction Pools',
        'description': 'Test your forecasting skills',
        'relevance_score': 0.7,
      },
      {
        'id': '3',
        'type': 'social',
        'title': 'Connect with Friends',
        'description': 'Find people with similar interests',
        'relevance_score': 0.6,
      },
    ];
  }

  Map<String, dynamic> _getDefaultInsights() {
    return {
      'engagement_prediction': 0.75,
      'churn_risk': 0.15,
      'lifetime_value_estimate': 500,
      'recommended_actions': [
        'Participate in prediction pools',
        'Connect with similar voters',
        'Explore trending topics',
      ],
    };
  }
}
