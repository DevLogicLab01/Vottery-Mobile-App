import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import './ai/ai_service_base.dart';

/// Election Insights Analytics Service
/// Provides OpenAI GPT-5 powered predictive modeling and analytics
/// for election outcomes, voting trends, and demographic insights
class ElectionInsightsService {
  static ElectionInsightsService? _instance;
  static ElectionInsightsService get instance =>
      _instance ??= ElectionInsightsService._();

  ElectionInsightsService._();

  final SupabaseClient _supabase = Supabase.instance.client;

  // =====================================================
  // OUTCOME PREDICTIONS
  // =====================================================

  /// Generate election outcome predictions using OpenAI GPT-5
  Future<Map<String, dynamic>> generatePredictions(String electionId) async {
    try {
      // Get historical voting data
      final votingData = await _getElectionVotingData(electionId);
      final demographicData = await _getDemographicData(electionId);

      // Call OpenAI GPT-5 for predictions
      final response =
          await AIServiceBase.invokeAIFunction('openai-election-insights', {
            'election_id': electionId,
            'voting_data': votingData,
            'demographic_data': demographicData,
            'analysis_type': 'outcome_prediction',
            'timestamp': DateTime.now().toIso8601String(),
          });

      AIServiceBase.validateResponse(response, ['predictions']);

      // Store predictions in database
      await _supabase.from('election_predictions').insert({
        'election_id': electionId,
        'prediction_data': response['predictions'],
        'confidence_score': response['confidence_score'] ?? 0.0,
        'accuracy_metrics': response['accuracy_metrics'] ?? {},
      });

      return response['predictions'] as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Generate predictions error: $e');
      return {};
    }
  }

  /// Get stored predictions for election
  Future<Map<String, dynamic>?> getPredictions(String electionId) async {
    try {
      final response = await _supabase
          .from('election_predictions')
          .select()
          .eq('election_id', electionId)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      return response;
    } catch (e) {
      debugPrint('Get predictions error: $e');
      return null;
    }
  }

  // =====================================================
  // VOTING TRENDS
  // =====================================================

