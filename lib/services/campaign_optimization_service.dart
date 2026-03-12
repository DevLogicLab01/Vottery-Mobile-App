import 'package:supabase_flutter/supabase_flutter.dart';

class CampaignOptimizationService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Fetch optimization recommendations for advertiser
  Future<List<Map<String, dynamic>>> getOptimizationRecommendations({
    String? campaignId,
    String? recommendationType,
    String? status,
  }) async {
    try {
      var query = _supabase
          .from('campaign_optimization_recommendations')
          .select('*')
          .eq('advertiser_id', _supabase.auth.currentUser!.id);

      if (campaignId != null) {
        query = query.eq('campaign_id', campaignId);
      }
      if (recommendationType != null) {
        query = query.eq('recommendation_type', recommendationType);
      }
      if (status != null) {
        query = query.eq('status', status);
      }

      final response = await query.order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch optimization recommendations: $e');
    }
  }

  // Apply optimization recommendation
  Future<void> applyOptimizationRecommendation(String recommendationId) async {
    try {
      await _supabase
          .from('campaign_optimization_recommendations')
          .update({
            'status': 'applied',
            'applied_at': DateTime.now().toIso8601String(),
          })
          .eq('id', recommendationId)
          .eq('advertiser_id', _supabase.auth.currentUser!.id);
    } catch (e) {
      throw Exception('Failed to apply optimization recommendation: $e');
    }
  }

  // Reject optimization recommendation
  Future<void> rejectOptimizationRecommendation(String recommendationId) async {
    try {
      await _supabase
          .from('campaign_optimization_recommendations')
          .update({'status': 'rejected'})
          .eq('id', recommendationId)
          .eq('advertiser_id', _supabase.auth.currentUser!.id);
    } catch (e) {
      throw Exception('Failed to reject optimization recommendation: $e');
    }
  }

  // Fetch audience expansion suggestions
  Future<List<Map<String, dynamic>>> getAudienceExpansionSuggestions({
    String? campaignId,
    String? status,
  }) async {
    try {
      var query = _supabase
          .from('audience_expansion_suggestions')
          .select('*')
          .eq('advertiser_id', _supabase.auth.currentUser!.id);

      if (campaignId != null) {
        query = query.eq('campaign_id', campaignId);
      }
      if (status != null) {
        query = query.eq('status', status);
      }

      final response = await query.order('similarity_score', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch audience expansion suggestions: $e');
    }
  }

  // Apply audience expansion suggestion
  Future<void> applyAudienceExpansion(String suggestionId) async {
    try {
      await _supabase
          .from('audience_expansion_suggestions')
          .update({'status': 'testing'})
          .eq('id', suggestionId)
          .eq('advertiser_id', _supabase.auth.currentUser!.id);
    } catch (e) {
      throw Exception('Failed to apply audience expansion: $e');
    }
  }

  // Fetch creative performance tracking
  Future<List<Map<String, dynamic>>> getCreativePerformance({
    String? campaignId,
    String? abTestGroup,
  }) async {
    try {
      var query = _supabase
          .from('creative_performance_tracking')
          .select('*')
          .eq('advertiser_id', _supabase.auth.currentUser!.id);

      if (campaignId != null) {
        query = query.eq('campaign_id', campaignId);
      }
      if (abTestGroup != null) {
        query = query.eq('ab_test_group', abTestGroup);
      }

      final response = await query.order('roas', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch creative performance: $e');
    }
  }

  // Mark creative as winner
  Future<void> markCreativeAsWinner(
    String creativeId,
    String campaignId,
  ) async {
    try {
      // Reset all winners for this campaign
      await _supabase
          .from('creative_performance_tracking')
          .update({'is_winner': false})
          .eq('campaign_id', campaignId)
          .eq('advertiser_id', _supabase.auth.currentUser!.id);

      // Mark new winner
      await _supabase
          .from('creative_performance_tracking')
          .update({'is_winner': true, 'rotation_weight': 2.0})
          .eq('id', creativeId)
          .eq('advertiser_id', _supabase.auth.currentUser!.id);
    } catch (e) {
      throw Exception('Failed to mark creative as winner: $e');
    }
  }

  // Fetch campaign automation rules
  Future<List<Map<String, dynamic>>> getAutomationRules({
    String? campaignId,
    bool? isActive,
  }) async {
    try {
      var query = _supabase
          .from('campaign_automation_rules')
          .select('*')
          .eq('advertiser_id', _supabase.auth.currentUser!.id);

      if (campaignId != null) {
        query = query.eq('campaign_id', campaignId);
      }
      if (isActive != null) {
        query = query.eq('is_active', isActive);
      }

      final response = await query.order('priority', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch automation rules: $e');
    }
  }

  // Create automation rule
  Future<void> createAutomationRule({
    required String campaignId,
    required String ruleName,
    required String ruleType,
    required Map<String, dynamic> triggerConditions,
    required Map<String, dynamic> actions,
    int priority = 1,
  }) async {
    try {
      await _supabase.from('campaign_automation_rules').insert({
        'campaign_id': campaignId,
        'advertiser_id': _supabase.auth.currentUser!.id,
        'rule_name': ruleName,
        'rule_type': ruleType,
        'trigger_conditions': triggerConditions,
        'actions': actions,
        'priority': priority,
        'is_active': true,
      });
    } catch (e) {
      throw Exception('Failed to create automation rule: $e');
    }
  }

  // Toggle automation rule
  Future<void> toggleAutomationRule(String ruleId, bool isActive) async {
    try {
      await _supabase
          .from('campaign_automation_rules')
          .update({'is_active': isActive})
          .eq('id', ruleId)
          .eq('advertiser_id', _supabase.auth.currentUser!.id);
    } catch (e) {
      throw Exception('Failed to toggle automation rule: $e');
    }
  }

  // Delete automation rule
  Future<void> deleteAutomationRule(String ruleId) async {
    try {
      await _supabase
          .from('campaign_automation_rules')
          .delete()
          .eq('id', ruleId)
          .eq('advertiser_id', _supabase.auth.currentUser!.id);
    } catch (e) {
      throw Exception('Failed to delete automation rule: $e');
    }
  }

  // Fetch budget optimization history
  Future<List<Map<String, dynamic>>> getBudgetOptimizationHistory({
    String? campaignId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      var query = _supabase
          .from('budget_optimization_history')
          .select('*')
          .eq('advertiser_id', _supabase.auth.currentUser!.id);

      if (campaignId != null) {
        query = query.eq('campaign_id', campaignId);
      }
      if (startDate != null) {
        query = query.gte('optimization_date', startDate.toIso8601String());
      }
      if (endDate != null) {
        query = query.lte('optimization_date', endDate.toIso8601String());
      }

      final response = await query.order('optimization_date', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch budget optimization history: $e');
    }
  }

  // Fetch ROI enhancement tracking
  Future<List<Map<String, dynamic>>> getRoiEnhancementTracking({
    String? campaignId,
    String? enhancementType,
  }) async {
    try {
      var query = _supabase
          .from('roi_enhancement_tracking')
          .select('*')
          .eq('advertiser_id', _supabase.auth.currentUser!.id);

      if (campaignId != null) {
        query = query.eq('campaign_id', campaignId);
      }
      if (enhancementType != null) {
        query = query.eq('enhancement_type', enhancementType);
      }

      final response = await query.order(
        'roi_improvement_percent',
        ascending: false,
      );
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch ROI enhancement tracking: $e');
    }
  }

  // Get campaign optimization summary
  Future<List<Map<String, dynamic>>> getCampaignOptimizationSummary() async {
    try {
      final response = await _supabase.rpc(
        'get_campaign_optimization_summary',
        params: {'p_advertiser_id': _supabase.auth.currentUser!.id},
      );
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch campaign optimization summary: $e');
    }
  }

  // Generate ML-powered budget reallocation recommendation
  Future<void> generateBudgetReallocationRecommendation({
    required String campaignId,
    required Map<String, dynamic> currentPerformance,
  }) async {
    try {
      // Simulate ML algorithm analysis
      final double currentRoas = (currentPerformance['roas'] ?? 0.0).toDouble();
      final double currentSpend = (currentPerformance['spend'] ?? 0.0)
          .toDouble();

      double suggestedBudgetChange = 0.0;
      String reason = '';

      if (currentRoas > 3.0) {
        suggestedBudgetChange = 0.20; // Increase by 20%
        reason = 'High ROAS detected - recommend budget increase for scaling';
      } else if (currentRoas < 1.5) {
        suggestedBudgetChange = -0.15; // Decrease by 15%
        reason = 'Low ROAS detected - recommend budget reduction';
      } else {
        suggestedBudgetChange = 0.05; // Slight increase
        reason = 'Stable performance - minor optimization recommended';
      }

      final suggestedBudget = currentSpend * (1 + suggestedBudgetChange);
      final projectedRoi = currentRoas * (1 + (suggestedBudgetChange * 0.5));

      await _supabase.from('campaign_optimization_recommendations').insert({
        'campaign_id': campaignId,
        'advertiser_id': _supabase.auth.currentUser!.id,
        'recommendation_type': 'budget_reallocation',
        'current_performance': currentPerformance,
        'suggested_changes': {
          'current_budget': currentSpend,
          'suggested_budget': suggestedBudget,
          'budget_change_percent': suggestedBudgetChange * 100,
          'reason': reason,
        },
        'projected_improvement': {
          'projected_roas': projectedRoi,
          'projected_roi_improvement':
              ((projectedRoi - currentRoas) / currentRoas) * 100,
        },
        'confidence_score': 85.0,
        'ml_model_version': 'v1.2.0',
        'status': 'pending',
      });
    } catch (e) {
      throw Exception(
        'Failed to generate budget reallocation recommendation: $e',
      );
    }
  }
}
