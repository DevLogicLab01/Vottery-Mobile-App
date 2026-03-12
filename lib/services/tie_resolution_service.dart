import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import './auth_service.dart';
import './supabase_service.dart';
import './enhanced_notification_service.dart';

/// Service for managing tie handling and resolution workflows
class TieResolutionService {
  static TieResolutionService? _instance;
  static TieResolutionService get instance =>
      _instance ??= TieResolutionService._();

  TieResolutionService._();

  SupabaseClient get _client => SupabaseService.instance.client;
  AuthService get _auth => AuthService.instance;
  EnhancedNotificationService get _notificationService =>
      EnhancedNotificationService.instance;

  /// Detect ties in election results
  Future<bool> detectElectionTie(String electionId) async {
    try {
      final response = await _client.rpc(
        'detect_election_tie',
        params: {'p_election_id': electionId},
      );

      return response as bool? ?? false;
    } catch (e) {
      debugPrint('Detect election tie error: $e');
      return false;
    }
  }

  /// Get tie result for an election
  Future<Map<String, dynamic>?> getTieResult(String electionId) async {
    try {
      final response = await _client
          .from('tie_results')
          .select()
          .eq('election_id', electionId)
          .maybeSingle();

      return response;
    } catch (e) {
      debugPrint('Get tie result error: $e');
      return null;
    }
  }

  /// Get all active ties
  Future<List<Map<String, dynamic>>> getActiveTies() async {
    try {
      final response = await _client
          .from('tie_results')
          .select('*, election:elections(*)')
          .eq('resolution_status', 'unresolved')
          .order('detected_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get active ties error: $e');
      return [];
    }
  }

  /// Get tie analytics
  Future<List<Map<String, dynamic>>> getTieAnalytics() async {
    try {
      final response = await _client
          .from('tie_analytics')
          .select()
          .order('total_ties', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get tie analytics error: $e');
      return [];
    }
  }

  /// Create runoff election from tie
  Future<String?> createRunoffElection({
    required String originalElectionId,
    required String tieResultId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      if (!_auth.isAuthenticated) return null;

      // Get original election details
      final originalElection = await _client
          .from('elections')
          .select()
          .eq('id', originalElectionId)
          .single();

      // Get tied candidates
      final tieResult = await _client
          .from('tie_results')
          .select()
          .eq('id', tieResultId)
          .single();

      final tiedCandidates = List<Map<String, dynamic>>.from(
        tieResult['tied_candidates'],
      );

      // Create runoff election
      final runoffElection = await _client
          .from('elections')
          .insert({
            'title': '${originalElection['title']} - Runoff Election',
            'description':
                'Runoff election to resolve tie from original election',
            'creator_id': _auth.currentUser!.id,
            'voting_method': originalElection['voting_method'],
            'start_date': startDate.toIso8601String(),
            'end_date': endDate.toIso8601String(),
            'status': 'scheduled',
            'is_lottery': originalElection['is_lottery'] ?? false,
            'participation_fee': originalElection['participation_fee'] ?? 0,
            'allow_anonymous_voting':
                originalElection['allow_anonymous_voting'] ?? false,
            'allow_vote_changes':
                originalElection['allow_vote_changes'] ?? false,
          })
          .select()
          .single();

      final runoffElectionId = runoffElection['id'];

      // Create election options from tied candidates
      for (var i = 0; i < tiedCandidates.length; i++) {
        await _client.from('election_options').insert({
          'election_id': runoffElectionId,
          'option_text': tiedCandidates[i]['option_title'],
          'display_order': i,
        });
      }

      // Update tie result with runoff election ID
      await _client
          .from('tie_results')
          .update({
            'runoff_election_id': runoffElectionId,
            'resolution_status': 'runoff_scheduled',
            'resolution_method': 'runoff',
          })
          .eq('id', tieResultId);

      // Update tie analytics
      await _client.rpc(
        'update_tie_analytics',
        params: {
          'p_voting_method': originalElection['voting_method'],
          'p_resolution_type': 'runoff',
        },
      );

      // Send notifications to original participants
      await _notifyRunoffParticipants(
        originalElectionId,
        runoffElectionId,
        originalElection['title'],
      );

      return runoffElectionId;
    } catch (e) {
      debugPrint('Create runoff election error: $e');
      return null;
    }
  }

  /// Manually resolve tie
  Future<bool> manuallyResolveTie({
    required String tieResultId,
    required String winnerOptionId,
    required String justification,
  }) async {
    try {
      if (!_auth.isAuthenticated) return false;

      await _client
          .from('tie_results')
          .update({
            'manual_winner_id': winnerOptionId,
            'manual_justification': justification,
            'resolution_status': 'manual_override',
            'resolution_method': 'manual',
            'resolved_by': _auth.currentUser!.id,
            'resolved_at': DateTime.now().toIso8601String(),
          })
          .eq('id', tieResultId);

      return true;
    } catch (e) {
      debugPrint('Manually resolve tie error: $e');
      return false;
    }
  }

  /// Notify participants about runoff election
  Future<void> _notifyRunoffParticipants(
    String originalElectionId,
    String runoffElectionId,
    String electionTitle,
  ) async {
    try {
      // Get all voters from original election
      final voters = await _client
          .from('votes')
          .select('user_id')
          .eq('election_id', originalElectionId);

      final uniqueVoterIds = voters
          .map((v) => v['user_id'] as String)
          .toSet()
          .toList();

      // Send notification to each voter
      for (final voterId in uniqueVoterIds) {
        await _notificationService.sendNotification(
          userId: voterId,
          category: 'new_vote',
          priority: 'high',
          title: 'Runoff Election Scheduled',
          body:
              'A runoff election has been scheduled for "$electionTitle" due to a tie. Your vote is needed!',
          deepLink: '/vote-casting',
          deepLinkParams: {'electionId': runoffElectionId},
        );
      }
    } catch (e) {
      debugPrint('Notify runoff participants error: $e');
    }
  }

  /// Get tie prevention recommendations
  Future<Map<String, dynamic>> getTiePreventionRecommendations(
    String votingMethod,
    int candidateCount,
  ) async {
    try {
      // Get historical tie frequency for this voting method
      final analytics = await _client
          .from('tie_analytics')
          .select()
          .eq('voting_method', votingMethod)
          .maybeSingle();

      final tieFrequency = analytics?['total_ties'] ?? 0;

      // Generate recommendations
      final recommendations = <String, dynamic>{
        'likely_to_tie': false,
        'recommendation': '',
        'alternative_method': '',
        'confidence': 0.0,
      };

      // Simple heuristic: plurality voting with 2 candidates has high tie risk
      if (votingMethod == 'plurality' && candidateCount == 2) {
        recommendations['likely_to_tie'] = true;
        recommendations['recommendation'] =
            'Consider using approval voting or ranked choice voting to reduce tie probability';
        recommendations['alternative_method'] = 'approval';
        recommendations['confidence'] = 0.75;
      } else if (tieFrequency > 5) {
        recommendations['likely_to_tie'] = true;
        recommendations['recommendation'] =
            'This voting method has a history of ties. Consider alternative methods.';
        recommendations['alternative_method'] = 'ranked_choice';
        recommendations['confidence'] = 0.60;
      }

      return recommendations;
    } catch (e) {
      debugPrint('Get tie prevention recommendations error: $e');
      return {};
    }
  }
}
