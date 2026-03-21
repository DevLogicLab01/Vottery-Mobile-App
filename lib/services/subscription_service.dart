import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import './payment_service.dart';
import './supabase_service.dart';
import './auth_service.dart';
import './vp_service.dart';
import './analytics_service.dart';

class SubscriptionService {
  static SubscriptionService? _instance;
  static SubscriptionService get instance =>
      _instance ??= SubscriptionService._();

  SubscriptionService._();

  SupabaseClient get _client => SupabaseService.instance.client;
  AuthService get _auth => AuthService.instance;
  PaymentService get _payment => PaymentService.instance;
  VPService get _vp => VPService.instance;
  AnalyticsService get _analytics => AnalyticsService.instance;

  // Subscription tiers with VP multipliers
  static const Map<String, Map<String, dynamic>> tiers = {
    'basic': {
      'name': 'Basic',
      'vp_multiplier': 2.0,
      'price_monthly': 4.99,
      'price_yearly': 49.99,
      'features': [
        '2x VP Multiplier',
        'Ad-Free Experience',
        'Custom Themes',
        'Priority Support',
      ],
    },
    'pro': {
      'name': 'Pro',
      'vp_multiplier': 3.0,
      'price_monthly': 9.99,
      'price_yearly': 99.99,
      'features': [
        '3x VP Multiplier',
        'All Basic Features',
        'Advanced Analytics',
        'Exclusive Badges',
        'Early Access',
      ],
    },
    'elite': {
      'name': 'Elite',
      'vp_multiplier': 5.0,
      'price_monthly': 19.99,
      'price_yearly': 199.99,
      'features': [
        '5x VP Multiplier',
        'All Pro Features',
        'VIP Support',
        'Creator Tools',
        'Revenue Sharing',
        'Custom Branding',
      ],
    },
  };

  /// Get user's current subscription
  Future<Map<String, dynamic>?> getCurrentSubscription() async {
    try {
      if (!_auth.isAuthenticated) return null;

      final response = await _client
          .from('user_subscriptions')
          .select('*, plan:plan_id(*)')
          .eq('user_id', _auth.currentUser!.id)
          .eq('is_active', true)
          .maybeSingle();

      if (response != null) {
        return response;
      }

      final legacy = await _client
          .from('subscriptions')
          .select()
          .eq('user_id', _auth.currentUser!.id)
          .eq('status', 'active')
          .maybeSingle();

      return legacy;
    } catch (e) {
      debugPrint('Get current subscription error: $e');
      return null;
    }
  }

  /// Subscribe to a tier
  Future<bool> subscribe({
    required String tier,
    required String billingPeriod,
  }) async {
    try {
      if (!_auth.isAuthenticated) return false;

      final tierData = tiers[tier];
      if (tierData == null) return false;

      final price = billingPeriod == 'monthly'
          ? tierData['price_monthly']
          : tierData['price_yearly'];

      final paymentResult = await _payment.purchaseVP(
        vpAmount: 0,
        priceUsd: price,
      );

      if (!paymentResult.success) return false;

      await _client.from('subscriptions').insert({
        'user_id': _auth.currentUser!.id,
        'tier': tier,
        'billing_period': billingPeriod,
        'price': price,
        'status': 'active',
        'start_date': DateTime.now().toIso8601String(),
        'next_billing_date': _calculateNextBillingDate(billingPeriod),
        'payment_intent_id': paymentResult.paymentIntentId,
      });

      // Keep parity with web billing source-of-truth.
      await _client.from('user_subscriptions').upsert({
        'user_id': _auth.currentUser!.id,
        'subscriber_type': 'individual',
        'is_active': true,
        'auto_renew': true,
        'start_date': DateTime.now().toIso8601String(),
        'end_date': _calculateNextBillingDate(billingPeriod),
        'updated_at': DateTime.now().toIso8601String(),
      });

      await _applyVPMultiplier(tierData['vp_multiplier']);

      await _analytics.trackUserEngagement(
        action: 'subscription_purchased',
        screen: 'subscription_center',
        additionalParams: {'tier': tier, 'billing_period': billingPeriod},
      );

      return true;
    } catch (e) {
      debugPrint('Subscribe error: $e');
      return false;
    }
  }

  /// Cancel subscription
  Future<bool> cancelSubscription() async {
    try {
      if (!_auth.isAuthenticated) return false;

      await _client
          .from('subscriptions')
          .update({
            'status': 'cancelled',
            'cancelled_at': DateTime.now().toIso8601String(),
          })
          .eq('user_id', _auth.currentUser!.id)
          .eq('status', 'active');

      await _client
          .from('user_subscriptions')
          .update({
            'is_active': false,
            'auto_renew': false,
            'end_date': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('user_id', _auth.currentUser!.id)
          .eq('is_active', true);

      await _applyVPMultiplier(1.0);

      return true;
    } catch (e) {
      debugPrint('Cancel subscription error: $e');
      return false;
    }
  }

  /// Upgrade subscription tier
  Future<bool> upgradeTier(String newTier) async {
    try {
      if (!_auth.isAuthenticated) return false;

      final currentSub = await getCurrentSubscription();
      if (currentSub == null) return false;

      final newTierData = tiers[newTier];
      if (newTierData == null) return false;

      await _client
          .from('subscriptions')
          .update({
            'tier': newTier,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', currentSub['id']);

      final userSubscriptionId = currentSub['id']?.toString();
      if (userSubscriptionId != null) {
        await _client.from('user_subscriptions').update({
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', userSubscriptionId);
      }

      await _applyVPMultiplier(newTierData['vp_multiplier']);

      return true;
    } catch (e) {
      debugPrint('Upgrade tier error: $e');
      return false;
    }
  }

  /// Get subscription history
  Future<List<Map<String, dynamic>>> getSubscriptionHistory() async {
    try {
      if (!_auth.isAuthenticated) return [];

      final response = await _client
          .from('subscriptions')
          .select()
          .eq('user_id', _auth.currentUser!.id)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get subscription history error: $e');
      return [];
    }
  }

  /// Check if user has active subscription
  Future<bool> hasActiveSubscription() async {
    final sub = await getCurrentSubscription();
    if (sub == null) return false;
    if (sub.containsKey('is_active')) {
      return sub['is_active'] == true;
    }
    return sub['status'] == 'active';
  }

  /// Get subscription benefits
  Map<String, dynamic> getSubscriptionBenefits(String tier) {
    return tiers[tier] ?? {};
  }

  Future<void> _applyVPMultiplier(double multiplier) async {
    try {
      await _client
          .from('vp_balance')
          .update({'vp_multiplier': multiplier})
          .eq('user_id', _auth.currentUser!.id);
    } catch (e) {
      debugPrint('Apply VP multiplier error: $e');
    }
  }

  String _calculateNextBillingDate(String billingPeriod) {
    final now = DateTime.now();
    final nextDate = billingPeriod == 'monthly'
        ? DateTime(now.year, now.month + 1, now.day)
        : DateTime(now.year + 1, now.month, now.day);
    return nextDate.toIso8601String();
  }
}