  /// Get voting trends over time
  Future<List<Map<String, dynamic>>> getVotingTrends(
    String electionId, {
    int hours = 24,
  }) async {
    try {
      final startTime = DateTime.now().subtract(Duration(hours: hours));

      final response = await _supabase
          .from('voting_trends')
          .select()
          .eq('election_id', electionId)
          .gte('timestamp', startTime.toIso8601String())
          .order('timestamp', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get voting trends error: $e');
      return [];
    }
  }

  /// Calculate vote momentum
  Future<Map<String, dynamic>> getVoteMomentum(String electionId) async {
    try {
      final trends = await getVotingTrends(electionId, hours: 6);

      if (trends.length < 2) {
        return {'momentum': 0.0, 'direction': 'stable'};
      }

      final latest = trends.last['vote_count'] as int;
      final previous = trends[trends.length - 2]['vote_count'] as int;
      final momentum = ((latest - previous) / previous * 100).toDouble();

      String direction = 'stable';
      if (momentum > 5) {
        direction = 'up';
      } else if (momentum < -5) {
        direction = 'down';
      }

      return {
        'momentum': momentum,
        'direction': direction,
        'latest_count': latest,
        'previous_count': previous,
      };
    } catch (e) {
      debugPrint('Get vote momentum error: $e');
      return {'momentum': 0.0, 'direction': 'stable'};
    }
  }

  // =====================================================
  // DEMOGRAPHIC BREAKDOWN
  // =====================================================

  /// Get demographic breakdown
  Future<List<Map<String, dynamic>>> getDemographicBreakdown(
    String electionId,
  ) async {
    try {
      final response = await _supabase
          .from('demographic_breakdown')
          .select()
          .eq('election_id', electionId)
          .order('vote_count', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get demographic breakdown error: $e');
      return [];
    }
  }

  /// Get demographic breakdown by type
  Future<List<Map<String, dynamic>>> getDemographicsByType(
    String electionId,
    String demographicType,
  ) async {
    try {
      final response = await _supabase
          .from('demographic_breakdown')
          .select()
          .eq('election_id', electionId)
          .eq('demographic_type', demographicType)
          .order('percentage', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get demographics by type error: $e');
      return [];
    }
  }

  // =====================================================
  // SWING VOTER IDENTIFICATION
  // =====================================================

  /// Identify swing voters using AI
  Future<List<Map<String, dynamic>>> identifySwingVoters(
    String electionId,
  ) async {
    try {
      // Get voting patterns
      final votingData = await _getElectionVotingData(electionId);

      // Call OpenAI for swing voter analysis
      final response =
          await AIServiceBase.invokeAIFunction('openai-election-insights', {
            'election_id': electionId,
            'voting_data': votingData,
            'analysis_type': 'swing_voter_identification',
            'timestamp': DateTime.now().toIso8601String(),
          });

      AIServiceBase.validateResponse(response, ['swing_voters']);

      return List<Map<String, dynamic>>.from(response['swing_voters']);
    } catch (e) {
      debugPrint('Identify swing voters error: $e');
      return [];
    }
  }

  /// Get stored swing voters
  Future<List<Map<String, dynamic>>> getSwingVoters(String electionId) async {
    try {
      final response = await _supabase
          .from('swing_voters')
          .select(
            'id, election_id, user_id, vote_switching_pattern, undecided_score, targeting_suggestions, created_at, updated_at',
          )
          .eq('election_id', electionId)
          .order('undecided_score', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get swing voters error: $e');
      return [];
    }
  }

  // =====================================================
  // STRATEGIC RECOMMENDATIONS
  // =====================================================

  /// Generate strategic recommendations using AI
  Future<List<Map<String, dynamic>>> generateRecommendations(
    String electionId,
  ) async {
    try {
      // Get election creator
      final election = await _supabase
          .from('elections')
          .select('created_by')
          .eq('id', electionId)
          .maybeSingle();

      if (election == null || election['created_by'] == null) {
        debugPrint('Election not found or has no creator');
        return [];
      }

      final creatorId = election['created_by'] as String;

      final votingData = await _getElectionVotingData(electionId);
      final demographicData = await _getDemographicData(electionId);
      final engagementData = await _getEngagementData(electionId);

      // Call OpenAI for strategic insights
      final response =
          await AIServiceBase.invokeAIFunction('openai-election-insights', {
            'election_id': electionId,
            'voting_data': votingData,
            'demographic_data': demographicData,
            'engagement_data': engagementData,
            'analysis_type': 'strategic_recommendations',
            'timestamp': DateTime.now().toIso8601String(),
          });

      AIServiceBase.validateResponse(response, ['recommendations']);

      // Store recommendations
      final recommendations = List<Map<String, dynamic>>.from(
        response['recommendations'],
      );
      for (final rec in recommendations) {
        await _supabase.from('strategic_recommendations').insert({
          'election_id': electionId,
          'creator_id': creatorId,
          'recommendation_type': rec['type'],
          'recommendation_text': rec['text'],
          'confidence_score': rec['confidence'] ?? 0.0,
          'metadata': rec['metadata'] ?? {},
        });
      }

      return recommendations;
    } catch (e) {
      debugPrint('Generate recommendations error: $e');
      return [];
    }
  }

  /// Get stored recommendations
  Future<List<Map<String, dynamic>>> getRecommendations(
    String electionId,
  ) async {
    try {
      final response = await _supabase
          .from('strategic_recommendations')
          .select()
          .eq('election_id', electionId)
          .order('confidence_score', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get recommendations error: $e');
      return [];
    }
  }

  // =====================================================
  // VOTER ENGAGEMENT HEATMAP
  // =====================================================

  /// Get voter engagement heatmap
  Future<List<Map<String, dynamic>>> getEngagementHeatmap(
    String electionId,
  ) async {
    try {
      final response = await _supabase
          .from('voter_engagement_heatmap')
          .select()
          .eq('election_id', electionId)
          .order('intensity_score', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get engagement heatmap error: $e');
      return [];
    }
  }

  /// Get peak voting times
  Future<List<Map<String, dynamic>>> getPeakVotingTimes(
    String electionId,
  ) async {
    try {
      final response = await _supabase
          .from('voter_engagement_heatmap')
          .select()
          .eq('election_id', electionId)
          .order('intensity_score', ascending: false)
          .limit(5);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get peak voting times error: $e');
      return [];
    }
  }

  // =====================================================
  // DEMOGRAPHIC CORRELATION ANALYSIS
  // =====================================================

  /// Get demographic correlations
  Future<List<Map<String, dynamic>>> getDemographicCorrelations(
    String electionId,
  ) async {
    try {
      final response = await _supabase
          .from('demographic_correlations')
          .select()
          .eq('election_id', electionId)
          .order('engagement_rate', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get demographic correlations error: $e');
      return [];
    }
  }

  // =====================================================
  // HISTORICAL COMPARISONS
  // =====================================================

  /// Get historical comparisons
  Future<List<Map<String, dynamic>>> getHistoricalComparisons(
    String electionId,
  ) async {
    try {
      final response = await _supabase
          .from('election_historical_comparisons')
          .select()
          .eq('election_id', electionId)
          .order('variance_percentage', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get historical comparisons error: $e');
      return [];
    }
  }

  // =====================================================
  // EXPORT FUNCTIONALITY
  // =====================================================

  /// Generate shareable insights report
  Future<Map<String, dynamic>> generateShareableReport(
    String electionId,
  ) async {
    try {
      final predictions = await getPredictions(electionId);
      final trends = await getVotingTrends(electionId);
      final demographics = await getDemographicBreakdown(electionId);
      final recommendations = await getRecommendations(electionId);

      return {
        'election_id': electionId,
        'generated_at': DateTime.now().toIso8601String(),
        'predictions': predictions,
        'trends': trends,
        'demographics': demographics,
        'recommendations': recommendations,
      };
    } catch (e) {
      debugPrint('Generate shareable report error: $e');
      return {};
    }
  }

  // =====================================================
  // PRIVATE HELPERS
  // =====================================================

  Future<Map<String, dynamic>> _getElectionVotingData(String electionId) async {
    try {
      final response = await _supabase
          .from('votes')
          .select()
          .eq('election_id', electionId);

      return {'votes': response, 'total_count': response.length};
    } catch (e) {
      debugPrint('Get election voting data error: $e');
      return {};
    }
  }

  Future<Map<String, dynamic>> _getDemographicData(String electionId) async {
    try {
      final demographics = await getDemographicBreakdown(electionId);
      return {'demographics': demographics};
    } catch (e) {
      debugPrint('Get demographic data error: $e');
      return {};
    }
  }

  Future<Map<String, dynamic>> _getEngagementData(String electionId) async {
    try {
      final heatmap = await getEngagementHeatmap(electionId);
      return {'engagement_heatmap': heatmap};
    } catch (e) {
      debugPrint('Get engagement data error: $e');
      return {};
    }
  }
}
