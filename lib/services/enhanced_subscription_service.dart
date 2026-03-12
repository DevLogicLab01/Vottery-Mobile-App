import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import './supabase_service.dart';
import './auth_service.dart';
import './payment_service.dart';
import './analytics_service.dart';

class EnhancedSubscriptionService {
  static EnhancedSubscriptionService? _instance;
  static EnhancedSubscriptionService get instance =>
      _instance ??= EnhancedSubscriptionService._();

  EnhancedSubscriptionService._();

  final _supabase = SupabaseService.instance.client;
  final _auth = AuthService.instance;
  final _payment = PaymentService.instance;
  final _analytics = AnalyticsService.instance;
  final Dio _dio = Dio();
  final String _baseUrl = '${SupabaseService.supabaseUrl}/functions/v1';

  /// Get all available subscription plans
  Future<List<Map<String, dynamic>>> getSubscriptionPlans() async {
    try {
      final response = await _supabase
          .from('subscription_plans')
          .select()
          .eq('is_active', true)
          .order('price_usd', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get subscription plans error: $e');
      return [];
    }
  }

  /// Get user's current subscription
  Future<Map<String, dynamic>?> getCurrentSubscription() async {
    try {
      if (!_auth.isAuthenticated) return null;

      final response = await _supabase
          .from('subscriptions')
          .select()
          .eq('user_id', _auth.currentUser!.id)
          .eq('status', 'active')
          .maybeSingle();

      return response;
    } catch (e) {
      debugPrint('Get current subscription error: $e');
      return null;
    }
  }

  /// Subscribe to a plan
  Future<SubscriptionResult> subscribe({
    required String planId,
    String? promoCode,
  }) async {
    try {
      if (!_auth.isAuthenticated) {
        return SubscriptionResult(
          success: false,
          message: 'User must be authenticated',
        );
      }

      // Get plan details
      final plan = await _supabase
          .from('subscription_plans')
          .select()
          .eq('plan_id', planId)
          .maybeSingle();

      if (plan == null) {
        return SubscriptionResult(success: false, message: 'Plan not found');
      }

      // Check if free plan
      if (plan['price_usd'] == 0) {
        return await _activateFreePlan(planId);
      }

      // Check if pay-as-you-go
      if (planId == 'pay_as_you_go') {
        return SubscriptionResult(
          success: true,
          message: 'Pay-as-you-go activated. You will be charged per election.',
        );
      }

      // Process payment for paid plans
      final paymentResult = await _payment.purchaseVP(
        vpAmount: 0,
        priceUsd: plan['price_usd'] as double,
      );

      if (!paymentResult.success) {
        return SubscriptionResult(
          success: false,
          message: 'Payment failed: ${paymentResult.message}',
        );
      }

      // Calculate next billing date
      final durationMonths = plan['duration_months'] as int? ?? 1;
      final nextBillingDate = DateTime.now().add(
        Duration(days: durationMonths * 30),
      );

      // Create subscription
      await _supabase.from('subscriptions').insert({
        'user_id': _auth.currentUser!.id,
        'tier': planId,
        'billing_period': _getBillingPeriod(durationMonths),
        'price': plan['price_usd'],
        'status': 'active',
        'start_date': DateTime.now().toIso8601String(),
        'next_billing_date': nextBillingDate.toIso8601String(),
        'payment_intent_id': paymentResult.paymentIntentId,
      });

      // Track analytics
      await _analytics.trackUserEngagement(
        action: 'subscription_purchased',
        screen: 'subscription_center',
        additionalParams: {'plan_id': planId},
      );

      return SubscriptionResult(
        success: true,
        message: 'Subscription activated successfully',
      );
    } catch (e) {
      debugPrint('Subscribe error: $e');
      return SubscriptionResult(
        success: false,
        message: 'Subscription failed: ${e.toString()}',
      );
    }
  }

  /// Upgrade subscription with proration
  Future<SubscriptionResult> upgradePlan(String newPlanId) async {
    try {
      if (!_auth.isAuthenticated) {
        return SubscriptionResult(
          success: false,
          message: 'User must be authenticated',
        );
      }

      final userId = _auth.currentUser!.id;

      // Get current subscription
      final currentSub = await getCurrentSubscription();
      if (currentSub == null) {
        return SubscriptionResult(
          success: false,
          message: 'No active subscription found',
        );
      }

      // Get new plan
      final newPlan = await _supabase
          .from('subscription_plans')
          .select()
          .eq('plan_id', newPlanId)
          .maybeSingle();

      if (newPlan == null) {
        return SubscriptionResult(success: false, message: 'Plan not found');
      }

      // Calculate proration credit
      final prorationCredit = await _supabase.rpc(
        'calculate_proration_credit',
        params: {'p_user_id': userId, 'p_new_plan_id': newPlanId},
      );

      final credit = (prorationCredit as num?)?.toDouble() ?? 0.0;
      final newPrice = (newPlan['price_usd'] as num).toDouble();
      final amountToPay = (newPrice - credit).clamp(0.0, double.infinity);

      // Process payment if needed
      if (amountToPay > 0) {
        final paymentResult = await _payment.purchaseVP(
          vpAmount: 0,
          priceUsd: amountToPay,
        );

        if (!paymentResult.success) {
          return SubscriptionResult(
            success: false,
            message: 'Payment failed: ${paymentResult.message}',
          );
        }
      }

      // Update subscription
      await _supabase
          .from('subscriptions')
          .update({
            'tier': newPlanId,
            'price': newPrice,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', currentSub['id']);

      // Log subscription change
      await _supabase.from('subscription_changes').insert({
        'user_id': userId,
        'from_plan_id': currentSub['tier'],
        'to_plan_id': newPlanId,
        'change_type': 'upgrade',
        'proration_credit': credit,
        'effective_date': DateTime.now().toIso8601String(),
      });

      return SubscriptionResult(
        success: true,
        message: 'Plan upgraded successfully',
        prorationCredit: credit,
      );
    } catch (e) {
      debugPrint('Upgrade plan error: $e');
      return SubscriptionResult(
        success: false,
        message: 'Upgrade failed: ${e.toString()}',
      );
    }
  }

  /// Downgrade subscription (scheduled for next billing)
  Future<SubscriptionResult> downgradePlan({
    required String newPlanId,
    bool immediate = false,
  }) async {
    try {
      if (!_auth.isAuthenticated) {
        return SubscriptionResult(
          success: false,
          message: 'User must be authenticated',
        );
      }

      final userId = _auth.currentUser!.id;

      // Get current subscription
      final currentSub = await getCurrentSubscription();
      if (currentSub == null) {
        return SubscriptionResult(
          success: false,
          message: 'No active subscription found',
        );
      }

      if (immediate) {
        // Immediate downgrade
        await _supabase
            .from('subscriptions')
            .update({
              'tier': newPlanId,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', currentSub['id']);

        return SubscriptionResult(
          success: true,
          message: 'Plan downgraded immediately',
        );
      } else {
        // Schedule downgrade for next billing
        await _supabase
            .from('subscriptions')
            .update({
              'pending_plan_change': newPlanId,
              'pending_change_date': currentSub['next_billing_date'],
            })
            .eq('id', currentSub['id']);

        return SubscriptionResult(
          success: true,
          message: 'Downgrade scheduled for next billing cycle',
        );
      }
    } catch (e) {
      debugPrint('Downgrade plan error: $e');
      return SubscriptionResult(
        success: false,
        message: 'Downgrade failed: ${e.toString()}',
      );
    }
  }

  /// Cancel subscription
  Future<bool> cancelSubscription() async {
    try {
      if (!_auth.isAuthenticated) return false;

      await _supabase
          .from('subscriptions')
          .update({
            'status': 'cancelled',
            'cancelled_at': DateTime.now().toIso8601String(),
          })
          .eq('user_id', _auth.currentUser!.id)
          .eq('status', 'active');

      return true;
    } catch (e) {
      debugPrint('Cancel subscription error: $e');
      return false;
    }
  }

  /// Get subscription change history
  Future<List<Map<String, dynamic>>> getSubscriptionHistory() async {
    try {
      if (!_auth.isAuthenticated) return [];

      final response = await _supabase
          .from('subscription_changes')
          .select()
          .eq('user_id', _auth.currentUser!.id)
          .order('created_at', ascending: false)
          .limit(50);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get subscription history error: $e');
      return [];
    }
  }

  /// Get recommended plan based on usage
  Future<String> getRecommendedPlan() async {
    try {
      if (!_auth.isAuthenticated) return 'free';

      // Get user's election count in last 30 days
      final thirtyDaysAgo = DateTime.now().subtract(Duration(days: 30));
      final elections = await _supabase
          .from('elections')
          .select('id')
          .eq('creator_id', _auth.currentUser!.id)
          .gte('created_at', thirtyDaysAgo.toIso8601String());

      final electionCount = elections.length;

      // Recommend based on usage
      if (electionCount <= 5) return 'free';
      if (electionCount <= 10) return 'pay_as_you_go';
      if (electionCount <= 50) return 'monthly';
      if (electionCount <= 150) return 'quarterly';
      if (electionCount <= 300) return 'semi_annual';
      return 'yearly';
    } catch (e) {
      debugPrint('Get recommended plan error: $e');
      return 'free';
    }
  }

  /// Get comprehensive subscription analytics
  Future<Map<String, dynamic>> getSubscriptionAnalytics() async {
    try {
      final response = await _supabase.rpc('get_subscription_analytics');

      if (response == null) {
        return {
          'mrr_tracking': [],
          'churn_analysis': [],
          'ltv_cohorts': [],
          'revenue_forecasts': [],
        };
      }

      return response as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Error fetching subscription analytics: $e');
      return {
        'mrr_tracking': [],
        'churn_analysis': [],
        'ltv_cohorts': [],
        'revenue_forecasts': [],
      };
    }
  }

  Future<SubscriptionResult> _activateFreePlan(String planId) async {
    try {
      await _supabase.from('subscriptions').insert({
        'user_id': _auth.currentUser!.id,
        'tier': planId,
        'billing_period': 'free',
        'price': 0,
        'status': 'active',
        'start_date': DateTime.now().toIso8601String(),
      });

      return SubscriptionResult(success: true, message: 'Free plan activated');
    } catch (e) {
      return SubscriptionResult(
        success: false,
        message: 'Failed to activate free plan',
      );
    }
  }

  String _getBillingPeriod(int months) {
    if (months == 1) return 'monthly';
    if (months == 3) return 'quarterly';
    if (months == 6) return 'semi_annual';
    if (months == 12) return 'yearly';
    return 'custom';
  }
}

class SubscriptionResult {
  final bool success;
  final String message;
  final double? prorationCredit;

  SubscriptionResult({
    required this.success,
    required this.message,
    this.prorationCredit,
  });
}
