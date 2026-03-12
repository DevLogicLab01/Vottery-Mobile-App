import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import './auth_service.dart';
import './supabase_service.dart';

/// Service for managing election social reactions with emoji support
class ElectionReactionService {
  static ElectionReactionService? _instance;
  static ElectionReactionService get instance =>
      _instance ??= ElectionReactionService._();

  ElectionReactionService._();

  SupabaseClient get _client => SupabaseService.instance.client;
  AuthService get _auth => AuthService.instance;

  static const List<Map<String, String>> availableReactions = [
    {'type': 'like', 'emoji': '👍', 'name': 'Like'},
    {'type': 'love', 'emoji': '❤️', 'name': 'Love'},
    {'type': 'wow', 'emoji': '😮', 'name': 'Wow'},
    {'type': 'angry', 'emoji': '😠', 'name': 'Angry'},
    {'type': 'sad', 'emoji': '😢', 'name': 'Sad'},
    {'type': 'celebrate', 'emoji': '🎉', 'name': 'Celebrate'},
  ];

  /// Get reaction counts for an election
  Future<Map<String, dynamic>?> getReactionCounts(String electionId) async {
    try {
      final response = await _client
          .from('election_reaction_counts')
          .select('*')
          .eq('election_id', electionId)
          .maybeSingle();

      return response;
    } catch (e) {
      debugPrint('Get reaction counts error: $e');
      return null;
    }
  }

  /// Get user's reaction for an election
  Future<String?> getUserReaction(String electionId) async {
    try {
      if (!_auth.isAuthenticated) return null;

      final response = await _client
          .from('election_reactions')
          .select('reaction_type')
          .eq('election_id', electionId)
          .eq('user_id', _auth.currentUser!.id)
          .maybeSingle();

      return response?['reaction_type'] as String?;
    } catch (e) {
      debugPrint('Get user reaction error: $e');
      return null;
    }
  }

  /// Add or update reaction
  Future<bool> reactToElection({
    required String electionId,
    required String reactionType,
  }) async {
    try {
      if (!_auth.isAuthenticated) return false;

      // Validate reaction type
      if (!availableReactions.any((r) => r['type'] == reactionType)) {
        debugPrint('Invalid reaction type: $reactionType');
        return false;
      }

      // Check if user already reacted
      final existingReaction = await _client
          .from('election_reactions')
          .select('reaction_type')
          .eq('election_id', electionId)
          .eq('user_id', _auth.currentUser!.id)
          .maybeSingle();

      if (existingReaction != null) {
        // If same reaction, remove it
        if (existingReaction['reaction_type'] == reactionType) {
          await _client
              .from('election_reactions')
              .delete()
              .eq('election_id', electionId)
              .eq('user_id', _auth.currentUser!.id);
        } else {
          // Update to new reaction
          await _client
              .from('election_reactions')
              .update({'reaction_type': reactionType})
              .eq('election_id', electionId)
              .eq('user_id', _auth.currentUser!.id);
        }
      } else {
        // Insert new reaction
        await _client.from('election_reactions').insert({
          'election_id': electionId,
          'user_id': _auth.currentUser!.id,
          'reaction_type': reactionType,
        });
      }

      return true;
    } catch (e) {
      debugPrint('React to election error: $e');
      return false;
    }
  }

  /// Remove reaction
  Future<bool> removeReaction(String electionId) async {
    try {
      if (!_auth.isAuthenticated) return false;

      await _client
          .from('election_reactions')
          .delete()
          .eq('election_id', electionId)
          .eq('user_id', _auth.currentUser!.id);

      return true;
    } catch (e) {
      debugPrint('Remove reaction error: $e');
      return false;
    }
  }

  /// Get users who reacted with specific type
  Future<List<Map<String, dynamic>>> getUsersByReaction({
    required String electionId,
    required String reactionType,
    int limit = 50,
  }) async {
    try {
      final response = await _client
          .from('election_reactions')
          .select('user:user_profiles!user_id(id, full_name, avatar_url)')
          .eq('election_id', electionId)
          .eq('reaction_type', reactionType)
          .limit(limit);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get users by reaction error: $e');
      return [];
    }
  }

  /// Subscribe to reaction updates
  RealtimeChannel subscribeToReactions({
    required String electionId,
    required Function() onReactionChanged,
  }) {
    return _client
        .channel('election_reactions:$electionId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'election_reactions',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'election_id',
            value: electionId,
          ),
          callback: (payload) {
            onReactionChanged();
          },
        )
        .subscribe();
  }
}
