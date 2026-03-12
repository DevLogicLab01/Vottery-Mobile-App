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
  static const int vpVoting = 10;
  static const int vpSocialInteraction = 5;
  static const int vpChallengeMin = 50;
  static const int vpChallengeMax = 500;
  static const int vpPredictionMax = 1000;

  // VP Spending Options
  static const int vpAdFree = 500;
  static const int vpCustomTheme = 300;
  static const int vpPredictionEntry = 100;
  static const int vpPremiumContent = 200;

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
  Future<bool> awardVotingVP(String electionId) async {
    return await _awardVP(
      amount: vpVoting,
      transactionType: 'voting',
      description: 'Voted in election',
      referenceId: electionId,
      referenceType: 'election',
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
        'vp_reward': vpVoting,
        'icon': 'how_to_vote',
        'action': 'vote',
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
