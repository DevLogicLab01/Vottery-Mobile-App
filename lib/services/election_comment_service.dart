import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import './auth_service.dart';
import './supabase_service.dart';

/// Service for managing election comments with threading, moderation, and real-time updates
class ElectionCommentService {
  static ElectionCommentService? _instance;
  static ElectionCommentService get instance =>
      _instance ??= ElectionCommentService._();

  ElectionCommentService._();

  SupabaseClient get _client => SupabaseService.instance.client;
  AuthService get _auth => AuthService.instance;

  /// Get comments for an election with pagination
  Future<List<Map<String, dynamic>>> getElectionComments({
    required String electionId,
    String sortBy = 'newest',
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      var query = _client
          .from('election_comments')
          .select(
            '*, user:user_profiles!user_id(id, full_name, avatar_url), reply_count:election_comments!parent_comment_id(count)',
          )
          .eq('election_id', electionId)
          .eq('is_deleted', false)
          .eq('is_approved', true)
          .isFilter('parent_comment_id', null);

      // Apply sorting
      dynamic transformedQuery = query;
      if (sortBy == 'newest') {
        transformedQuery = query.order('created_at', ascending: false);
      } else if (sortBy == 'oldest') {
        transformedQuery = query.order('created_at', ascending: true);
      } else if (sortBy == 'top') {
        transformedQuery = query.order('upvote_count', ascending: false);
      } else if (sortBy == 'controversial') {
        // Sort by highest total votes (upvotes + downvotes)
        transformedQuery = query.order('upvote_count', ascending: false);
      }

      transformedQuery = transformedQuery.range(offset, offset + limit - 1);

      final response = await transformedQuery;
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get election comments error: $e');
      return [];
    }
  }

  /// Get replies for a comment
  Future<List<Map<String, dynamic>>> getCommentReplies({
    required String commentId,
    int limit = 20,
  }) async {
    try {
      final response = await _client
          .from('election_comments')
          .select('*, user:user_profiles!user_id(id, full_name, avatar_url)')
          .eq('parent_comment_id', commentId)
          .eq('is_deleted', false)
          .eq('is_approved', true)
          .order('created_at', ascending: true)
          .limit(limit);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get comment replies error: $e');
      return [];
    }
  }

  /// Post a comment
  Future<bool> postComment({
    required String electionId,
    required String commentText,
    String? parentCommentId,
  }) async {
    try {
      if (!_auth.isAuthenticated) return false;

      // Calculate depth level
      int depthLevel = 0;
      if (parentCommentId != null) {
        final parentComment = await _client
            .from('election_comments')
            .select('depth_level')
            .eq('id', parentCommentId)
            .maybeSingle();

        if (parentComment != null) {
          depthLevel = (parentComment['depth_level'] as int? ?? 0) + 1;
        }
      }

      // Check max depth (3 levels)
      if (depthLevel > 3) {
        debugPrint('Max comment depth reached');
        return false;
      }

      // Check if comments are enabled for this election
      final election = await _client
          .from('elections')
          .select('comments_enabled')
          .eq('id', electionId)
          .maybeSingle();

      if (election == null || election['comments_enabled'] == false) {
        debugPrint('Comments disabled for this election');
        return false;
      }

      await _client.from('election_comments').insert({
        'election_id': electionId,
        'user_id': _auth.currentUser!.id,
        'comment_text': commentText,
        'parent_comment_id': parentCommentId,
        'depth_level': depthLevel,
      });

      return true;
    } catch (e) {
      debugPrint('Post comment error: $e');
      return false;
    }
  }

  /// Edit a comment (within 15 minutes)
  Future<bool> editComment({
    required String commentId,
    required String newText,
  }) async {
    try {
      if (!_auth.isAuthenticated) return false;

      final comment = await _client
          .from('election_comments')
          .select('user_id, created_at')
          .eq('id', commentId)
          .maybeSingle();

      if (comment == null) return false;

      // Check ownership
      if (comment['user_id'] != _auth.currentUser!.id) return false;

      // Check 15-minute edit window
      final createdAt = DateTime.parse(comment['created_at'] as String);
      final now = DateTime.now();
      if (now.difference(createdAt).inMinutes > 15) {
        debugPrint('Edit window expired');
        return false;
      }

      await _client
          .from('election_comments')
          .update({
            'comment_text': newText,
            'is_edited': true,
            'edited_at': DateTime.now().toIso8601String(),
          })
          .eq('id', commentId);

      return true;
    } catch (e) {
      debugPrint('Edit comment error: $e');
      return false;
    }
  }

