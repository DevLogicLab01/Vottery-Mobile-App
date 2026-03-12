import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import './auth_service.dart';
import './supabase_service.dart';

class LeaderboardService {
  static LeaderboardService? _instance;
  static LeaderboardService get instance =>
      _instance ??= LeaderboardService._();

  LeaderboardService._();

  SupabaseClient get _client => SupabaseService.instance.client;
  AuthService get _auth => AuthService.instance;

  /// Get global leaderboard
  Future<List<Map<String, dynamic>>> getGlobalLeaderboard({
    required String leaderboardType,
    String timePeriod = 'all_time',
    int limit = 50,
  }) async {
    try {
      final response = await _client
          .from('leaderboards')
          .select('*, user:user_profiles!user_id(*)')
          .eq('leaderboard_type', leaderboardType)
          .eq('scope', 'global')
          .eq('time_period', timePeriod)
          .order('rank_position', ascending: true)
          .limit(limit);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get global leaderboard error: $e');
      return [];
    }
  }

  /// Get regional leaderboard
  Future<List<Map<String, dynamic>>> getRegionalLeaderboard({
    required String leaderboardType,
    required String region,
    String timePeriod = 'all_time',
    int limit = 50,
  }) async {
    try {
      final response = await _client
          .from('leaderboards')
          .select('*, user:user_profiles!user_id(*)')
          .eq('leaderboard_type', leaderboardType)
          .eq('scope', region)
          .eq('time_period', timePeriod)
          .order('rank_position', ascending: true)
          .limit(limit);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get regional leaderboard error: $e');
      return [];
    }
  }

  /// Get friends leaderboard
  Future<List<Map<String, dynamic>>> getFriendsLeaderboard({
    required String leaderboardType,
    String timePeriod = 'all_time',
  }) async {
    try {
      if (!_auth.isAuthenticated) return [];

      // Get friend IDs
      final connections = await _client
          .from('user_connections')
          .select('requester_id, addressee_id')
          .eq('status', 'accepted')
          .or(
            'requester_id.eq.${_auth.currentUser!.id},addressee_id.eq.${_auth.currentUser!.id}',
          );

      final friendIds = <String>{};
      for (var conn in connections) {
        if (conn['requester_id'] == _auth.currentUser!.id) {
          friendIds.add(conn['addressee_id'] as String);
        } else {
          friendIds.add(conn['requester_id'] as String);
        }
      }
      friendIds.add(_auth.currentUser!.id);

      // Get leaderboard for friends
      final response = await _client
          .from('leaderboards')
          .select('*, user:user_profiles!user_id(*)')
          .eq('leaderboard_type', leaderboardType)
          .eq('time_period', timePeriod)
          .inFilter('user_id', friendIds.toList())
          .order('score', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get friends leaderboard error: $e');
      return [];
    }
  }

  /// Get user rank
  Future<Map<String, dynamic>?> getUserRank({
    required String leaderboardType,
    String scope = 'global',
    String timePeriod = 'all_time',
  }) async {
    try {
      if (!_auth.isAuthenticated) return null;

      final response = await _client
          .from('leaderboards')
          .select()
          .eq('leaderboard_type', leaderboardType)
          .eq('scope', scope)
          .eq('time_period', timePeriod)
          .eq('user_id', _auth.currentUser!.id)
          .maybeSingle();

      return response;
    } catch (e) {
      debugPrint('Get user rank error: $e');
      return null;
    }
  }

  /// Update leaderboard entry
  Future<bool> updateLeaderboardEntry({
    required String leaderboardType,
    required String scope,
    required String timePeriod,
    required int score,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      if (!_auth.isAuthenticated) return false;

      await _client.from('leaderboards').upsert({
        'leaderboard_type': leaderboardType,
        'scope': scope,
        'time_period': timePeriod,
        'user_id': _auth.currentUser!.id,
        'score': score,
        'metadata': metadata ?? {},
        'updated_at': DateTime.now().toIso8601String(),
      });

      return true;
    } catch (e) {
      debugPrint('Update leaderboard entry error: $e');
      return false;
    }
  }

  /// Get available leaderboard types
  List<Map<String, dynamic>> getLeaderboardTypes() {
    return [
      {
        'type': 'vp_earned',
        'title': 'VP Earned',
        'description': 'Total Vottery Points earned',
        'icon': 'stars',
      },
      {
        'type': 'votes_cast',
        'title': 'Votes Cast',
        'description': 'Total number of votes',
        'icon': 'how_to_vote',
      },
      {
        'type': 'prediction_accuracy',
        'title': 'Prediction Accuracy',
        'description': 'Best Brier scores',
        'icon': 'psychology',
      },
      {
        'type': 'social_engagement',
        'title': 'Social Engagement',
        'description': 'Comments, shares, interactions',
        'icon': 'groups',
      },
      {
        'type': 'streak_days',
        'title': 'Longest Streak',
        'description': 'Consecutive activity days',
        'icon': 'local_fire_department',
      },
    ];
  }
}
