import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import './auth_service.dart';
import './supabase_service.dart';

class VerificationAuditService {
  static VerificationAuditService? _instance;
  static VerificationAuditService get instance =>
      _instance ??= VerificationAuditService._();

  VerificationAuditService._();

  SupabaseClient get _client => SupabaseService.instance.client;
  AuthService get _auth => AuthService.instance;

  /// Get user's voting history for verification
  Future<List<Map<String, dynamic>>> getVotingHistory() async {
    try {
      if (!_auth.isAuthenticated) return [];

      final response = await _client
          .from('votes')
          .select('*, elections(*), election_options(*)')
          .eq('user_id', _auth.currentUser!.id)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get voting history error: $e');
      return [];
    }
  }

  /// Submit verification request for selected elections
  Future<String?> submitVerificationRequest(List<String> electionIds) async {
    try {
      if (!_auth.isAuthenticated) return null;

      final response = await _client
          .from('verification_requests')
          .insert({
            'user_id': _auth.currentUser!.id,
            'election_ids': electionIds,
            'verification_status': 'pending',
          })
          .select()
          .single();

      // Process verification immediately
      await _processVerification(response['id'] as String, electionIds);

      return response['id'] as String;
    } catch (e) {
      debugPrint('Submit verification request error: $e');
      return null;
    }
  }

  /// Process verification (check blockchain hashes)
  Future<void> _processVerification(
    String requestId,
    List<String> electionIds,
  ) async {
    try {
      final results = <String, dynamic>{};

      for (final electionId in electionIds) {
        final vote = await _client
            .from('votes')
            .select('*, blockchain_audit_log(*)')
            .eq('election_id', electionId)
            .eq('user_id', _auth.currentUser!.id)
            .maybeSingle();

        if (vote != null) {
          final voteHash = vote['vote_hash'] as String?;
          final blockchainHash = vote['blockchain_hash'] as String?;

          // Check if blockchain audit log exists
          final auditLog = await _client
              .from('blockchain_audit_log')
              .select()
              .eq('vote_id', vote['id'])
              .maybeSingle();

          results[electionId] = {
            'status': auditLog != null ? 'verified' : 'failed',
            'vote_hash': voteHash,
            'blockchain_hash': blockchainHash,
            'block_number': auditLog?['block_number'],
            'transaction_hash': auditLog?['transaction_hash'],
            'verification_status': auditLog?['verification_status'],
          };
        } else {
          results[electionId] = {
            'status': 'not_found',
            'message': 'No vote found for this election',
          };
        }
      }

      // Update verification request with results
      await _client
          .from('verification_requests')
          .update({
            'verification_status': 'completed',
            'verification_results': results,
            'completed_at': DateTime.now().toIso8601String(),
          })
          .eq('id', requestId);
    } catch (e) {
      debugPrint('Process verification error: $e');
    }
  }

  /// Get verification request by ID
  Future<Map<String, dynamic>?> getVerificationRequest(String requestId) async {
    try {
      final response = await _client
          .from('verification_requests')
          .select()
          .eq('id', requestId)
          .maybeSingle();

      return response;
    } catch (e) {
      debugPrint('Get verification request error: $e');
      return null;
    }
  }

  /// Get blockchain audit log for vote
  Future<Map<String, dynamic>?> getBlockchainAuditLog(String voteId) async {
    try {
      final response = await _client
          .from('blockchain_audit_log')
          .select()
          .eq('vote_id', voteId)
          .maybeSingle();

      return response;
    } catch (e) {
      debugPrint('Get blockchain audit log error: $e');
      return null;
    }
  }

  /// Generate audit report for election
  Future<String?> generateAuditReport(String electionId) async {
    try {
      if (!_auth.isAuthenticated) return null;

      // Get election data
      final election = await _client
          .from('elections')
          .select('*, votes(*), blockchain_audit_log(*)')
          .eq('id', electionId)
          .maybeSingle();

      if (election == null) return null;

      // Generate report data
      final reportData = {
        'election_title': election['title'],
        'total_votes': (election['votes'] as List).length,
        'verified_votes': (election['blockchain_audit_log'] as List)
            .where((log) => log['verification_status'] == 'verified')
            .length,
        'audit_timeline': election['blockchain_audit_log'],
        'generated_at': DateTime.now().toIso8601String(),
      };

      // Save audit report
      final response = await _client
          .from('audit_reports')
          .insert({
            'election_id': electionId,
            'generated_by': _auth.currentUser!.id,
            'report_type': 'comprehensive',
            'report_data': reportData,
          })
          .select()
          .single();

      return response['id'] as String;
    } catch (e) {
      debugPrint('Generate audit report error: $e');
      return null;
    }
  }

  /// Get audit report by ID
  Future<Map<String, dynamic>?> getAuditReport(String reportId) async {
    try {
      final response = await _client
          .from('audit_reports')
          .select()
          .eq('id', reportId)
          .maybeSingle();

      return response;
    } catch (e) {
      debugPrint('Get audit report error: $e');
      return null;
    }
  }

  /// Get all audit reports for election
  Future<List<Map<String, dynamic>>> getElectionAuditReports(
    String electionId,
  ) async {
    try {
      final response = await _client
          .from('audit_reports')
          .select()
          .eq('election_id', electionId)
          .order('generated_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get election audit reports error: $e');
      return [];
    }
  }
}
