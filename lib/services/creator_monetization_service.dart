import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import './supabase_service.dart';
import './auth_service.dart';

class CreatorMonetizationService {
  static CreatorMonetizationService? _instance;
  static CreatorMonetizationService get instance =>
      _instance ??= CreatorMonetizationService._();

  CreatorMonetizationService._();

  SupabaseClient get _client => SupabaseService.instance.client;
  AuthService get _auth => AuthService.instance;

  // Revenue split configuration (70% creator, 30% platform)
  static const double creatorSharePercentage = 70.0;
  static const double platformSharePercentage = 30.0;

  /// Get creator earnings summary
  Future<Map<String, dynamic>> getCreatorEarnings() async {
    try {
      if (!_auth.isAuthenticated) return _getDefaultEarnings();

      final response = await _client.rpc(
        'get_creator_earnings',
        params: {'creator_id': _auth.currentUser!.id},
      );

      return response ?? _getDefaultEarnings();
    } catch (e) {
      debugPrint('Get creator earnings error: $e');
      return _getDefaultEarnings();
    }
  }

  /// Get revenue breakdown by source
  Future<Map<String, dynamic>> getRevenueBreakdown() async {
    try {
      if (!_auth.isAuthenticated) return _getDefaultBreakdown();

      final response = await _client.rpc(
        'get_revenue_breakdown',
        params: {'creator_id': _auth.currentUser!.id},
      );

      return response ?? _getDefaultBreakdown();
    } catch (e) {
      debugPrint('Get revenue breakdown error: $e');
      return _getDefaultBreakdown();
    }
  }

  /// Request payout
  Future<bool> requestPayout({
    required double amount,
    required String payoutMethod,
    Map<String, dynamic>? payoutDetails,
  }) async {
    try {
      if (!_auth.isAuthenticated) return false;

      final earnings = await getCreatorEarnings();
      final availableBalance = earnings['available_balance'] ?? 0.0;

      if (amount > availableBalance) {
        debugPrint('Insufficient balance for payout');
        return false;
      }

      await _client.from('payout_requests').insert({
        'creator_id': _auth.currentUser!.id,
        'amount': amount,
        'payout_method': payoutMethod,
        'payout_details': payoutDetails ?? {},
        'status': 'pending',
      });

      return true;
    } catch (e) {
      debugPrint('Request payout error: $e');
      return false;
    }
  }

  /// Get payout history
  Future<List<Map<String, dynamic>>> getPayoutHistory() async {
    try {
      if (!_auth.isAuthenticated) return [];

      final response = await _client
          .from('payout_requests')
          .select()
          .eq('creator_id', _auth.currentUser!.id)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get payout history error: $e');
      return [];
    }
  }

  /// Get creator tier information
  Future<Map<String, dynamic>> getCreatorTier() async {
    try {
      if (!_auth.isAuthenticated) return _getDefaultTierData();

      final response = await _client
          .from('creator_tiers')
          .select()
          .eq('creator_id', _auth.currentUser!.id)
          .maybeSingle();

      if (response == null) {
        return _getDefaultTierData();
      }

      return {
        'current_tier': response['tier_name'] ?? 'Bronze',
        'tier_level': response['tier_level'] ?? 1,
        'next_milestone_progress': response['next_milestone_progress'] ?? 0.0,
        'benefits': response['benefits'] ?? [],
        'requirements_met': response['requirements_met'] ?? [],
      };
    } catch (e) {
      debugPrint('Get creator tier error: $e');
      return _getDefaultTierData();
    }
  }

