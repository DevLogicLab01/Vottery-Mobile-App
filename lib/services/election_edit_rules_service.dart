import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import './auth_service.dart';
import './supabase_service.dart';

/// Election Edit/Delete Rules Engine Service
class ElectionEditRulesService {
  static ElectionEditRulesService? _instance;
  static ElectionEditRulesService get instance =>
      _instance ??= ElectionEditRulesService._();

  ElectionEditRulesService._();

  SupabaseClient get _client => SupabaseService.instance.client;
  AuthService get _auth => AuthService.instance;

  /// Check if election can be edited
  Future<Map<String, dynamic>> canEditElection(String electionId) async {
    try {
      final result = await _client.rpc(
        'can_edit_election',
        params: {'p_election_id': electionId},
      );

      return Map<String, dynamic>.from(result);
    } catch (e) {
      debugPrint('Can edit election error: $e');
      return {
        'can_edit': false,
        'can_edit_all_fields': false,
        'can_delete': false,
        'reason': 'Error checking edit permissions',
      };
    }
  }

  /// Update election with edit rules enforcement
  Future<Map<String, dynamic>> updateElection({
    required String electionId,
    required Map<String, dynamic> updates,
  }) async {
    try {
      if (!_auth.isAuthenticated) {
        throw Exception('User must be authenticated');
      }

      final userId = _auth.currentUser!.id;

      // Check edit permissions
      final permissions = await canEditElection(electionId);

      if (permissions['can_edit'] != true) {
        return {'success': false, 'error': permissions['reason']};
      }

      // Get current election data
      final currentElection = await _client
          .from('elections')
          .select()
          .eq('id', electionId)
          .single();

      // Validate allowed edits
      final canEditAllFields = permissions['can_edit_all_fields'] as bool;
      final allowedEdits = permissions['allowed_edits'] as List<dynamic>? ?? [];

      Map<String, dynamic> validatedUpdates = {};
      Map<String, dynamic> changedFields = {};
      Map<String, dynamic> previousValues = {};
      Map<String, dynamic> newValues = {};

      if (canEditAllFields) {
        // Pre-vote: all edits allowed
        validatedUpdates = updates;
        changedFields = updates;
        for (var key in updates.keys) {
          previousValues[key] = currentElection[key];
          newValues[key] = updates[key];
        }
      } else {
        // Post-vote: only specific edits allowed
        for (var key in updates.keys) {
          if (allowedEdits.contains(key)) {
            validatedUpdates[key] = updates[key];
            changedFields[key] = updates[key];
            previousValues[key] = currentElection[key];
            newValues[key] = updates[key];
          }
        }

        // Validate deadline extension
        if (validatedUpdates.containsKey('deadline')) {
          final currentDeadline = DateTime.parse(
            currentElection['deadline'] as String,
          );
          final newDeadline = DateTime.parse(
            validatedUpdates['deadline'] as String,
          );
          final maxExtensionMonths =
              currentElection['max_deadline_extension_months'] as int? ?? 6;

          final maxAllowedDeadline = DateTime(
            currentDeadline.year,
            currentDeadline.month + maxExtensionMonths,
            currentDeadline.day,
          );

          if (newDeadline.isAfter(maxAllowedDeadline)) {
            return {
              'success': false,
              'error':
                  'Deadline can only be extended up to $maxExtensionMonths months',
            };
          }
        }
      }

      if (validatedUpdates.isEmpty) {
        return {'success': false, 'error': 'No valid fields to update'};
      }

      // Update election
      await _client
          .from('elections')
          .update(validatedUpdates)
          .eq('id', electionId);

      // Log edit history
      await _client.from('election_edit_history').insert({
        'election_id': electionId,
        'edited_by': userId,
        'changed_fields': changedFields,
        'previous_values': previousValues,
        'new_values': newValues,
        'edit_type': canEditAllFields ? 'pre_vote' : 'post_vote',
      });

      return {
        'success': true,
        'updated_fields': validatedUpdates.keys.toList(),
      };
    } catch (e) {
      debugPrint('Update election error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Soft delete election
  Future<Map<String, dynamic>> deleteElection(String electionId) async {
    try {
      if (!_auth.isAuthenticated) {
        throw Exception('User must be authenticated');
      }

      final userId = _auth.currentUser!.id;

      // Check delete permissions
      final permissions = await canEditElection(electionId);

      if (permissions['can_delete'] != true) {
        return {
          'success': false,
          'error': 'Cannot delete election after votes have been cast',
        };
      }

      // Soft delete
      await _client
          .from('elections')
          .update({
            'is_deleted': true,
            'deleted_at': DateTime.now().toIso8601String(),
            'deleted_by': userId,
          })
          .eq('id', electionId);

      return {'success': true};
    } catch (e) {
      debugPrint('Delete election error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Admin override for edit/delete
  Future<Map<String, dynamic>> adminOverride({
    required String electionId,
    required String actionType,
    required String justification,
    required Map<String, dynamic> updates,
  }) async {
    try {
      if (!_auth.isAuthenticated) {
        throw Exception('User must be authenticated');
      }

      final userId = _auth.currentUser!.id;

      // Verify admin role
      final userProfile = await _client
          .from('user_profiles')
          .select('role')
          .eq('id', userId)
          .single();

      if (userProfile['role'] != 'admin') {
        return {'success': false, 'error': 'Admin privileges required'};
      }

      // Apply updates
      await _client.from('elections').update(updates).eq('id', electionId);

      // Log admin override
      await _client.from('election_admin_overrides').insert({
        'election_id': electionId,
        'admin_id': userId,
        'action_type': actionType,
        'justification': justification,
        'metadata': updates,
      });

      return {'success': true};
    } catch (e) {
      debugPrint('Admin override error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Get edit history for election
  Future<List<Map<String, dynamic>>> getEditHistory(String electionId) async {
    try {
      final response = await _client
          .from('election_edit_history')
          .select('*, user_profiles!edited_by(username, avatar_url)')
          .eq('election_id', electionId)
          .order('edited_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get edit history error: $e');
      return [];
    }
  }

  /// Get admin overrides for election
  Future<List<Map<String, dynamic>>> getAdminOverrides(
    String electionId,
  ) async {
    try {
      final response = await _client
          .from('election_admin_overrides')
          .select('*, user_profiles!admin_id(username, avatar_url)')
          .eq('election_id', electionId)
          .order('performed_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get admin overrides error: $e');
      return [];
    }
  }
}
