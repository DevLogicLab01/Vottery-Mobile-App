import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import './supabase_service.dart';
import './auth_service.dart';
import './payout_notification_service.dart';

class TierCalculationService {
  static TierCalculationService? _instance;
  static TierCalculationService get instance =>
      _instance ??= TierCalculationService._();

  TierCalculationService._();

  SupabaseClient get _client => SupabaseService.instance.client;
  AuthService get _auth => AuthService.instance;

  /// Calculate tier based on earnings and VP
  Future<String> calculateTier({
    required double totalEarnings,
    required int lifetimeVp,
  }) async {
    try {
      final response = await _client.rpc(
        'calculate_creator_tier',
        params: {
          'p_total_earnings': totalEarnings,
          'p_lifetime_vp': lifetimeVp,
        },
      );

      return response ?? 'bronze';
    } catch (e) {
      debugPrint('Calculate tier error: $e');
      return 'bronze';
    }
  }

  /// Get all tier configurations
  Future<List<Map<String, dynamic>>> getAllTierConfigs() async {
    try {
      final response = await _client
          .from('creator_tier_config')
          .select()
          .order('tier_rank', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get all tier configs error: $e');
      return [];
    }
  }

  /// Get tier config for specific tier
  Future<Map<String, dynamic>?> getTierConfig(String tierLevel) async {
    try {
      final response = await _client
          .from('creator_tier_config')
          .select()
          .eq('tier_level', tierLevel)
          .maybeSingle();

      return response;
    } catch (e) {
      debugPrint('Get tier config error: $e');
      return null;
    }
  }

  /// Get user's current tier from creator_accounts
  Future<Map<String, dynamic>> getUserTierInfo() async {
    try {
      if (!_auth.isAuthenticated) return _getDefaultTierInfo();

      final response = await _client
          .from('creator_accounts')
          .select('tier_level, total_earnings, lifetime_vp_earned')
          .eq('creator_user_id', _auth.currentUser!.id)
          .maybeSingle();

      if (response == null) return _getDefaultTierInfo();

      final tierLevel = response['tier_level'] ?? 'bronze';
      final tierConfig = await getTierConfig(tierLevel);

      return {
        'current_tier': tierLevel,
        'total_earnings': response['total_earnings'] ?? 0.0,
        'lifetime_vp': response['lifetime_vp_earned'] ?? 0,
        'vp_multiplier': tierConfig?['vp_multiplier'] ?? 1.0,
        'payout_schedule': tierConfig?['payout_schedule'] ?? 'weekly',
        'minimum_threshold': tierConfig?['minimum_threshold'] ?? 50.0,
        'features': tierConfig?['features'] ?? [],
      };
    } catch (e) {
      debugPrint('Get user tier info error: $e');
      return _getDefaultTierInfo();
    }
  }

  /// Get tier upgrade history
  Future<List<Map<String, dynamic>>> getTierUpgradeHistory() async {
    try {
      if (!_auth.isAuthenticated) return [];

      final response = await _client
          .from('tier_upgrade_history')
          .select()
          .eq('user_id', _auth.currentUser!.id)
          .order('upgraded_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get tier upgrade history error: $e');
      return [];
    }
  }

  /// Check and update tier if requirements met
  Future<Map<String, dynamic>> checkAndUpdateTier() async {
    try {
      if (!_auth.isAuthenticated) {
        return {'upgraded': false, 'message': 'Not authenticated'};
      }

      final userInfo = await getUserTierInfo();
      final currentTier = userInfo['current_tier'] as String;
      final totalEarnings = userInfo['total_earnings'] as double;
      final lifetimeVp = userInfo['lifetime_vp'] as int;

      final newTier = await calculateTier(
        totalEarnings: totalEarnings,
        lifetimeVp: lifetimeVp,
      );

      if (newTier != currentTier) {
        // Update creator_accounts
        await _client
            .from('creator_accounts')
            .update({
              'tier_level': newTier,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('creator_user_id', _auth.currentUser!.id);

        // Record upgrade history
        await _client.from('tier_upgrade_history').insert({
          'user_id': _auth.currentUser!.id,
          'old_tier': currentTier,
          'new_tier': newTier,
        });

        // Send notification
        await _sendTierUpgradeNotification(currentTier, newTier);

        return {
          'upgraded': true,
          'old_tier': currentTier,
          'new_tier': newTier,
          'message': 'Congratulations! You have reached $newTier tier!',
        };
      }

      return {'upgraded': false, 'message': 'No tier change'};
    } catch (e) {
      debugPrint('Check and update tier error: $e');
      return {'upgraded': false, 'message': e.toString()};
    }
  }

  /// Send tier upgrade notification
  Future<void> _sendTierUpgradeNotification(
    String oldTier,
    String newTier,
  ) async {
    try {
      // Get user email
      final profile = await _client
          .from('user_profiles')
          .select('email')
          .eq('id', _auth.currentUser!.id)
          .maybeSingle();

      if (profile == null) return;

      // Get new tier config
      final tierConfig = await getTierConfig(newTier);
      if (tierConfig == null) return;

      final vpMultiplier = (tierConfig['vp_multiplier'] as num).toDouble();
      final features = tierConfig['features'] as List? ?? [];

      // Import and use notification service
      final notificationService = PayoutNotificationService.instance;
      await notificationService.sendTierUpgradeNotification(
        recipientEmail: profile['email'],
        oldTier: oldTier,
        newTier: newTier,
        vpMultiplier: vpMultiplier,
        newFeatures: features.map((f) => f.toString()).toList(),
      );
    } catch (e) {
      debugPrint('Send tier upgrade notification error: $e');
    }
  }

  /// Get progress to next tier
  Future<Map<String, dynamic>> getProgressToNextTier() async {
    try {
      if (!_auth.isAuthenticated) return _getDefaultProgress();

      final userInfo = await getUserTierInfo();
      final currentTier = userInfo['current_tier'] as String;
      final totalEarnings = userInfo['total_earnings'] as double;
      final lifetimeVp = userInfo['lifetime_vp'] as int;

      final allTiers = await getAllTierConfigs();
      final currentTierIndex = allTiers.indexWhere(
        (t) => t['tier_level'] == currentTier,
      );

      if (currentTierIndex == -1 || currentTierIndex >= allTiers.length - 1) {
        return {
          'is_max_tier': true,
          'current_tier': currentTier,
          'message': 'You are at the highest tier!',
        };
      }

      final nextTier = allTiers[currentTierIndex + 1];
      final earningsRequired = (nextTier['earnings_requirement'] as num)
          .toDouble();
      final vpRequired = nextTier['vp_requirement'] as int;

      final earningsProgress = totalEarnings >= earningsRequired
          ? 1.0
          : totalEarnings / earningsRequired;
      final vpProgress = lifetimeVp >= vpRequired
          ? 1.0
          : lifetimeVp / vpRequired;

      return {
        'is_max_tier': false,
        'current_tier': currentTier,
        'next_tier': nextTier['tier_level'],
        'next_tier_name': nextTier['tier_name'],
        'earnings_current': totalEarnings,
        'earnings_required': earningsRequired,
        'earnings_progress': earningsProgress,
        'vp_current': lifetimeVp,
        'vp_required': vpRequired,
        'vp_progress': vpProgress,
        'overall_progress': (earningsProgress + vpProgress) / 2,
      };
    } catch (e) {
      debugPrint('Get progress to next tier error: $e');
      return _getDefaultProgress();
    }
  }

  Map<String, dynamic> _getDefaultTierInfo() {
    return {
      'current_tier': 'bronze',
      'total_earnings': 0.0,
      'lifetime_vp': 0,
      'vp_multiplier': 1.0,
      'payout_schedule': 'weekly',
      'minimum_threshold': 50.0,
      'features': [],
    };
  }

  Map<String, dynamic> _getDefaultProgress() {
    return {
      'is_max_tier': false,
      'current_tier': 'bronze',
      'next_tier': 'silver',
      'earnings_current': 0.0,
      'earnings_required': 1000.0,
      'earnings_progress': 0.0,
      'vp_current': 0,
      'vp_required': 5000,
      'vp_progress': 0.0,
      'overall_progress': 0.0,
    };
  }
}