  /// Get monetization milestones
  Future<List<Map<String, dynamic>>> getMilestones() async {
    try {
      if (!_auth.isAuthenticated) return _getDefaultMilestones();

      final response = await _client
          .from('creator_milestones')
          .select()
          .eq('creator_id', _auth.currentUser!.id)
          .order('target', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get milestones error: $e');
      return _getDefaultMilestones();
    }
  }

  /// Track content revenue
  Future<void> trackContentRevenue({
    required String contentId,
    required String contentType,
    required double revenue,
    required String revenueSource,
  }) async {
    try {
      if (!_auth.isAuthenticated) return;

      final creatorShare = revenue * (creatorSharePercentage / 100);
      final platformShare = revenue * (platformSharePercentage / 100);

      await _client.from('revenue_transactions').insert({
        'creator_id': _auth.currentUser!.id,
        'content_id': contentId,
        'content_type': contentType,
        'total_revenue': revenue,
        'creator_share': creatorShare,
        'platform_share': platformShare,
        'revenue_source': revenueSource,
      });
    } catch (e) {
      debugPrint('Track content revenue error: $e');
    }
  }

  /// Get content performance analytics
  Future<List<Map<String, dynamic>>> getContentPerformance() async {
    try {
      if (!_auth.isAuthenticated) return [];

      final response = await _client.rpc(
        'get_content_performance',
        params: {'creator_id': _auth.currentUser!.id},
      );

      return List<Map<String, dynamic>>.from(response ?? []);
    } catch (e) {
      debugPrint('Get content performance error: $e');
      return [];
    }
  }

  /// Get brand partnership opportunities
  Future<List<Map<String, dynamic>>> getBrandPartnerships() async {
    try {
      if (!_auth.isAuthenticated) return [];

      final response = await _client
          .from('brand_partnerships')
          .select()
          .eq('status', 'open')
          .order('budget', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get brand partnerships error: $e');
      return [];
    }
  }

  /// Get active revenue share configuration
  Future<Map<String, dynamic>> getActiveRevenueShareConfig({
    String? creatorId,
  }) async {
    try {
      final response = await _client.rpc(
        'get_active_revenue_share_config',
        params: {'creator_id': creatorId},
      );

      return response ?? _getDefaultRevenueConfig();
    } catch (e) {
      debugPrint('Get active revenue share config error: $e');
      return _getDefaultRevenueConfig();
    }
  }

  /// Calculate revenue split
  Future<Map<String, dynamic>> calculateRevenueSplit({
    required double totalRevenue,
    String? creatorId,
  }) async {
    try {
      final config = await getActiveRevenueShareConfig(creatorId: creatorId);
      final creatorPercentage = config['creator_percentage'] ?? 70.0;
      final platformPercentage = config['platform_percentage'] ?? 30.0;

      final creatorShare = totalRevenue * (creatorPercentage / 100);
      final platformShare = totalRevenue * (platformPercentage / 100);

      return {
        'total_revenue': totalRevenue,
        'creator_share': creatorShare,
        'platform_share': platformShare,
        'creator_percentage': creatorPercentage,
        'platform_percentage': platformPercentage,
        'config_id': config['id'],
      };
    } catch (e) {
      debugPrint('Calculate revenue split error: $e');
      return {
        'total_revenue': totalRevenue,
        'creator_share': totalRevenue * 0.7,
        'platform_share': totalRevenue * 0.3,
        'creator_percentage': 70.0,
        'platform_percentage': 30.0,
      };
    }
  }

  Map<String, dynamic> _getDefaultRevenueConfig() {
    return {
      'id': null,
      'creator_percentage': 70.0,
      'platform_percentage': 30.0,
      'campaign_name': 'Default Split',
    };
  }

  Map<String, dynamic> _getDefaultEarnings() {
    return {
      'total_earnings': 0.0,
      'available_balance': 0.0,
      'pending_balance': 0.0,
      'lifetime_earnings': 0.0,
      'this_month': 0.0,
      'last_month': 0.0,
    };
  }

  Map<String, dynamic> _getDefaultBreakdown() {
    return {
      'vp_tips': 0.0,
      'ad_revenue': 0.0,
      'subscriptions': 0.0,
      'brand_deals': 0.0,
      'merchandise': 0.0,
    };
  }

  Map<String, dynamic> _getDefaultTier() {
    return {
      'tier': 'Bronze Creator',
      'tier_level': 1,
      'revenue_share_percentage': creatorSharePercentage,
      'benefits': [
        'Basic analytics',
        '70/30 revenue split',
        'Standard support',
      ],
    };
  }

  Map<String, dynamic> _getDefaultTierData() {
    return {
      'current_tier': 'Bronze',
      'tier_level': 1,
      'next_milestone_progress': 0.0,
      'benefits': [],
      'requirements_met': [],
    };
  }

  List<Map<String, dynamic>> _getDefaultMilestones() {
    return [
      {
        'title': 'First \$100 Earned',
        'description': 'Earn your first \$100 in revenue',
        'target': 100.0,
        'current': 0.0,
        'achieved': false,
        'reward': '100 Bonus VP',
      },
      {
        'title': '1000 Followers',
        'description': 'Reach 1000 followers on the platform',
        'target': 1000.0,
        'current': 0.0,
        'achieved': false,
        'reward': 'Featured Creator Badge',
      },
      {
        'title': 'Top Performer',
        'description': 'Rank in top 10% of creators for the month',
        'target': 1.0,
        'current': 0.0,
        'achieved': false,
        'reward': '500 Bonus VP + Priority Support',
      },
    ];
  }
}
