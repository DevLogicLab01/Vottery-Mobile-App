import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import './supabase_service.dart';
import './auth_service.dart';
import './stripe_connect_service.dart';

/// Service for managing carousel creator tier subscriptions, feature flags, and tier analytics
class CarouselCreatorTiersService {
  static CarouselCreatorTiersService? _instance;
  static CarouselCreatorTiersService get instance =>
      _instance ??= CarouselCreatorTiersService._();

  CarouselCreatorTiersService._();

  SupabaseClient get _client => SupabaseService.instance.client;
  AuthService get _auth => AuthService.instance;
  StripeConnectService get _stripe => StripeConnectService.instance;

  /// Get all carousel creator tiers
  Future<List<Map<String, dynamic>>> getAllTiers() async {
    try {
      final response = await _client
          .from('carousel_creator_tiers')
          .select()
          .eq('is_active', true)
          .order('tier_level', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get all tiers error: $e');
      return [];
    }
  }

  /// Get user's current subscription
  Future<Map<String, dynamic>?> getUserSubscription() async {
    try {
      if (!_auth.isAuthenticated) return null;

      final response = await _client
          .from('user_carousel_subscriptions')
          .select('*, carousel_creator_tiers(*)')
          .eq('user_id', _auth.currentUser!.id)
          .eq('subscription_status', 'active')
          .gt('current_period_end', DateTime.now().toIso8601String())
          .order('current_period_end', ascending: false)
          .limit(1)
          .maybeSingle();

      return response;
    } catch (e) {
      debugPrint('Get user subscription error: $e');
      return null;
    }
  }

  /// Get user's tier level (defaults to 1 if no subscription)
  Future<int> getUserTierLevel() async {
    try {
      final subscription = await getUserSubscription();
      if (subscription == null) return 1; // Default to starter tier

      final tier =
          subscription['carousel_creator_tiers'] as Map<String, dynamic>?;
      return tier?['tier_level'] ?? 1;
    } catch (e) {
      debugPrint('Get user tier level error: $e');
      return 1;
    }
  }

  /// Check if feature is enabled for user
  Future<bool> isFeatureEnabled(String featureName) async {
    try {
      if (!_auth.isAuthenticated) return false;

      final response = await _client.rpc(
        'is_carousel_feature_enabled',
        params: {
          'p_user_id': _auth.currentUser!.id,
          'p_feature_name': featureName,
        },
      );

      return response == true;
    } catch (e) {
      debugPrint('Check feature enabled error: $e');
      return false;
    }
  }

  /// Get all feature flags
  Future<List<Map<String, dynamic>>> getAllFeatureFlags() async {
    try {
      final response = await _client
          .from('carousel_feature_flags')
          .select()
          .order('feature_name', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get all feature flags error: $e');
      return [];
    }
  }

  /// Update feature flag (admin only)
  Future<bool> updateFeatureFlag({
    required String flagId,
    bool? enabledGlobally,
    List<int>? enabledForTiers,
    int? requiresMinimumTier,
  }) async {
    try {
      if (!_auth.isAuthenticated) return false;

      final updates = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (enabledGlobally != null) {
        updates['enabled_globally'] = enabledGlobally;
      }
      if (enabledForTiers != null) {
        updates['enabled_for_tiers'] = enabledForTiers;
      }
      if (requiresMinimumTier != null) {
        updates['requires_minimum_tier'] = requiresMinimumTier;
      }

      await _client
          .from('carousel_feature_flags')
          .update(updates)
          .eq('flag_id', flagId);

      return true;
    } catch (e) {
      debugPrint('Update feature flag error: $e');
      return false;
    }
  }

  /// Create Stripe subscription for tier upgrade
  Future<Map<String, dynamic>?> createTierSubscription({
    required String tierId,
    required bool isAnnual,
  }) async {
    try {
      if (!_auth.isAuthenticated) return null;

      // Get tier details
      final tier = await _client
          .from('carousel_creator_tiers')
          .select()
          .eq('tier_id', tierId)
          .single();

      final price = isAnnual ? tier['annual_price'] : tier['monthly_price'];

      if (price == null || price == 0) {
        // Free tier - create subscription without Stripe
        return await _createFreeSubscription(tierId);
      }

      // TODO: Integrate with Stripe subscription creation
      // This would call Stripe API to create subscription
      // For now, return placeholder
      return {
        'tier_id': tierId,
        'price': price,
        'interval': isAnnual ? 'year' : 'month',
        'requires_payment': true,
      };
    } catch (e) {
      debugPrint('Create tier subscription error: $e');
      return null;
    }
  }

  /// Create free subscription (starter tier)
  Future<Map<String, dynamic>?> _createFreeSubscription(String tierId) async {
    try {
      final now = DateTime.now();
      final periodEnd = now.add(Duration(days: 365)); // 1 year for free tier

      final response = await _client
          .from('user_carousel_subscriptions')
          .insert({
            'user_id': _auth.currentUser!.id,
            'tier_id': tierId,
            'subscription_status': 'active',
            'current_period_start': now.toIso8601String(),
            'current_period_end': periodEnd.toIso8601String(),
          })
          .select()
          .single();

      return response;
    } catch (e) {
      debugPrint('Create free subscription error: $e');
      return null;
    }
  }

  /// Cancel subscription
  Future<bool> cancelSubscription(String subscriptionId) async {
    try {
      if (!_auth.isAuthenticated) return false;

      await _client
          .from('user_carousel_subscriptions')
          .update({
            'cancel_at_period_end': true,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('subscription_id', subscriptionId)
          .eq('user_id', _auth.currentUser!.id);

      return true;
    } catch (e) {
      debugPrint('Cancel subscription error: $e');
      return false;
    }
  }

  /// Get tier analytics (admin only)
  Future<Map<String, dynamic>> getTierAnalytics() async {
    try {
      final subscriptions = await _client
          .from('user_carousel_subscriptions')
          .select('*, carousel_creator_tiers(tier_name, tier_level)')
          .eq('subscription_status', 'active');

      final tierCounts = <String, int>{};
      double totalRevenue = 0;

      for (final sub in subscriptions) {
        final tier = sub['carousel_creator_tiers'] as Map<String, dynamic>?;
        final tierName = tier?['tier_name'] ?? 'unknown';
        tierCounts[tierName] = (tierCounts[tierName] ?? 0) + 1;
      }

      return {
        'total_subscribers': subscriptions.length,
        'tier_breakdown': tierCounts,
        'total_revenue': totalRevenue,
      };
    } catch (e) {
      debugPrint('Get tier analytics error: $e');
      return {};
    }
  }

  /// Stream feature flags for real-time updates
  Stream<List<Map<String, dynamic>>> streamFeatureFlags() {
    return _client
        .from('carousel_feature_flags')
        .stream(primaryKey: ['flag_id'])
        .order('feature_name');
  }
}
