import './enhanced_notification_service.dart';
import './supabase_service.dart';

class VoteChangeService {
  static final VoteChangeService _instance = VoteChangeService._internal();
  factory VoteChangeService() => _instance;
  VoteChangeService._internal();

  final _supabase = SupabaseService.instance.client;
  final _notificationService = EnhancedNotificationService.instance;

  /// Check if election allows vote changes (Web parity: vote_editing_allowed).
  Future<bool> isVoteChangeAllowed(String electionId) async {
    try {
      final response = await _supabase
          .from('elections')
          .select('vote_editing_allowed')
          .eq('id', electionId)
          .single();
      return response['vote_editing_allowed'] ?? false;
    } catch (e) {
      try {
        final fallback = await _supabase
            .from('elections')
            .select('allow_vote_changes')
            .eq('id', electionId)
            .single();
        return fallback['allow_vote_changes'] ?? false;
      } catch (_) {
        return false;
      }
    }
  }

  /// Request vote change. Uses Web schema: vote_editing_allowed, vote_editing_requires_approval, vote_edit_history, vote_audit_markers.
  Future<Map<String, dynamic>> requestVoteChange({
    required String electionId,
    required String voterId,
    required Map<String, dynamic> originalVoteData,
    required Map<String, dynamic> newVoteData,
    String? changeReason,
  }) async {
    try {
      final changeAllowed = await isVoteChangeAllowed(electionId);

      if (!changeAllowed) {
        await _insertVoteAuditMarker(
            electionId: electionId, userId: voterId, reason: 'vote_change_attempt_disallowed');
        return {
          'success': false,
          'error': 'Vote changes are not allowed for this election. Your attempt has been recorded for audit.',
          'flagged': true,
        };
      }

      final election = await _supabase
          .from('elections')
          .select('vote_editing_requires_approval')
          .eq('id', electionId)
          .single();

      final requiresApproval = election['vote_editing_requires_approval'] ?? true;

      final voteRow = await _supabase
          .from('votes')
          .select('id')
          .eq('election_id', electionId)
          .eq('user_id', voterId)
          .single();

      final voteId = voteRow['id'] as String?;
      if (voteId == null) return {'success': false, 'error': 'Vote not found'};

      if (requiresApproval) {
        await _supabase.from('vote_edit_history').insert({
          'vote_id': voteId,
          'election_id': electionId,
          'user_id': voterId,
          'previous_vote_data': originalVoteData,
          'new_vote_data': newVoteData,
          'edit_reason': changeReason,
          'approval_status': 'pending',
        });
        return {
          'success': true,
          'status': 'pending',
          'message': 'Vote change request submitted. Awaiting creator approval.',
        };
      }

      await _supabase.from('votes').update({
        'selected_option_id': newVoteData['selectedOptionId'],
        'ranked_choices': newVoteData['rankedChoices'] ?? [],
        'selected_options': newVoteData['selectedOptions'] ?? [],
        'vote_scores': newVoteData['voteScores'] ?? {},
      }).eq('id', voteId);
      return {'success': true, 'status': 'updated'};
    } catch (e) {
      print('Error requesting vote change: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<void> _insertVoteAuditMarker({
    required String electionId,
    required String userId,
    required String reason,
  }) async {
    try {
      await _supabase.from('vote_audit_markers').insert({
        'election_id': electionId,
        'user_id': userId,
        'reason': reason,
      });
    } catch (e) {
      print('Error inserting vote_audit_marker: $e');
    }
  }

  /// Approve vote change (creator action). Web schema: vote_edit_history.
  Future<Map<String, dynamic>> approveVoteChange(
    String requestId,
    String reviewerId,
  ) async {
    try {
      final request = await _supabase
          .from('vote_edit_history')
          .select('vote_id, election_id, user_id, new_vote_data')
          .eq('id', requestId)
          .single();
      final newData = request['new_vote_data'] as Map<String, dynamic>? ?? {};
      await _supabase.from('votes').update({
        'selected_option_id': newData['selectedOptionId'],
        'ranked_choices': newData['rankedChoices'] ?? [],
        'selected_options': newData['selectedOptions'] ?? [],
        'vote_scores': newData['voteScores'] ?? {},
      }).eq('id', request['vote_id']);
      await _supabase.from('vote_edit_history').update({
        'approval_status': 'approved',
        'approved_by': reviewerId,
      }).eq('id', requestId);
      final userId = request['user_id'] as String?;
      if (userId != null) {
        await _notificationService.sendNotification(
          userId: userId,
          title: 'Vote Change Approved',
          body: 'Your vote change request has been approved by the election creator.',
          category: 'vote_change',
          priority: 'high',
        );
      }
      return {'success': true, 'message': 'Vote change approved successfully'};
    } catch (e) {
      print('Error approving vote change: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Reject vote change (creator action).
  Future<Map<String, dynamic>> rejectVoteChange(
    String requestId,
    String reviewerId,
  ) async {
    try {
      final request = await _supabase
          .from('vote_edit_history')
          .select('user_id')
          .eq('id', requestId)
          .single();
      await _supabase.from('vote_edit_history').update({
        'approval_status': 'rejected',
        'approved_by': reviewerId,
      }).eq('id', requestId);
      final userId = request['user_id'] as String?;
      if (userId != null) {
        await _notificationService.sendNotification(
          userId: userId,
          title: 'Vote Change Rejected',
          body: 'Your vote change request has been rejected by the election creator.',
          category: 'vote_change',
          priority: 'high',
        );
      }
      return {'success': true, 'message': 'Vote change rejected'};
    } catch (e) {
      print('Error rejecting vote change: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Get pending vote change requests for creator (vote_edit_history).
  Future<List<Map<String, dynamic>>> getPendingChangeRequests(
    String electionId,
  ) async {
    try {
      final response = await _supabase
          .from('vote_edit_history')
          .select()
          .eq('election_id', electionId)
          .eq('approval_status', 'pending')
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching pending change requests: $e');
      return [];
    }
  }

  /// Get vote change history for election (vote_edit_history).
  Future<List<Map<String, dynamic>>> getVoteChangeHistory(
    String electionId,
  ) async {
    try {
      final response = await _supabase
          .from('vote_edit_history')
          .select('*')
          .eq('election_id', electionId)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching vote change history: $e');
      return [];
    }
  }

  /// Get vote change analytics for creator.
  Future<Map<String, dynamic>> getVoteChangeAnalytics(String electionId) async {
    try {
      final historyResponse = await _supabase
          .from('vote_edit_history')
          .select('id')
          .eq('election_id', electionId);
      final pendingResponse = await _supabase
          .from('vote_edit_history')
          .select('id')
          .eq('election_id', electionId)
          .eq('approval_status', 'pending');
      return {
        'total_changes': historyResponse.length,
        'pending_requests': pendingResponse.length,
        'change_rate': historyResponse.isNotEmpty ? (historyResponse.length / 100.0) : 0.0,
      };
    } catch (e) {
      return {'total_changes': 0, 'pending_requests': 0, 'change_rate': 0.0};
    }
  }

  /// Get audit markers for election (vote_audit_markers). Web parity.
  Future<List<Map<String, dynamic>>> getAuditFlags(String electionId) async {
    try {
      final response = await _supabase
          .from('vote_audit_markers')
          .select('*, user_profiles(name, email)')
          .eq('election_id', electionId)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching audit markers: $e');
      return [];
    }
  }
}
