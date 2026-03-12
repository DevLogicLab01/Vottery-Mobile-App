import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import './supabase_service.dart';
import './auth_service.dart';

class RevenueSplitAdminService {
  static RevenueSplitAdminService? _instance;
  static RevenueSplitAdminService get instance =>
      _instance ??= RevenueSplitAdminService._();

  RevenueSplitAdminService._();

  SupabaseClient get _client => SupabaseService.instance.client;
  AuthService get _auth => AuthService.instance;

  /// Get current global split configuration
  Future<Map<String, dynamic>?> getGlobalSplit() async {
    try {
      final response = await _client
          .from('revenue_split_config')
          .select('*, user_profiles!created_by(full_name)')
          .eq('is_active', true)
          .eq('split_type', 'global')
          .order('effective_date', ascending: false)
          .limit(1)
          .maybeSingle();

      return response;
    } catch (e) {
      debugPrint('Get global split error: $e');
      return null;
    }
  }

  /// Update global split configuration
  Future<bool> updateGlobalSplit({
    required int creatorPercentage,
    required int platformPercentage,
    required DateTime effectiveDate,
    required String reason,
  }) async {
    try {
      if (!_auth.isAuthenticated) return false;

      // Validate split totals 100%
      if (creatorPercentage + platformPercentage != 100) {
        throw Exception('Split percentages must total 100%');
      }

      // Deactivate current config
      await _client
          .from('revenue_split_config')
          .update({'is_active': false})
          .eq('is_active', true)
          .eq('split_type', 'global');

      // Insert new config
      await _client.from('revenue_split_config').insert({
        'split_type': 'global',
        'creator_percentage': creatorPercentage,
        'platform_percentage': platformPercentage,
        'effective_date': effectiveDate.toIso8601String().split('T')[0],
        'reason': reason,
        'is_active': true,
        'created_by': _auth.currentUser!.id,
      });

      // Log audit
      await _logAuditAction(
        actionType: 'config_change',
        details: {
          'creator_percentage': creatorPercentage,
          'platform_percentage': platformPercentage,
          'effective_date': effectiveDate.toIso8601String(),
          'reason': reason,
        },
      );

      return true;
    } catch (e) {
      debugPrint('Update global split error: $e');
      return false;
    }
  }

