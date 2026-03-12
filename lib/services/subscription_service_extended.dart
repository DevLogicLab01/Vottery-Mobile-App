import 'package:flutter/material.dart';

import './supabase_service.dart';

class UserSubscription {
  final String id;
  final String userId;
  final String planType; // basic, pro, elite
  final int vpMultiplier;
  final String status; // active, past_due, canceled, expired
  final DateTime? subscriptionStartDate;
  final DateTime? nextBillingDate;
  final double? subscriptionAmount;
  final String? paymentMethod;
  final String? cardLast4;
  final String? paypalEmail;

  UserSubscription({
    required this.id,
    required this.userId,
    required this.planType,
    required this.vpMultiplier,
    required this.status,
    this.subscriptionStartDate,
    this.nextBillingDate,
    this.subscriptionAmount,
    this.paymentMethod,
    this.cardLast4,
    this.paypalEmail,
  });

  factory UserSubscription.fromMap(Map<String, dynamic> map) {
    final planType = map['plan_type']?.toString() ?? 'basic';
    int vpMultiplier;
    switch (planType.toLowerCase()) {
      case 'elite':
        vpMultiplier = 5;
        break;
      case 'pro':
        vpMultiplier = 3;
        break;
      default:
        vpMultiplier = 2;
    }

    return UserSubscription(
      id: map['id']?.toString() ?? '',
      userId: map['user_id']?.toString() ?? '',
      planType: planType,
      vpMultiplier: vpMultiplier,
      status: map['status']?.toString() ?? 'active',
      subscriptionStartDate: map['subscription_start_date'] != null
          ? DateTime.tryParse(map['subscription_start_date'].toString())
          : null,
      nextBillingDate: map['next_billing_date'] != null
          ? DateTime.tryParse(map['next_billing_date'].toString())
          : null,
      subscriptionAmount: (map['subscription_amount'] as num?)?.toDouble(),
      paymentMethod: map['payment_method']?.toString(),
      cardLast4: map['card_last4']?.toString(),
      paypalEmail: map['paypal_email']?.toString(),
    );
  }

  static UserSubscription get defaultBasic => UserSubscription(
    id: 'default',
    userId: '',
    planType: 'basic',
    vpMultiplier: 2,
    status: 'active',
    subscriptionAmount: 9.99,
  );
}

class SubscriptionServiceExtended {
  static final SubscriptionServiceExtended instance =
      SubscriptionServiceExtended._internal();
  SubscriptionServiceExtended._internal();

  final _client = SupabaseService.instance.client;

  Future<UserSubscription?> getUserSubscription(String userId) async {
    try {
      final response = await _client
          .from('user_subscriptions')
          .select()
          .eq('user_id', userId)
          .inFilter('status', ['active', 'past_due'])
          .order('created_at', ascending: false)
          .limit(1);

      if (response.isEmpty) return UserSubscription.defaultBasic;
      return UserSubscription.fromMap(response.first);
    } catch (e) {
      debugPrint('getUserSubscription error: $e');
      return UserSubscription.defaultBasic;
    }
  }

  Future<List<Map<String, dynamic>>> getBillingHistory(String userId) async {
    try {
      final response = await _client
          .from('billing_history')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(20);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('getBillingHistory error: $e');
      return [];
    }
  }

  String getNextTier(String currentPlan) {
    switch (currentPlan.toLowerCase()) {
      case 'basic':
        return 'Pro';
      case 'pro':
        return 'Elite';
      default:
        return '';
    }
  }

  String getLowerTier(String currentPlan) {
    switch (currentPlan.toLowerCase()) {
      case 'elite':
        return 'Pro';
      case 'pro':
        return 'Basic';
      default:
        return '';
    }
  }

  double getPlanPrice(String plan) {
    switch (plan.toLowerCase()) {
      case 'pro':
        return 24.99;
      case 'elite':
        return 49.99;
      default:
        return 9.99;
    }
  }
}
