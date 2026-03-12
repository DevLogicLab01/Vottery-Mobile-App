import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import './auth_service.dart';
import './supabase_service.dart';

/// Service for managing audience questions with voting and moderation
class AudienceQuestionsService {
  static AudienceQuestionsService? _instance;
  static AudienceQuestionsService get instance =>
      _instance ??= AudienceQuestionsService._();

  AudienceQuestionsService._();

  SupabaseClient get _client => SupabaseService.instance.client;
  AuthService get _auth => AuthService.instance;

  /// Submit a question
  Future<bool> submitQuestion({
    required String electionId,
    required String questionText,
    bool isAnonymous = false,
  }) async {
    try {
      if (!_auth.isAuthenticated) return false;

      await _client.from('audience_questions').insert({
        'election_id': electionId,
        'submitted_by': _auth.currentUser!.id,
        'question_text': questionText,
        'is_anonymous': isAnonymous,
        'moderation_status': 'pending',
      });

      return true;
    } catch (e) {
      debugPrint('Submit question error: $e');
      return false;
    }
  }

  /// Get questions for an election
  Future<List<Map<String, dynamic>>> getQuestions({
    required String electionId,
    String sortBy = 'votes',
    String? statusFilter,
  }) async {
    try {
      var query = _client
          .from('audience_questions')
          .select(
            '*, submitter:user_profiles!submitted_by(id, full_name, avatar_url), answers:question_answers(*, answerer:user_profiles!answered_by(full_name))',
          )
          .eq('election_id', electionId);

      if (statusFilter != null) {
        query = query.eq('moderation_status', statusFilter);
      }

      dynamic transformedQuery = query;
      if (sortBy == 'votes') {
        transformedQuery = query.order('upvotes', ascending: false);
      } else if (sortBy == 'recent') {
        transformedQuery = query.order('created_at', ascending: false);
      }

      final response = await transformedQuery;
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get questions error: $e');
      return [];
    }
  }

  /// Get user's submitted questions
  Future<List<Map<String, dynamic>>> getMyQuestions() async {
    try {
      if (!_auth.isAuthenticated) return [];

      final response = await _client
          .from('audience_questions')
          .select(
            '*, election:elections(title), answers:question_answers(answer_text, created_at)',
          )
          .eq('submitted_by', _auth.currentUser!.id)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get my questions error: $e');
      return [];
    }
  }

  /// Vote on a question
  Future<bool> voteQuestion({
    required String questionId,
    required String voteType,
  }) async {
    try {
      if (!_auth.isAuthenticated) return false;

      await _client.from('question_votes').upsert({
        'question_id': questionId,
        'user_id': _auth.currentUser!.id,
        'vote_type': voteType,
      }, onConflict: 'question_id,user_id');

      return true;
    } catch (e) {
      debugPrint('Vote question error: $e');
      return false;
    }
  }

  /// Remove vote from a question
  Future<bool> removeVote({required String questionId}) async {
    try {
      if (!_auth.isAuthenticated) return false;

      await _client
          .from('question_votes')
          .delete()
          .eq('question_id', questionId)
          .eq('user_id', _auth.currentUser!.id);

      return true;
    } catch (e) {
      debugPrint('Remove vote error: $e');
      return false;
    }
  }

  /// Get user's vote on a question
  Future<String?> getUserVote({required String questionId}) async {
    try {
      if (!_auth.isAuthenticated) return null;

      final response = await _client
          .from('question_votes')
          .select('vote_type')
          .eq('question_id', questionId)
          .eq('user_id', _auth.currentUser!.id)
          .maybeSingle();

      return response?['vote_type'] as String?;
    } catch (e) {
      debugPrint('Get user vote error: $e');
      return null;
    }
  }

  /// Moderate a question (approve/reject/flag)
  Future<bool> moderateQuestion({
    required String questionId,
    required String action,
    String? reason,
  }) async {
    try {
      if (!_auth.isAuthenticated) return false;

      await _client
          .from('audience_questions')
          .update({
            'moderation_status': action,
            'moderated_by': _auth.currentUser!.id,
            'moderated_at': DateTime.now().toIso8601String(),
            'moderator_notes': reason,
          })
          .eq('id', questionId);

      await _client.from('question_moderation_logs').insert({
        'question_id': questionId,
        'moderator_id': _auth.currentUser!.id,
        'action': action,
        'reason': reason,
      });

      return true;
    } catch (e) {
      debugPrint('Moderate question error: $e');
      return false;
    }
  }

  /// Answer a question
  Future<bool> answerQuestion({
    required String questionId,
    required String answerText,
    bool isLive = false,
  }) async {
    try {
      if (!_auth.isAuthenticated) return false;

      await _client.from('question_answers').insert({
        'question_id': questionId,
        'answered_by': _auth.currentUser!.id,
        'answer_text': answerText,
        'is_live': isLive,
      });

      return true;
    } catch (e) {
      debugPrint('Answer question error: $e');
      return false;
    }
  }

  /// Subscribe to questions real-time updates
  RealtimeChannel subscribeToQuestions({
    required String electionId,
    required Function(Map<String, dynamic>) onQuestionAdded,
    Function(Map<String, dynamic>)? onQuestionUpdated,
  }) {
    final channel = _client
        .channel('audience_questions_$electionId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'audience_questions',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'election_id',
            value: electionId,
          ),
          callback: (payload) {
            onQuestionAdded(payload.newRecord);
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'audience_questions',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'election_id',
            value: electionId,
          ),
          callback: (payload) {
            if (onQuestionUpdated != null) {
              onQuestionUpdated(payload.newRecord);
            }
          },
        )
        .subscribe();

    return channel;
  }

  /// Get pending questions count for creator
  Future<int> getPendingQuestionsCount({required String electionId}) async {
    try {
      final response = await _client
          .from('audience_questions')
          .select('id')
          .eq('election_id', electionId)
          .eq('moderation_status', 'pending');

      return response.length;
    } catch (e) {
      debugPrint('Get pending questions count error: $e');
      return 0;
    }
  }
}