  /// Get all active campaigns
  Future<List<Map<String, dynamic>>> getActiveCampaigns() async {
    try {
      final response = await _client
          .from('revenue_split_campaigns')
          .select('*, user_profiles!created_by(full_name)')
          .inFilter('status', ['scheduled', 'active', 'paused'])
          .order('start_date', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get active campaigns error: $e');
      return [];
    }
  }

  /// Create new campaign
  Future<String?> createCampaign({
    required String campaignName,
    required String campaignDescription,
    required String campaignType,
    required int creatorSplitPercentage,
    required Map<String, dynamic> eligibilityCriteria,
    required DateTime startDate,
    DateTime? endDate,
    Map<String, dynamic>? autoEndConditions,
  }) async {
    try {
      if (!_auth.isAuthenticated) return null;

      final response = await _client
          .from('revenue_split_campaigns')
          .insert({
            'campaign_name': campaignName,
            'campaign_description': campaignDescription,
            'campaign_type': campaignType,
            'creator_split_percentage': creatorSplitPercentage,
            'eligibility_criteria': eligibilityCriteria,
            'start_date': startDate.toIso8601String().split('T')[0],
            'end_date': endDate?.toIso8601String().split('T')[0],
            'auto_end_conditions': autoEndConditions,
            'status': startDate.isAfter(DateTime.now())
                ? 'scheduled'
                : 'active',
            'created_by': _auth.currentUser!.id,
          })
          .select('campaign_id')
          .single();

      final campaignId = response['campaign_id'] as String;

      // Log audit
      await _logAuditAction(
        actionType: 'campaign_create',
        details: {
          'campaign_id': campaignId,
          'campaign_name': campaignName,
          'creator_split_percentage': creatorSplitPercentage,
        },
      );

      return campaignId;
    } catch (e) {
      debugPrint('Create campaign error: $e');
      return null;
    }
  }

  /// Update campaign
  Future<bool> updateCampaign({
    required String campaignId,
    String? campaignName,
    String? campaignDescription,
    int? creatorSplitPercentage,
    Map<String, dynamic>? eligibilityCriteria,
    DateTime? endDate,
    String? status,
  }) async {
    try {
      if (!_auth.isAuthenticated) return false;

      final updates = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (campaignName != null) updates['campaign_name'] = campaignName;
      if (campaignDescription != null) {
        updates['campaign_description'] = campaignDescription;
      }
      if (creatorSplitPercentage != null) {
        updates['creator_split_percentage'] = creatorSplitPercentage;
      }
      if (eligibilityCriteria != null) {
        updates['eligibility_criteria'] = eligibilityCriteria;
      }
      if (endDate != null) {
        updates['end_date'] = endDate.toIso8601String().split('T')[0];
      }
      if (status != null) {
        updates['status'] = status;
        if (status == 'ended') {
          updates['ended_at'] = DateTime.now().toIso8601String();
        }
      }

      await _client
          .from('revenue_split_campaigns')
          .update(updates)
          .eq('campaign_id', campaignId);

      // Log audit
      await _logAuditAction(
        actionType: 'campaign_modify',
        details: {'campaign_id': campaignId, 'changes': updates},
      );

      return true;
    } catch (e) {
      debugPrint('Update campaign error: $e');
      return false;
    }
  }

  /// Get campaign enrollments
  Future<List<Map<String, dynamic>>> getCampaignEnrollments({
    required String campaignId,
  }) async {
    try {
      final response = await _client
          .from('campaign_enrollments')
          .select('*, user_profiles!creator_user_id(username, avatar_url)')
          .eq('campaign_id', campaignId)
          .eq('is_active', true)
          .order('enrolled_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get campaign enrollments error: $e');
      return [];
    }
  }

  /// Check if creator matches campaign eligibility
  Future<bool> checkEligibility({
    required String creatorUserId,
    required Map<String, dynamic> eligibilityCriteria,
  }) async {
    try {
      // Get creator profile
      final creator = await _client
          .from('creator_accounts')
          .select('tier, total_earnings')
          .eq('creator_user_id', creatorUserId)
          .maybeSingle();

      if (creator == null) return false;

      // Check tier eligibility
      final tierList = eligibilityCriteria['tier'] as List?;
      if (tierList != null && tierList.isNotEmpty) {
        final creatorTier = creator['tier'] as String? ?? 'bronze';
        if (!tierList.contains('all') && !tierList.contains(creatorTier)) {
          return false;
        }
      }

      // Check minimum earnings
      final minEarnings = eligibilityCriteria['min_earnings'] as num? ?? 0;
      final totalEarnings = creator['total_earnings'] as num? ?? 0;
      if (totalEarnings < minEarnings) {
        return false;
      }

      return true;
    } catch (e) {
      debugPrint('Check eligibility error: $e');
      return false;
    }
  }

  /// Get applicable split for transaction
  Future<Map<String, dynamic>> getSplitForTransaction({
    required String creatorUserId,
    required String transactionType,
    required double transactionAmount,
  }) async {
    try {
      // Check active campaigns first
      final campaigns = await _client
          .from('revenue_split_campaigns')
          .select()
          .eq('status', 'active')
          .lte('start_date', DateTime.now().toIso8601String().split('T')[0])
          .or(
            'end_date.is.null,end_date.gte.${DateTime.now().toIso8601String().split('T')[0]}',
          )
          .order('creator_split_percentage', ascending: false);

      // Find highest matching campaign
      for (final campaign in campaigns) {
        final eligibility =
            campaign['eligibility_criteria'] as Map<String, dynamic>;
        final isEligible = await checkEligibility(
          creatorUserId: creatorUserId,
          eligibilityCriteria: eligibility,
        );

        if (isEligible) {
          final splitPercentage = campaign['creator_split_percentage'] as int;
          final creatorAmount = transactionAmount * (splitPercentage / 100);
          final platformAmount = transactionAmount - creatorAmount;

          return {
            'split_percentage': splitPercentage,
            'creator_amount': creatorAmount,
            'platform_amount': platformAmount,
            'campaign_id': campaign['campaign_id'],
            'split_config_id': null,
          };
        }
      }

      // Use global split if no campaign matches
      final globalSplit = await getGlobalSplit();
      if (globalSplit != null) {
        final splitPercentage = globalSplit['creator_percentage'] as int;
        final creatorAmount = transactionAmount * (splitPercentage / 100);
        final platformAmount = transactionAmount - creatorAmount;

        return {
          'split_percentage': splitPercentage,
          'creator_amount': creatorAmount,
          'platform_amount': platformAmount,
          'campaign_id': null,
          'split_config_id': globalSplit['config_id'],
        };
      }

      // Default fallback (70/30)
      return {
        'split_percentage': 70,
        'creator_amount': transactionAmount * 0.7,
        'platform_amount': transactionAmount * 0.3,
        'campaign_id': null,
        'split_config_id': null,
      };
    } catch (e) {
      debugPrint('Get split for transaction error: $e');
      return {
        'split_percentage': 70,
        'creator_amount': transactionAmount * 0.7,
        'platform_amount': transactionAmount * 0.3,
        'campaign_id': null,
        'split_config_id': null,
      };
    }
  }

  /// Log transaction split application
  Future<void> logTransactionSplit({
    required String transactionId,
    required String transactionType,
    required String creatorUserId,
    required double transactionAmount,
    required Map<String, dynamic> splitResult,
  }) async {
    try {
      await _client.from('transaction_split_log').insert({
        'transaction_id': transactionId,
        'transaction_type': transactionType,
        'creator_user_id': creatorUserId,
        'split_config_id': splitResult['split_config_id'],
        'campaign_id': splitResult['campaign_id'],
        'transaction_amount': transactionAmount,
        'creator_amount': splitResult['creator_amount'],
        'platform_amount': splitResult['platform_amount'],
        'creator_percentage': splitResult['split_percentage'],
      });
    } catch (e) {
      debugPrint('Log transaction split error: $e');
    }
  }

  /// Get split audit log
  Future<List<Map<String, dynamic>>> getAuditLog({int limit = 50}) async {
    try {
      final response = await _client
          .from('split_audit_log')
          .select('*, user_profiles!action_by(full_name, username)')
          .order('timestamp', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get audit log error: $e');
      return [];
    }
  }

  /// Get split statistics
  Future<Map<String, dynamic>> getSplitStatistics() async {
    try {
      final globalSplit = await getGlobalSplit();
      final activeCampaigns = await getActiveCampaigns();

      // Get total creators affected
      final creatorsResponse = await _client
          .from('creator_accounts')
          .select('creator_user_id')
          .count(CountOption.exact);

      final totalCreators = creatorsResponse.count;

      // Get enrolled creators count
      final enrolledResponse = await _client
          .from('campaign_enrollments')
          .select('creator_user_id')
          .eq('is_active', true)
          .count(CountOption.exact);

      final enrolledCreators = enrolledResponse.count;

      return {
        'current_global_split': globalSplit?['creator_percentage'] ?? 70,
        'active_campaigns_count': activeCampaigns.length,
        'total_creators': totalCreators,
        'enrolled_creators': enrolledCreators,
        'last_updated': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      debugPrint('Get split statistics error: $e');
      return {
        'current_global_split': 70,
        'active_campaigns_count': 0,
        'total_creators': 0,
        'enrolled_creators': 0,
      };
    }
  }

  /// Private helper to log audit actions
  Future<void> _logAuditAction({
    required String actionType,
    required Map<String, dynamic> details,
  }) async {
    try {
      await _client.from('split_audit_log').insert({
        'action_type': actionType,
        'action_by': _auth.currentUser?.id,
        'action_details': details,
        'affected_creators_count': 0, // Can be calculated based on action
      });
    } catch (e) {
      debugPrint('Log audit action error: $e');
    }
  }
}
