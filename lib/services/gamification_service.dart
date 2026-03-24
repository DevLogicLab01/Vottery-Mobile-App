import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import './ai_feature_adoption_analytics_service.dart';
import './auth_service.dart';
import './supabase_service.dart';
import './vp_service.dart';

class GamificationService {
  static GamificationService? _instance;
  static GamificationService get instance =>
      _instance ??= GamificationService._();

  GamificationService._();

  SupabaseClient get _client => SupabaseService.instance.client;
  AuthService get _auth => AuthService.instance;
  VPService get _vpService => VPService.instance;

  static const int maxLevel = 100;

  /// Level thresholds for UI (VP widget, hub progression). Matches `_calculateLevelFromXP` math.
  static final List<Map<String, dynamic>> levelTiers = List<Map<String, dynamic>>.unmodifiable(
    List.generate(
      maxLevel,
      (i) {
        final level = i + 1;
        final xpRequired = (level - 1) * 100;
        final mult = _vpMultiplierForLevel(level);
        return {
          'tier': level,
          'level': level,
          'name': titleForLevel(level),
          'xpRequired': xpRequired,
          'xp_required': xpRequired,
          'vpMultiplier': mult,
        };
      },
    ),
  );

  static double _vpMultiplierForLevel(int level) {
    if (level >= maxLevel) return 5.0;
    final growth = 1.0 + (level / maxLevel) * 4.0;
    return double.parse(growth.toStringAsFixed(2));
  }

  /// Public titles for level badges (same as `_titleForLevel`).
  static String titleForLevel(int level) {
    if (level >= 90) return 'Legendary Master';
    if (level >= 75) return 'Elite Champion';
    if (level >= 60) return 'Diamond Leader';
    if (level >= 45) return 'Platinum Strategist';
    if (level >= 30) return 'Gold Advocate';
    if (level >= 15) return 'Silver Contributor';
    if (level >= 5) return 'Bronze Voter';
    return 'Novice';
  }

  /// Get user's current level
  Future<Map<String, dynamic>?> getUserLevel() async {
    try {
      if (!_auth.isAuthenticated) return null;

      final response = await _client
          .from('user_levels')
          .select()
          .eq('user_id', _auth.currentUser!.id)
          .maybeSingle();

      return response;
    } catch (e) {
      debugPrint('Get user level error: $e');
      return null;
    }
  }

  /// Initialize user level
  Future<bool> initializeUserLevel() async {
    try {
      if (!_auth.isAuthenticated) return false;

      await _client.from('user_levels').insert({
        'user_id': _auth.currentUser!.id,
        'current_level': 1,
        'current_xp': 0,
        'total_xp': 0,
        'level_title': 'Novice',
        'vp_multiplier': 1.00,
      });

      return true;
    } catch (e) {
      debugPrint('Initialize user level error: $e');
      return false;
    }
  }