  /// Delete a comment (soft delete)
  Future<bool> deleteComment(String commentId) async {
    try {
      if (!_auth.isAuthenticated) return false;

      final comment = await _client
          .from('election_comments')
          .select('user_id, created_at')
          .eq('id', commentId)
          .maybeSingle();

      if (comment == null) return false;

      // Check ownership
      if (comment['user_id'] != _auth.currentUser!.id) return false;

      // Check 15-minute delete window
      final createdAt = DateTime.parse(comment['created_at'] as String);
      final now = DateTime.now();
      if (now.difference(createdAt).inMinutes > 15) {
        debugPrint('Delete window expired');
        return false;
      }

      await _client
          .from('election_comments')
          .update({
            'is_deleted': true,
            'deleted_at': DateTime.now().toIso8601String(),
          })
          .eq('id', commentId);

      return true;
    } catch (e) {
      debugPrint('Delete comment error: $e');
      return false;
    }
  }

  /// Vote on a comment
  Future<bool> voteComment({
    required String commentId,
    required String voteType, // 'upvote' or 'downvote'
  }) async {
    try {
      if (!_auth.isAuthenticated) return false;

      // Check if user already voted
      final existingVote = await _client
          .from('election_comment_votes')
          .select('vote_type')
          .eq('comment_id', commentId)
          .eq('user_id', _auth.currentUser!.id)
          .maybeSingle();

      if (existingVote != null) {
        // Remove vote if same type, otherwise update
        if (existingVote['vote_type'] == voteType) {
          await _client
              .from('election_comment_votes')
              .delete()
              .eq('comment_id', commentId)
              .eq('user_id', _auth.currentUser!.id);
        } else {
          await _client
              .from('election_comment_votes')
              .update({'vote_type': voteType})
              .eq('comment_id', commentId)
              .eq('user_id', _auth.currentUser!.id);
        }
      } else {
        // Insert new vote
        await _client.from('election_comment_votes').insert({
          'comment_id': commentId,
          'user_id': _auth.currentUser!.id,
          'vote_type': voteType,
        });
      }

      // Update vote counts
      await _updateCommentVoteCounts(commentId);

      return true;
    } catch (e) {
      debugPrint('Vote comment error: $e');
      return false;
    }
  }

  /// Flag a comment
  Future<bool> flagComment({
    required String commentId,
    required String reason,
  }) async {
    try {
      if (!_auth.isAuthenticated) return false;

      await _client
          .from('election_comments')
          .update({
            'is_flagged': true,
            'flag_reason': reason,
            'flagged_at': DateTime.now().toIso8601String(),
          })
          .eq('id', commentId);

      return true;
    } catch (e) {
      debugPrint('Flag comment error: $e');
      return false;
    }
  }

  /// Moderate comment (creator only)
  Future<bool> moderateComment({
    required String commentId,
    required String electionId,
    required bool approve,
  }) async {
    try {
      if (!_auth.isAuthenticated) return false;

      // Check if user is election creator
      final election = await _client
          .from('elections')
          .select('created_by')
          .eq('id', electionId)
          .maybeSingle();

      if (election == null || election['created_by'] != _auth.currentUser!.id) {
        return false;
      }

      await _client
          .from('election_comments')
          .update({
            'is_approved': approve,
            'approved_by': _auth.currentUser!.id,
            'approved_at': DateTime.now().toIso8601String(),
          })
          .eq('id', commentId);

      return true;
    } catch (e) {
      debugPrint('Moderate comment error: $e');
      return false;
    }
  }

  /// Get moderation queue for election creator
  Future<List<Map<String, dynamic>>> getModerationQueue(
    String electionId,
  ) async {
    try {
      if (!_auth.isAuthenticated) return [];

      // Check if user is election creator
      final election = await _client
          .from('elections')
          .select('created_by')
          .eq('id', electionId)
          .maybeSingle();

      if (election == null || election['created_by'] != _auth.currentUser!.id) {
        return [];
      }

      final response = await _client
          .from('election_comments')
          .select('*, user:user_profiles!user_id(id, full_name, avatar_url)')
          .eq('election_id', electionId)
          .eq('is_approved', false)
          .eq('is_deleted', false)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get moderation queue error: $e');
      return [];
    }
  }

  /// Subscribe to comment updates
  RealtimeChannel subscribeToComments({
    required String electionId,
    required Function(Map<String, dynamic>) onCommentAdded,
  }) {
    return _client
        .channel('election_comments:$electionId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'election_comments',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'election_id',
            value: electionId,
          ),
          callback: (payload) {
            onCommentAdded(payload.newRecord);
          },
        )
        .subscribe();
  }

  /// Update comment vote counts
  Future<void> _updateCommentVoteCounts(String commentId) async {
    try {
      final votes = await _client
          .from('election_comment_votes')
          .select('vote_type')
          .eq('comment_id', commentId);

      int upvotes = 0;
      int downvotes = 0;

      for (var vote in votes) {
        if (vote['vote_type'] == 'upvote') {
          upvotes++;
        } else if (vote['vote_type'] == 'downvote') {
          downvotes++;
        }
      }

      await _client
          .from('election_comments')
          .update({'upvote_count': upvotes, 'downvote_count': downvotes})
          .eq('id', commentId);
    } catch (e) {
      debugPrint('Update comment vote counts error: $e');
    }
  }
}
