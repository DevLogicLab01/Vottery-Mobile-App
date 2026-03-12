import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import './supabase_service.dart';
import './auth_service.dart';

class AchievementService {
  static AchievementService? _instance;
  static AchievementService get instance =>
      _instance ??= AchievementService._();

  AchievementService._();

  SupabaseClient get _client => SupabaseService.instance.client;
  AuthService get _auth => AuthService.instance;

  /// Get all achievements
  Future<List<Map<String, dynamic>>> getAllAchievements() async {
    try {
      final response = await _client
          .from('achievements')
          .select()
          .order('display_order', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get all achievements error: $e');
      return [];
    }
  }

  /// Get user achievements
  Future<List<Map<String, dynamic>>> getUserAchievements() async {
    try {
      if (!_auth.isAuthenticated) return [];

      final response = await _client
          .from('user_achievements')
          .select('*, achievements(*)')
          .eq('user_id', _auth.currentUser!.id)
          .order('unlocked_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get user achievements error: $e');
      return [];
    }
  }

  /// Check and unlock achievement
  Future<Map<String, dynamic>?> checkAndUnlockAchievement({
    required String achievementType,
    int progressValue = 0,
  }) async {
    try {
      if (!_auth.isAuthenticated) return null;

      // Check if already unlocked
      final existing = await _client
          .from('user_achievements')
          .select('*, achievements(*)')
          .eq('user_id', _auth.currentUser!.id)
          .eq('achievements.achievement_type', achievementType)
          .maybeSingle();

      if (existing != null) return null;

      // Get achievement definition
      final achievement = await _client
          .from('achievements')
          .select()
          .eq('achievement_type', achievementType)
          .maybeSingle();

      if (achievement == null) return null;

      // Check if requirements met
      final requirementMet = await _checkAchievementRequirement(
        achievementType,
        progressValue,
      );

      if (!requirementMet) return null;

      // Unlock achievement
      await _client.from('user_achievements').insert({
        'user_id': _auth.currentUser!.id,
        'achievement_id': achievement['id'],
        'progress_value': progressValue,
      });

      // Award VP
      final vpReward = achievement['vp_reward'] as int? ?? 0;
      if (vpReward > 0) {
        // Comment out or remove the VP awarding logic since VpService is not available
        /*
        await _vpService.addVP(
          amount: vpReward,
          source: 'achievement_unlocked',
          description: 'Achievement: ${achievement['title']}',
        );
        */
      }

      return {
        'achievement': achievement,
        'vp_reward': vpReward,
        'unlocked_at': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      debugPrint('Check and unlock achievement error: $e');
      return null;
    }
  }

  /// Check specific achievement requirements
  Future<bool> _checkAchievementRequirement(
    String achievementType,
    int progressValue,
  ) async {
    try {
      if (!_auth.isAuthenticated) return false;

      switch (achievementType) {
        case 'first_election_created':
          final elections = await _client
              .from('elections')
              .select('id')
              .eq('creator_id', _auth.currentUser!.id)
              .limit(1);
          return elections.isNotEmpty;

        case 'first_1000_votes':
          final votes = await _client
              .from('votes')
              .select('id')
              .eq('user_id', _auth.currentUser!.id);
          return votes.length >= 1000;

        case 'first_payout':
          final payouts = await _client
              .from('settlement_records')
              .select('settlement_id')
              .eq('creator_user_id', _auth.currentUser!.id)
              .eq('status', 'completed')
              .limit(1);
          return payouts.isNotEmpty;

        case '100_elections_created':
          final elections = await _client
              .from('elections')
              .select('id')
              .eq('creator_id', _auth.currentUser!.id);
          return elections.length >= 100;

        case 'top_earner_monthly':
          return progressValue >= 1;

        case 'viral_content':
          final elections = await _client
              .from('elections')
              .select('total_votes')
              .eq('creator_id', _auth.currentUser!.id)
              .gte('total_votes', 10000)
              .limit(1);
          return elections.isNotEmpty;

        default:
          return false;
      }
    } catch (e) {
      debugPrint('Check achievement requirement error: $e');
      return false;
    }
  }

  /// Get achievement progress
  Future<Map<String, dynamic>> getAchievementProgress(
    String achievementType,
  ) async {
    try {
      if (!_auth.isAuthenticated) return {'progress': 0, 'target': 0};

      switch (achievementType) {
        case 'first_election_created':
          final count = await _client
              .from('elections')
              .select('id')
              .eq('creator_id', _auth.currentUser!.id);
          return {'progress': count.length, 'target': 1};

        case 'first_1000_votes':
          final count = await _client
              .from('votes')
              .select('id')
              .eq('user_id', _auth.currentUser!.id);
          return {'progress': count.length, 'target': 1000};

        case '100_elections_created':
          final count = await _client
              .from('elections')
              .select('id')
              .eq('creator_id', _auth.currentUser!.id);
          return {'progress': count.length, 'target': 100};

        case 'viral_content':
          final elections = await _client
              .from('elections')
              .select('total_votes')
              .eq('creator_id', _auth.currentUser!.id)
              .order('total_votes', ascending: false)
              .limit(1);
          final maxVotes = elections.isNotEmpty
              ? (elections.first['total_votes'] as int? ?? 0)
              : 0;
          return {'progress': maxVotes, 'target': 10000};

        default:
          return {'progress': 0, 'target': 0};
      }
    } catch (e) {
      debugPrint('Get achievement progress error: $e');
      return {'progress': 0, 'target': 0};
    }
  }
}
