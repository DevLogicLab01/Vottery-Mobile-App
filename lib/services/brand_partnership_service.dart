import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import './supabase_service.dart';
import './auth_service.dart';

class BrandPartnershipService {
  static BrandPartnershipService? _instance;
  static BrandPartnershipService get instance =>
      _instance ??= BrandPartnershipService._();

  BrandPartnershipService._();

  SupabaseClient get _client => SupabaseService.instance.client;
  AuthService get _auth => AuthService.instance;

  /// Get active brand campaigns
  Future<List<Map<String, dynamic>>> getActiveCampaigns({
    String? creatorId,
  }) async {
    try {
      final response = await _client
          .from('brand_partnerships')
          .select('''
            *,
            brand:user_profiles!brand_partnerships_brand_id_fkey(
              id,
              full_name,
              avatar_url
            ),
            brand_verification(
              verification_status,
              trust_score,
              average_rating
            )
          ''')
          .eq('status', 'open')
          .gte('application_deadline', DateTime.now().toIso8601String())
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get active campaigns error: $e');
      return [];
    }
  }

  /// Get available opportunities for creator
  Future<List<Map<String, dynamic>>> getAvailableOpportunities({
    required String creatorId,
  }) async {
    try {
      // Get creator profile for matching
      final creatorProfile = await _client
          .from('user_profiles')
          .select('*')
          .eq('id', creatorId)
          .maybeSingle();

      if (creatorProfile == null) return [];

      // Get campaigns matching creator profile
      final response = await _client
          .from('brand_partnerships')
          .select('''
            *,
            brand:user_profiles!brand_partnerships_brand_id_fkey(
              id,
              full_name,
              avatar_url
            ),
            brand_verification(
              verification_status,
              trust_score,
              average_rating
            )
          ''')
          .eq('status', 'open')
          .gte('application_deadline', DateTime.now().toIso8601String())
          .order('revenue_potential', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get available opportunities error: $e');
      return [];
    }
  }

  /// Get partnership history for creator
  Future<List<Map<String, dynamic>>> getPartnershipHistory({
    required String creatorId,
  }) async {
    try {
      final response = await _client
          .from('partnership_history')
          .select('''
            *,
            campaign:brand_partnerships(
              campaign_name,
              brand_logo_url
            ),
            brand:user_profiles!partnership_history_brand_id_fkey(
              full_name,
              avatar_url
            )
          ''')
          .eq('creator_id', creatorId)
          .order('completed_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get partnership history error: $e');
      return [];
    }
  }

  /// Get verified brands directory
  Future<List<Map<String, dynamic>>> getBrandDirectory() async {
    try {
      final response = await _client
          .from('brand_verification')
          .select('''
            *,
            brand:user_profiles!brand_verification_brand_id_fkey(
              id,
              full_name,
              avatar_url,
              bio
            )
          ''')
          .eq('verification_status', 'verified')
          .order('average_rating', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get brand directory error: $e');
      return [];
    }
  }

  /// Apply to campaign
  Future<bool> applyToCampaign({
    required String campaignId,
    required String creatorId,
    required Map<String, dynamic> applicationData,
  }) async {
    try {
      await _client.from('campaign_applications').insert({
        'campaign_id': campaignId,
        'creator_id': creatorId,
        'application_status': 'pending',
        'portfolio_submission': applicationData['portfolio'] ?? [],
        'audience_demographics': applicationData['demographics'] ?? {},
        'collaboration_proposal': applicationData['proposal'] ?? '',
        'expected_reach': applicationData['expected_reach'] ?? 0,
        'expected_engagement_rate':
            applicationData['expected_engagement_rate'] ?? 0.0,
        'proposed_content_plan': applicationData['content_plan'] ?? [],
      });

      return true;
    } catch (e) {
      debugPrint('Apply to campaign error: $e');
      return false;
    }
  }

  /// Get creator applications
  Future<List<Map<String, dynamic>>> getCreatorApplications({
    required String creatorId,
  }) async {
    try {
      final response = await _client
          .from('campaign_applications')
          .select('''
            *,
            campaign:brand_partnerships(
              campaign_name,
              brand_logo_url,
              revenue_potential,
              status
            )
          ''')
          .eq('creator_id', creatorId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get creator applications error: $e');
      return [];
    }
  }

  /// Get revenue tracking for creator
  Future<Map<String, dynamic>> getRevenueTracking({
    required String creatorId,
  }) async {
    try {
      // Get total earnings from partnership history
      final historyResponse = await _client
          .from('partnership_history')
          .select('total_earnings')
          .eq('creator_id', creatorId);

      double totalEarnings = 0.0;
      double thisMonthEarnings = 0.0;

      for (var record in historyResponse) {
        final earnings = (record['total_earnings'] ?? 0.0) as num;
        totalEarnings += earnings.toDouble();
      }

      // Get this month's earnings
      final thisMonthStart = DateTime(
        DateTime.now().year,
        DateTime.now().month,
        1,
      );

      final thisMonthResponse = await _client
          .from('partnership_history')
          .select('total_earnings')
          .eq('creator_id', creatorId)
          .gte('completed_at', thisMonthStart.toIso8601String());

      for (var record in thisMonthResponse) {
        final earnings = (record['total_earnings'] ?? 0.0) as num;
        thisMonthEarnings += earnings.toDouble();
      }

      // Get active campaigns count
      final activeApplications = await _client
          .from('campaign_applications')
          .select('id')
          .eq('creator_id', creatorId)
          .eq('application_status', 'accepted');

      return {
        'total_earnings': totalEarnings,
        'this_month_earnings': thisMonthEarnings,
        'active_campaigns': activeApplications.length,
        'currency': 'USD',
      };
    } catch (e) {
      debugPrint('Get revenue tracking error: $e');
      return {
        'total_earnings': 0.0,
        'this_month_earnings': 0.0,
        'active_campaigns': 0,
        'currency': 'USD',
      };
    }
  }

  /// Get campaign performance metrics
  Future<Map<String, dynamic>> getCampaignPerformance({
    required String campaignId,
    required String creatorId,
  }) async {
    try {
      final response = await _client
          .from('partnership_history')
          .select('*')
          .eq('campaign_id', campaignId)
          .eq('creator_id', creatorId)
          .maybeSingle();

      return response ?? {};
    } catch (e) {
      debugPrint('Get campaign performance error: $e');
      return {};
    }
  }

  /// Withdraw application
  Future<bool> withdrawApplication({required String applicationId}) async {
    try {
      await _client
          .from('campaign_applications')
          .update({'application_status': 'withdrawn'})
          .eq('id', applicationId);

      return true;
    } catch (e) {
      debugPrint('Withdraw application error: $e');
      return false;
    }
  }
}
