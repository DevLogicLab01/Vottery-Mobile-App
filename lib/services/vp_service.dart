import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import './auth_service.dart';
import './supabase_service.dart';

class VPService {
  static VPService? _instance;
  static VPService get instance => _instance ??= VPService._();

  VPService._();

  SupabaseClient get _client => SupabaseService.instance.client;
  AuthService get _auth => AuthService.instance;

  // VP Earning Sources
  static const int vpVotingMin = 5;
  static const int vpVotingMax = 50;
  static const int vpDailyLogin = 10;
  static const int vpSocialInteraction = 5;
  static const int vpChallengeMin = 50;
  static const int vpChallengeMax = 500;
  static const int vpPredictionMax = 1000;
  static const int vpReferral = 100;

  // VP Spending Options
  static const int vpAdFree = 500;
  static const int vpCustomTheme = 300;
  static const int vpPredictionEntry = 100;
  static const int vpPremiumContent = 200;
  static const int vpQuestPack = 250;
  static const int vpVipTierUnlock = 1500;

  /// Get user's VP balance
  Future<Map<String, dynamic>?> getVPBalance() async {
    try {
      if (!_auth.isAuthenticated) return null;

      final response = await _client
          .from('vp_balance')
          .select()
          .eq('user_id', _auth.currentUser!.id)
          .maybeSingle();

      return response;
    } catch (e) {
      debugPrint('Get VP balance error: $e');
      return null;
    }
  }

  /// Initialize VP balance for new user
  Future<bool> initializeVPBalance() async {
    try {
      if (!_auth.isAuthenticated) return false;

      await _client.from('vp_balance').insert({
        'user_id': _auth.currentUser!.id,
        'available_vp': 100, // Starting bonus
        'lifetime_earned': 100,
      });

      return true;
    } catch (e) {
      debugPrint('Initialize VP balance error: $e');
      return false;
    }
  }

  /// Award VP for voting
  Future<bool> awardVotingVP(String electionId, {double qualityScore = 0.5}) async {
    final score = qualityScore.clamp(0.0, 1.0);
    final amount =
        (vpVotingMin + ((vpVotingMax - vpVotingMin) * score)).round();
    return await _awardVP(
      amount: amount,
      transactionType: 'voting',
      description: 'Voted in election',
      referenceId: electionId,
      referenceType: 'election',
    );
  }

  /// Award VP for daily login
  Future<bool> awardDailyLoginVP() async {
    return await _awardVP(
      amount: vpDailyLogin,
      transactionType: 'daily_login',
      description: 'Daily login bonus',
      referenceType: 'daily_login',
    );
  }

  /// Award VP for successful referral
  Future<bool> awardReferralVP(String referralUserId) async {
    return await _awardVP(
      amount: vpReferral,
      transactionType: 'referral_success',
      description: 'Successful referral reward',
      referenceId: referralUserId,
      referenceType: 'referral',
    );
  }

  /// Award VP for social interaction
  Future<bool> awardSocialVP(String interactionType, String referenceId) async {
    return await _awardVP(
      amount: vpSocialInteraction,
      transactionType: 'social_interaction',
      description: 'Social interaction: $interactionType',
      referenceId: referenceId,
      referenceType: interactionType,
    );
  }

  /// Award VP for challenge completion
  Future<bool> awardChallengeVP(int amount, String challengeId) async {
    final clampedAmount = amount.clamp(vpChallengeMin, vpChallengeMax);
    return await _awardVP(
      amount: clampedAmount,
      transactionType: 'challenge_completion',
      description: 'Challenge completed',
      referenceId: challengeId,
      referenceType: 'challenge',
    );
  }

  /// Award VP for prediction win
  Future<bool> awardPredictionVP(int amount, String predictionId) async {
    final clampedAmount = amount.clamp(0, vpPredictionMax);
    return await _awardVP(
      amount: clampedAmount,
      transactionType: 'prediction_reward',
      description: 'Prediction pool reward',
      referenceId: predictionId,
      referenceType: 'prediction',
    );
  }

  /// Award streak bonus VP
  Future<bool> awardStreakBonus(int streakDays, int bonusAmount) async {
    return await _awardVP(
      amount: bonusAmount,
      transactionType: 'streak_bonus',
      description: '$streakDays-day streak bonus',
      referenceType: 'streak',
    );
  }

