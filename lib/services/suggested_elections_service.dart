import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import './supabase_service.dart';
import './auth_service.dart';
import './topic_preference_service.dart';
import './feed_ranking_service.dart';

class SuggestedElectionsService {
  static SuggestedElectionsService? _instance;
  static SuggestedElectionsService get instance =>
      _instance ??= SuggestedElectionsService._();

  SuggestedElectionsService._();

  SupabaseClient get _client => SupabaseService.instance.client;
  AuthService get _auth => AuthService.instance;
  TopicPreferenceService get _topicPrefs => TopicPreferenceService.instance;
  FeedRankingService get _feedRanking => FeedRankingService.instance;

  /// Get trending elections with velocity calculation
  Future<List<Map<String, dynamic>>> getTrendingElections({
    int limit = 20,
  }) async {
    try {
      if (!_auth.isAuthenticated) return [];

      final response = await _client.rpc(
        'get_trending_elections',
        params: {'user_id_param': _auth.currentUser!.id, 'limit_count': limit},
      );

      return List<Map<String, dynamic>>.from(response ?? []);
    } catch (e) {
      debugPrint('Get trending elections error: $e');
      return [];
    }
  }

  /// Get personalized election recommendations
  Future<List<Map<String, dynamic>>> getPersonalizedRecommendations({
    int limit = 20,
  }) async {
    try {
      if (!_auth.isAuthenticated) return [];

      final response = await _client.rpc(
        'get_personalized_election_recommendations',
        params: {'user_id_param': _auth.currentUser!.id, 'limit_count': limit},
      );

      return List<Map<String, dynamic>>.from(response ?? []);
    } catch (e) {
      debugPrint('Get personalized recommendations error: $e');
      return [];
    }
  }

  /// Get combined suggested elections (trending + personalized)
  Future<List<Map<String, dynamic>>> getSuggestedElections({
    int limit = 20,
  }) async {
    try {
      final results = await Future.wait([
        getTrendingElections(limit: limit ~/ 2),
        getPersonalizedRecommendations(limit: limit ~/ 2),
      ]);

      final trending = results[0];
      final personalized = results[1];

      // Combine and deduplicate
      final combined = <String, Map<String, dynamic>>{};

      for (var election in trending) {
        combined[election['election_id']] = {
          ...election,
          'recommendation_type': 'trending',
        };
      }

      for (var election in personalized) {
        if (!combined.containsKey(election['election_id'])) {
          combined[election['election_id']] = {
            ...election,
            'recommendation_type': 'personalized',
          };
        }
      }

      return combined.values.toList().take(limit).toList();
    } catch (e) {
      debugPrint('Get suggested elections error: $e');
      return [];
    }
  }