  /// Add XP and check for level up
  Future<Map<String, dynamic>> addXP(int xpAmount, String source) async {
    try {
      if (!_auth.isAuthenticated) {
        return {'success': false, 'level_up': false};
      }

      var userLevel = await getUserLevel();
      if (userLevel == null) {
        await initializeUserLevel();
        userLevel = await getUserLevel();
        if (userLevel == null) return {'success': false, 'level_up': false};
      }

      final currentXP = userLevel['total_xp'] as int;
      final currentLevel = userLevel['current_level'] as int;
      final newTotalXP = currentXP + xpAmount;

      // Calculate new level
      final levelInfo = _calculateLevelFromXP(newTotalXP);
      final newLevel = levelInfo['level'] as int;
      final levelUp = newLevel > currentLevel;

      // Update user level
      await _client
          .from('user_levels')
          .update({
            'current_xp': newTotalXP - (levelInfo['xp_required'] as int),
            'total_xp': newTotalXP,
            'current_level': newLevel,
            'level_title': levelInfo['title'],
            'vp_multiplier': levelInfo['vp_multiplier'],
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('user_id', _auth.currentUser!.id);

      // Update VP multiplier
      await _client
          .from('vp_balance')
          .update({'vp_multiplier': levelInfo['vp_multiplier']})
          .eq('user_id', _auth.currentUser!.id);

      // Check for level achievement
      if (levelUp) {
        await _checkLevelAchievements(newLevel);
      }

      return {
        'success': true,
        'level_up': levelUp,
        'new_level': newLevel,
        'level_title': levelInfo['title'],
        'xp_gained': xpAmount,
        'total_xp': newTotalXP,
      };
    } catch (e) {
      debugPrint('Add XP error: $e');
      return {'success': false, 'level_up': false};
    }
  }

  /// Get all achievements
  Future<List<Map<String, dynamic>>> getAllAchievements() async {
    try {
      final response = await _client
          .from('achievements')
          .select()
          .eq('is_active', true)
          .order('display_order', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get achievements error: $e');
      return [];
    }
  }

  /// Get user's unlocked achievements
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

  /// Unlock achievement
  Future<bool> unlockAchievement(String achievementKey) async {
    try {
      if (!_auth.isAuthenticated) return false;

      // Get achievement details
      final achievement = await _client
          .from('achievements')
          .select()
          .eq('achievement_key', achievementKey)
          .maybeSingle();

      if (achievement == null) return false;

      // Check if already unlocked
      final existing = await _client
          .from('user_achievements')
          .select()
          .eq('user_id', _auth.currentUser!.id)
          .eq('achievement_id', achievement['id'])
          .maybeSingle();

      if (existing != null && existing['is_completed'] == true) {
        return false; // Already unlocked
      }

      // Unlock achievement
      await _client.from('user_achievements').upsert({
        'user_id': _auth.currentUser!.id,
        'achievement_id': achievement['id'],
        'is_completed': true,
        'progress_value': achievement['requirement_value'],
        'unlocked_at': DateTime.now().toIso8601String(),
      });

      // Award VP and XP
      final vpReward = achievement['vp_reward'] as int;
      final xpReward = achievement['xp_reward'] as int;

      if (vpReward > 0) {
        await _vpService.awardAchievementVP(vpReward, achievement['id']);
        // Fire GA4 vp_earned event
        await AIFeatureAdoptionAnalyticsService.instance.logVPEarned(
          amount: vpReward.toDouble(),
          source: 'achievement',
          userId: _auth.currentUser!.id,
        );
      }

      if (xpReward > 0) {
        await addXP(xpReward, 'achievement');
      }

      return true;
    } catch (e) {
      debugPrint('Unlock achievement error: $e');
      return false;
    }
  }

  /// Update achievement progress
  Future<bool> updateAchievementProgress(
    String achievementKey,
    int progressValue,
  ) async {
    try {
      if (!_auth.isAuthenticated) return false;

      final achievement = await _client
          .from('achievements')
          .select()
          .eq('achievement_key', achievementKey)
          .maybeSingle();

      if (achievement == null) return false;

      final requirementValue = achievement['requirement_value'] as int;
      final isCompleted = progressValue >= requirementValue;

      await _client.from('user_achievements').upsert({
        'user_id': _auth.currentUser!.id,
        'achievement_id': achievement['id'],
        'progress_value': progressValue,
        'is_completed': isCompleted,
        'unlocked_at': isCompleted ? DateTime.now().toIso8601String() : null,
      });

      if (isCompleted) {
        await unlockAchievement(achievementKey);
      }

      return true;
    } catch (e) {
      debugPrint('Update achievement progress error: $e');
      return false;
    }
  }

  /// Get user's streak
  Future<Map<String, dynamic>?> getUserStreak() async {
    try {
      if (!_auth.isAuthenticated) return null;

      final response = await _client
          .from('user_streaks')
          .select()
          .eq('user_id', _auth.currentUser!.id)
          .maybeSingle();

      return response;
    } catch (e) {
      debugPrint('Get user streak error: $e');
      return null;
    }
  }

  /// Update streak
  Future<Map<String, dynamic>> updateStreak() async {
    try {
      if (!_auth.isAuthenticated) {
        return {'success': false, 'streak': 0};
      }

      var streak = await getUserStreak();
      if (streak == null) {
        await _client.from('user_streaks').insert({
          'user_id': _auth.currentUser!.id,
          'current_streak': 1,
          'longest_streak': 1,
          'last_activity_date': DateTime.now().toIso8601String().split('T')[0],
          'streak_multiplier': 1.00,
        });
        return {'success': true, 'streak': 1, 'bonus_awarded': false};
      }

      final lastActivityDate = DateTime.parse(streak['last_activity_date']);
      final today = DateTime.now();
      final daysDifference = today.difference(lastActivityDate).inDays;

      int newStreak = streak['current_streak'] as int;
      int longestStreak = streak['longest_streak'] as int;
      bool bonusAwarded = false;

      if (daysDifference == 0) {
        // Same day, no change
        return {'success': true, 'streak': newStreak, 'bonus_awarded': false};
      } else if (daysDifference == 1) {
        // Consecutive day
        newStreak += 1;
        if (newStreak > longestStreak) {
          longestStreak = newStreak;
        }

        // Award streak bonuses
        if (newStreak == 7) {
          await unlockAchievement('vote_streak_7');
          await _vpService.awardStreakBonus(7, 50);
          bonusAwarded = true;
        } else if (newStreak == 30) {
          await unlockAchievement('vote_streak_30');
          await _vpService.awardStreakBonus(30, 200);
          bonusAwarded = true;
        } else if (newStreak % 10 == 0) {
          await _vpService.awardStreakBonus(newStreak, newStreak * 5);
          bonusAwarded = true;
        }
      } else {
        // Streak broken
        newStreak = 1;
      }

      final streakMultiplier = _calculateStreakMultiplier(newStreak);

      await _client
          .from('user_streaks')
          .update({
            'current_streak': newStreak,
            'longest_streak': longestStreak,
            'last_activity_date': today.toIso8601String().split('T')[0],
            'streak_multiplier': streakMultiplier,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('user_id', _auth.currentUser!.id);

      await scheduleStreakExpiryReminders();

      return {
        'success': true,
        'streak': newStreak,
        'longest_streak': longestStreak,
        'bonus_awarded': bonusAwarded,
        'multiplier': streakMultiplier,
      };
    } catch (e) {
      debugPrint('Update streak error: $e');
      return {'success': false, 'streak': 0};
    }
  }

  /// Calculate level from XP
  Map<String, dynamic> _calculateLevelFromXP(int totalXP) {
    final boundedLevel = ((totalXP / 100).floor() + 1).clamp(1, maxLevel);
    final level = boundedLevel;
    return {
      'level': level,
      'title': titleForLevel(level),
      'xp_required': (level - 1) * 100,
      'vp_multiplier': _vpMultiplierForLevel(level),
    };
  }

  /// Calculate streak multiplier
  double _calculateStreakMultiplier(int streakDays) {
    if (streakDays >= 30) return 2.00;
    if (streakDays >= 14) return 1.75;
    if (streakDays >= 7) return 1.50;
    if (streakDays >= 3) return 1.25;
    return 1.00;
  }

  Future<void> scheduleStreakExpiryReminders() async {
    try {
      if (!_auth.isAuthenticated) return;
      final streak = await getUserStreak();
      if (streak == null) return;
      final lastActivityRaw = streak['last_activity_date']?.toString();
      final parsedLastActivity = DateTime.tryParse(lastActivityRaw ?? '');
      if (parsedLastActivity == null) return;

      // Some rows store date-only values (midnight). Normalize to "now" for same-day
      // activity to avoid scheduling reminders in the past.
      final now = DateTime.now();
      final normalizedLastActivity = (parsedLastActivity.year == now.year &&
              parsedLastActivity.month == now.month &&
              parsedLastActivity.day == now.day)
          ? now
          : parsedLastActivity;

      final expiryAt = normalizedLastActivity.add(const Duration(days: 1));
      final reminder24h = expiryAt.subtract(const Duration(hours: 24));
      final reminder1h = expiryAt.subtract(const Duration(hours: 1));

      if (reminder1h.isBefore(now)) return;

      await _client.from('user_streak_reminders').upsert([
        {
          'user_id': _auth.currentUser!.id,
          'reminder_type': 'streak_expiry_24h',
          'scheduled_for': (reminder24h.isBefore(now) ? now : reminder24h)
              .toIso8601String(),
          'status': 'scheduled',
        },
        {
          'user_id': _auth.currentUser!.id,
          'reminder_type': 'streak_expiry_1h',
          'scheduled_for': reminder1h.toIso8601String(),
          'status': 'scheduled',
        },
      ]);

      // Best-effort nudge so due reminders can be dispatched without waiting for
      // external cron in environments where scheduler is not active.
      try {
        await _client.functions.invoke('streak-expiration-alerts');
      } catch (_) {
        // Ignore: server cron may handle dispatch in production.
      }
    } catch (e) {
      debugPrint('Schedule streak reminders error: $e');
    }
  }

  /// Check and unlock level achievements
  Future<void> _checkLevelAchievements(int level) async {
    if (level >= 5) {
      await unlockAchievement('level_5');
    }
    if (level >= 10) {
      await unlockAchievement('level_10');
    }
  }

  /// Save prize configuration
  Future<bool> savePrizeConfiguration({
    required String electionId,
    required Map<String, dynamic> config,
  }) async {
    try {
      if (!_auth.isAuthenticated) return false;

      // Insert prize configuration
      final response = await _client
          .from('gamification_prize_config')
          .insert({
            'election_id': electionId,
            'prize_type': config['prize_type'],
            'monetary_config': config['monetary_config'],
            'non_monetary_config': config['non_monetary_config'],
            'revenue_share_config': config['revenue_share_config'],
            'multiple_winners_enabled': config['multiple_winners_enabled'],
            'winner_count': config['winner_count'],
            'sequential_reveal_enabled': config['sequential_reveal_enabled'],
            'reveal_delay_seconds': config['reveal_delay_seconds'],
            'animation_style': config['animation_style'],
          })
          .select()
          .single();

      final configId = response['config_id'];

      // Insert winner slots if multiple winners
      if (config['multiple_winners_enabled'] == true &&
          config['winner_slots'] != null) {
        final slots = config['winner_slots'] as List<Map<String, dynamic>>;
        for (var slot in slots) {
          await _client.from('prize_winner_slots').insert({
            'config_id': configId,
            'winner_rank': slot['rank'],
            'prize_percentage': slot['percentage'],
          });
        }
      }

      return true;
    } catch (e) {
      debugPrint('Save prize configuration error: $e');
      return false;
    }
  }

  /// Get prize configuration for election
  Future<Map<String, dynamic>?> getPrizeConfiguration({
    required String electionId,
  }) async {
    try {
      final response = await _client
          .from('gamification_prize_config')
          .select('*, prize_winner_slots(*)')
          .eq('election_id', electionId)
          .maybeSingle();

      return response;
    } catch (e) {
      debugPrint('Get prize configuration error: $e');
      return null;
    }
  }

  /// Complete a quest and award VP
  Future<Map<String, dynamic>> completeQuest({
    required String questId,
    required String userId,
  }) async {
    try {
      if (!_auth.isAuthenticated) return {'success': false};

      // Get quest details
      final quest = await _client
          .from('user_quests')
          .select('*, quest_definitions(*)')
          .eq('id', questId)
          .eq('user_id', userId)
          .maybeSingle();

      if (quest == null) return {'success': false, 'error': 'Quest not found'};
      if (quest['is_completed'] == true) {
        return {'success': false, 'error': 'Already completed'};
      }

      final startedAt =
          DateTime.tryParse(quest['started_at'] ?? '') ?? DateTime.now();
      final completionTimeSeconds = DateTime.now()
          .difference(startedAt)
          .inSeconds;
      final questDef =
          quest['quest_definitions'] as Map<String, dynamic>? ?? {};
      final rewardAmount = (questDef['vp_reward'] ?? quest['vp_reward'] ?? 50)
          .toDouble();
      final questType =
          questDef['quest_type'] ?? quest['quest_type'] ?? 'daily';

      // Mark quest as completed
      await _client
          .from('user_quests')
          .update({
            'is_completed': true,
            'completed_at': DateTime.now().toIso8601String(),
          })
          .eq('id', questId);

      // Award VP
      await _vpService.awardChallengeVP(rewardAmount.toInt(), questId);

      // Get user tier
      final userLevel = await getUserLevel();
      final userTier = userLevel?['level_title'] ?? 'Novice';

      // Fire GA4 quest_completed event
      await AIFeatureAdoptionAnalyticsService.instance.logQuestCompleted(
        questId: questId,
        questType: questType,
        rewardAmount: rewardAmount,
        completionTimeSeconds: completionTimeSeconds,
        userTier: userTier,
      );

      // Fire GA4 vp_earned event
      await AIFeatureAdoptionAnalyticsService.instance.logVPEarned(
        amount: rewardAmount,
        source: 'quest',
        userId: userId,
      );

      return {
        'success': true,
        'vp_awarded': rewardAmount,
        'completion_time_seconds': completionTimeSeconds,
      };
    } catch (e) {
      debugPrint('Complete quest error: \$e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Award VP from voting and fire GA4 event
  Future<bool> awardVotingVP({
    required String userId,
    required double amount,
    String source = 'vote',
  }) async {
    try {
      await _vpService.awardVotingVP(userId);

      // Fire GA4 vp_earned event
      await AIFeatureAdoptionAnalyticsService.instance.logVPEarned(
        amount: amount,
        source: source,
        userId: userId,
      );

      return true;
    } catch (e) {
      debugPrint('Award voting VP error: \$e');
      return false;
    }
  }
}