  /// Award achievement unlock VP
  Future<bool> awardAchievementVP(int amount, String achievementId) async {
    return await _awardVP(
      amount: amount,
      transactionType: 'achievement_unlock',
      description: 'Achievement unlocked',
      referenceId: achievementId,
      referenceType: 'achievement',
    );
  }

  /// Spend VP for ad-free experience
  Future<bool> spendVPAdFree() async {
    return await _spendVP(
      amount: vpAdFree,
      description: 'Ad-free experience purchase',
      referenceType: 'ad_free',
    );
  }

  /// Spend VP for custom theme
  Future<bool> spendVPCustomTheme(String themeId) async {
    return await _spendVP(
      amount: vpCustomTheme,
      description: 'Custom theme purchase',
      referenceId: themeId,
      referenceType: 'theme',
    );
  }

  /// Spend VP for prediction pool entry
  Future<bool> spendVPPredictionEntry(String predictionId) async {
    return await _spendVP(
      amount: vpPredictionEntry,
      description: 'Prediction pool entry',
      referenceId: predictionId,
      referenceType: 'prediction_entry',
    );
  }

  /// Spend VP for premium content
  Future<bool> spendVPPremiumContent(String contentId) async {
    return await _spendVP(
      amount: vpPremiumContent,
      description: 'Premium content access',
      referenceId: contentId,
      referenceType: 'premium_content',
    );
  }

  Future<bool> spendVPForQuestPack(String packId) async {
    return await _spendVP(
      amount: vpQuestPack,
      description: 'Quest pack purchase',
      referenceId: packId,
      referenceType: 'quest_pack',
    );
  }

  Future<bool> spendVPForVipTier(String tierId) async {
    return await _spendVP(
      amount: vpVipTierUnlock,
      description: 'VIP tier unlock',
      referenceId: tierId,
      referenceType: 'vip_tier',
    );
  }

  Future<bool> donateVPToCharity({
    required String charityId,
    required int vpAmount,
  }) async {
    return await _spendVP(
      amount: vpAmount,
      description: 'VP charity donation',
      referenceId: charityId,
      referenceType: 'charity_donation',
    );
  }

  Future<bool> convertVPToCrypto({
    required String token,
    required int vpAmount,
    required double exchangeRate,
  }) async {
    return await _spendVP(
      amount: vpAmount,
      description:
          'VP crypto conversion to $token at rate $exchangeRate',
      referenceType: 'crypto_conversion',
    );
  }