  /// Track election shown to user
  Future<void> trackElectionShown({
    required String electionId,
    required String recommendationReason,
    required double recommendationScore,
    String? trendingBadge,
  }) async {
    try {
      if (!_auth.isAuthenticated) return;

      await _client.from('suggested_elections_tracking').insert({
        'user_id': _auth.currentUser!.id,
        'election_id': electionId,
        'recommendation_reason': recommendationReason,
        'recommendation_score': recommendationScore,
        'trending_badge': trendingBadge,
        'shown_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Track election shown error: $e');
    }
  }

  /// Track election clicked
  Future<void> trackElectionClicked(String electionId) async {
    try {
      if (!_auth.isAuthenticated) return;

      await _client
          .from('suggested_elections_tracking')
          .update({'clicked_at': DateTime.now().toIso8601String()})
          .eq('user_id', _auth.currentUser!.id)
          .eq('election_id', electionId)
          .isFilter('clicked_at', null);

      // Update collaborative filtering matrix
      await _feedRanking.trackEngagement(
        contentId: electionId,
        contentType: 'election',
        signalType: 'vote_participation',
      );
    } catch (e) {
      debugPrint('Track election clicked error: $e');
    }
  }

  /// Dismiss election with feedback
  Future<void> dismissElection({
    required String electionId,
    required String dismissReason,
  }) async {
    try {
      if (!_auth.isAuthenticated) return;

      // Insert dismissal
      await _client.from('election_dismissals').insert({
        'user_id': _auth.currentUser!.id,
        'election_id': electionId,
        'dismiss_reason': dismissReason,
      });

      // Update tracking
      await _client
          .from('suggested_elections_tracking')
          .update({
            'dismissed_at': DateTime.now().toIso8601String(),
            'dismiss_reason': dismissReason,
          })
          .eq('user_id', _auth.currentUser!.id)
          .eq('election_id', electionId)
          .isFilter('dismissed_at', null);

      // Update collaborative filtering (negative signal)
      await _feedRanking.trackEngagement(
        contentId: electionId,
        contentType: 'election',
        signalType: 'view',
      );
    } catch (e) {
      debugPrint('Dismiss election error: $e');
    }
  }

  /// Track election voted
  Future<void> trackElectionVoted(String electionId) async {
    try {
      if (!_auth.isAuthenticated) return;

      await _client
          .from('suggested_elections_tracking')
          .update({'voted_at': DateTime.now().toIso8601String()})
          .eq('user_id', _auth.currentUser!.id)
          .eq('election_id', electionId)
          .isFilter('voted_at', null);

      // Update collaborative filtering (strong positive signal)
      await _feedRanking.trackEngagement(
        contentId: electionId,
        contentType: 'election',
        signalType: 'vote_participation',
      );
    } catch (e) {
      debugPrint('Track election voted error: $e');
    }
  }

  /// Get recommendation performance metrics
  Future<Map<String, dynamic>> getRecommendationMetrics() async {
    try {
      if (!_auth.isAuthenticated) return {};

      final response = await _client
          .from('suggested_elections_tracking')
          .select()
          .eq('user_id', _auth.currentUser!.id)
          .gte(
            'shown_at',
            DateTime.now().subtract(Duration(days: 30)).toIso8601String(),
          );

      final tracking = List<Map<String, dynamic>>.from(response);

      final totalShown = tracking.length;
      final totalClicked = tracking
          .where((t) => t['clicked_at'] != null)
          .length;
      final totalVoted = tracking.where((t) => t['voted_at'] != null).length;
      final totalDismissed = tracking
          .where((t) => t['dismissed_at'] != null)
          .length;

      return {
        'total_shown': totalShown,
        'total_clicked': totalClicked,
        'total_voted': totalVoted,
        'total_dismissed': totalDismissed,
        'click_through_rate': totalShown > 0 ? totalClicked / totalShown : 0.0,
        'conversion_rate': totalShown > 0 ? totalVoted / totalShown : 0.0,
        'dismissal_rate': totalShown > 0 ? totalDismissed / totalShown : 0.0,
      };
    } catch (e) {
      debugPrint('Get recommendation metrics error: $e');
      return {};
    }
  }

  /// Get trending badge for election
  String? getTrendingBadge(Map<String, dynamic> election) {
    final voteVelocity = election['vote_velocity'] as double? ?? 0.0;
    final engagementRate = election['engagement_rate'] as double? ?? 0.0;
    final recencyScore = election['recency_score'] as double? ?? 0.0;

    if (voteVelocity > 10) return 'hot';
    if (recencyScore > 0.8) return 'new';
    if (engagementRate > 0.5) return 'rising';
    return null;
  }

  /// Get badge emoji
  String getBadgeEmoji(String? badge) {
    switch (badge) {
      case 'hot':
        return '🔥';
      case 'rising':
        return '⭐';
      case 'new':
        return '💎';
      default:
        return '';
    }
  }

  /// Get badge color
  String getBadgeColor(String? badge) {
    switch (badge) {
      case 'hot':
        return '#FF4500';
      case 'rising':
        return '#FFD700';
      case 'new':
        return '#00CED1';
      default:
        return '#808080';
    }
  }
}