  /// Get VP transaction history
  Future<List<Map<String, dynamic>>> getVPTransactionHistory({
    int limit = 100,
  }) async {
    try {
      if (!_auth.isAuthenticated) return [];

      final response = await _client
          .from('vp_transactions')
          .select()
          .eq('user_id', _auth.currentUser!.id)
          .order('created_at', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get VP transaction history error: $e');
      return [];
    }
  }

  /// Get earning opportunities
  Future<List<Map<String, dynamic>>> getEarningOpportunities() async {
    return [
      {
        'id': 'voting',
        'title': 'Cast a Vote',
        'description': 'Participate in elections and earn VP',
        'vp_reward_min': vpVotingMin,
        'vp_reward_max': vpVotingMax,
        'icon': 'how_to_vote',
        'action': 'vote',
      },
      {
        'id': 'daily_login',
        'title': 'Daily Login Bonus',
        'description': 'Log in daily to keep your streak alive',
        'vp_reward': vpDailyLogin,
        'icon': 'calendar_today',
        'action': 'daily_login',
      },
      {
        'id': 'social',
        'title': 'Social Interaction',
        'description': 'Comment, share, or engage with content',
        'vp_reward': vpSocialInteraction,
        'icon': 'groups',
        'action': 'interact',
      },
      {
        'id': 'referral',
        'title': 'Referral Bonus',
        'description': 'Earn VP for every successful referral',
        'vp_reward': vpReferral,
        'icon': 'person_add',
        'action': 'referral',
      },
      {
        'id': 'challenge',
        'title': 'Complete Challenges',
        'description': 'Participate in special challenges',
        'vp_reward': vpChallengeMin,
        'vp_reward_max': vpChallengeMax,
        'icon': 'flag',
        'action': 'challenge',
      },
      {
        'id': 'prediction',
        'title': 'Win Predictions',
        'description': 'Make accurate predictions and win big',
        'vp_reward': vpPredictionMax,
        'icon': 'psychology',
        'action': 'predict',
      },
    ];
  }

  /// Get spending options
  Future<List<Map<String, dynamic>>> getSpendingOptions() async {
    return [
      {
        'id': 'ad_free',
        'title': 'Ad-Free Experience',
        'description': 'Remove all ads for 30 days',
        'vp_cost': vpAdFree,
        'icon': 'block',
        'duration': '30 days',
      },
      {
        'id': 'quest_pack',
        'title': 'Quest Pack Bundle',
        'description': 'Unlock premium quest bundles',
        'vp_cost': vpQuestPack,
        'icon': 'inventory_2',
        'duration': 'Per pack',
      },
      {
        'id': 'vip_tier',
        'title': 'VIP Tier Unlock',
        'description': 'Unlock exclusive VIP tier access',
        'vp_cost': vpVipTierUnlock,
        'icon': 'workspace_premium',
        'duration': '30 days',
      },
      {
        'id': 'crypto_conversion',
        'title': 'Crypto Conversion',
        'description': 'Convert VP to supported cryptocurrency',
        'vp_cost': 0,
        'icon': 'currency_bitcoin',
        'duration': 'Instant',
      },
      {
        'id': 'charity_donation',
        'title': 'Charity Donation',
        'description': 'Donate VP to verified charity partners',
        'vp_cost': 0,
        'icon': 'volunteer_activism',
        'duration': 'Instant',
      },
      {
        'id': 'custom_theme',
        'title': 'Custom Themes',
        'description': 'Unlock exclusive app themes',
        'vp_cost': vpCustomTheme,
        'icon': 'palette',
        'duration': 'Permanent',
      },
      {
        'id': 'prediction_entry',
        'title': 'Prediction Pool Entry',
        'description': 'Enter premium prediction pools',
        'vp_cost': vpPredictionEntry,
        'icon': 'casino',
        'duration': 'Per entry',
      },
      {
        'id': 'premium_content',
        'title': 'Premium Content',
        'description': 'Access exclusive content and features',
        'vp_cost': vpPremiumContent,
        'icon': 'workspace_premium',
        'duration': '7 days',
      },
    ];
  }

  /// Internal method to award VP
  Future<bool> _awardVP({
    required int amount,
    required String transactionType,
    required String description,
    String? referenceId,
    String? referenceType,
  }) async {
    try {
      if (!_auth.isAuthenticated) return false;

      final balance = await getVPBalance();
      if (balance == null) {
        await initializeVPBalance();
        return await _awardVP(
          amount: amount,
          transactionType: transactionType,
          description: description,
          referenceId: referenceId,
          referenceType: referenceType,
        );
      }

      final currentBalance = balance['available_vp'] as int;
      final multiplier = (balance['vp_multiplier'] as num).toDouble();
      final finalAmount = (amount * multiplier).round();
      final newBalance = currentBalance + finalAmount;

      await _client.from('vp_transactions').insert({
        'user_id': _auth.currentUser!.id,
        'transaction_type': transactionType,
        'amount': finalAmount,
        'balance_before': currentBalance,
        'balance_after': newBalance,
        'description': description,
        'reference_id': referenceId,
        'reference_type': referenceType,
      });

      return true;
    } catch (e) {
      debugPrint('Award VP error: $e');
      return false;
    }
  }

  /// Internal method to spend VP
  Future<bool> _spendVP({
    required int amount,
    required String description,
    String? referenceId,
    String? referenceType,
  }) async {
    try {
      if (!_auth.isAuthenticated) return false;

      final balance = await getVPBalance();
      if (balance == null) return false;

      final currentBalance = balance['available_vp'] as int;
      if (currentBalance < amount) {
        throw Exception('Insufficient VP balance');
      }

      final newBalance = currentBalance - amount;

      await _client.from('vp_transactions').insert({
        'user_id': _auth.currentUser!.id,
        'transaction_type': 'spending',
        'amount': -amount,
        'balance_before': currentBalance,
        'balance_after': newBalance,
        'description': description,
        'reference_id': referenceId,
        'reference_type': referenceType,
      });

      return true;
    } catch (e) {
      debugPrint('Spend VP error: $e');
      return false;
    }
  }
}
