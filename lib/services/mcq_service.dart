import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import './auth_service.dart';
import './supabase_service.dart';
import '../services/openai_service.dart';

/// MCQ Service for election MCQ creation, answering, and validation
class MCQService {
  static MCQService? _instance;
  static MCQService get instance => _instance ??= MCQService._();

  MCQService._();

  SupabaseClient get _client => SupabaseService.instance.client;
  AuthService get _auth => AuthService.instance;

  /// Create MCQ questions for an election
  Future<bool> createMCQQuestions({
    required String electionId,
    required List<Map<String, dynamic>> questions,
  }) async {
    try {
      if (!_auth.isAuthenticated) {
        throw Exception('User must be authenticated');
      }

      final questionsData = questions.asMap().entries.map((entry) {
        final index = entry.key;
        final question = entry.value;
        return {
          'election_id': electionId,
          'question_text': question['question_text'],
          'question_order': index + 1,
          'options': question['options'],
          'correct_answer_index': question['correct_answer_index'],
          'question_image_url': question['question_image_url'],
          'difficulty_level': question['difficulty_level'] ?? 'medium',
          'is_required': question['is_required'] ?? true,
        };
      }).toList();

      await _client.from('election_mcqs').insert(questionsData);

      return true;
    } catch (e) {
      debugPrint('Create MCQ questions error: $e');
      return false;
    }
  }

  /// Get MCQ questions for an election
  Future<List<Map<String, dynamic>>> getMCQQuestions(String electionId) async {
    try {
      final response = await _client
          .from('election_mcqs')
          .select()
          .eq('election_id', electionId)
          .order('question_order', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get MCQ questions error: $e');
      return [];
    }
  }

  /// Submit MCQ answers
  Future<Map<String, dynamic>> submitMCQAnswers({
    required String electionId,
    required List<Map<String, dynamic>> answers,
    required int attemptNumber,
  }) async {
    try {
      if (!_auth.isAuthenticated) {
        throw Exception('User must be authenticated');
      }

      final userId = _auth.currentUser!.id;

      // Insert responses
      final responsesData = answers.map((answer) {
        return {
          'mcq_id': answer['mcq_id'],
          'voter_id': userId,
          'election_id': electionId,
          'selected_answer_index': answer['selected_answer_index'],
          'is_correct': answer['is_correct'],
          'attempt_number': attemptNumber,
        };
      }).toList();

      await _client.from('voter_mcq_responses').insert(responsesData);

      // Calculate score
      final scoreResult = await _client.rpc(
        'calculate_mcq_score',
        params: {
          'p_voter_id': userId,
          'p_election_id': electionId,
          'p_attempt_number': attemptNumber,
        },
      );

      final score = Map<String, dynamic>.from(scoreResult);

      // Record attempt
      await _client.from('voter_mcq_attempts').insert({
        'voter_id': userId,
        'election_id': electionId,
        'attempt_number': attemptNumber,
        'total_questions': score['total_questions'],
        'correct_answers': score['correct_answers'],
        'score_percentage': score['score_percentage'],
        'passed': score['passed'],
      });

      return score;
    } catch (e) {
      debugPrint('Submit MCQ answers error: $e');
      return {
        'total_questions': 0,
        'correct_answers': 0,
        'score_percentage': 0.0,
        'passed': false,
        'error': e.toString(),
      };
    }
  }

  /// Get voter's MCQ attempts for an election
  Future<List<Map<String, dynamic>>> getVoterAttempts(String electionId) async {
    try {
      if (!_auth.isAuthenticated) return [];

      final userId = _auth.currentUser!.id;

      final response = await _client
          .from('voter_mcq_attempts')
          .select()
          .eq('voter_id', userId)
          .eq('election_id', electionId)
          .order('attempt_number', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get voter attempts error: $e');
      return [];
    }
  }

  /// Check if voter has passed MCQ
  Future<bool> hasPassedMCQ(String electionId) async {
    try {
      if (!_auth.isAuthenticated) return false;

      final userId = _auth.currentUser!.id;

      final response = await _client
          .from('voter_mcq_attempts')
          .select('passed')
          .eq('voter_id', userId)
          .eq('election_id', electionId)
          .eq('passed', true)
          .maybeSingle();

      return response != null;
    } catch (e) {
      debugPrint('Check MCQ pass error: $e');
      return false;
    }
  }

  /// Get MCQ analytics for election creator
  Future<Map<String, dynamic>> getMCQAnalytics(String electionId) async {
    try {
      final questions = await getMCQQuestions(electionId);
      final analytics = <String, dynamic>{};

      for (var question in questions) {
        final questionId = question['id'];
        final responses = await _client
            .from('voter_mcq_responses')
            .select()
            .eq('mcq_id', questionId);

        final totalResponses = responses.length;
        final correctResponses = responses
            .where((r) => r['is_correct'] == true)
            .length;

        final options = List<Map<String, dynamic>>.from(question['options']);
        final answerDistribution = <int, int>{};

        for (var response in responses) {
          final selectedIndex = response['selected_answer_index'] as int;
          answerDistribution[selectedIndex] =
              (answerDistribution[selectedIndex] ?? 0) + 1;
        }

        analytics[questionId] = {
          'question_text': question['question_text'],
          'difficulty_level': question['difficulty_level'],
          'total_responses': totalResponses,
          'correct_responses': correctResponses,
          'accuracy_rate': totalResponses > 0
              ? (correctResponses / totalResponses * 100).toStringAsFixed(1)
              : '0.0',
          'answer_distribution': answerDistribution,
          'options': options,
        };
      }

      return analytics;
    } catch (e) {
      debugPrint('Get MCQ analytics error: $e');
      return {};
    }
  }

  /// Update MCQ question
  Future<bool> updateMCQQuestion({
    required String questionId,
    required Map<String, dynamic> updates,
  }) async {
    try {
      if (!_auth.isAuthenticated) {
        throw Exception('User must be authenticated');
      }

      await _client.from('election_mcqs').update(updates).eq('id', questionId);

      return true;
    } catch (e) {
      debugPrint('Update MCQ question error: $e');
      return false;
    }
  }

  /// Delete MCQ question
  Future<bool> deleteMCQQuestion(String questionId) async {
    try {
      if (!_auth.isAuthenticated) {
        throw Exception('User must be authenticated');
      }

      await _client.from('election_mcqs').delete().eq('id', questionId);

      return true;
    } catch (e) {
      debugPrint('Delete MCQ question error: $e');
      return false;
    }
  }

  /// Validate MCQ answer
  bool validateAnswer({
    required List<dynamic> options,
    required int correctAnswerIndex,
    required int selectedAnswerIndex,
  }) {
    return selectedAnswerIndex == correctAnswerIndex;
  }

  /// Submit free-text answer
  Future<bool> submitFreeTextAnswer({
    required String mcqId,
    required String electionId,
    required String answerText,
  }) async {
    try {
      if (!_auth.isAuthenticated) {
        throw Exception('User must be authenticated');
      }

      final userId = _auth.currentUser!.id;

      await _client.from('voter_free_text_responses').insert({
        'mcq_id': mcqId,
        'voter_id': userId,
        'election_id': electionId,
        'answer_text': answerText,
      });

      return true;
    } catch (e) {
      debugPrint('Submit free-text answer error: $e');
      return false;
    }
  }

  /// Create live question injection
  Future<String?> createLiveQuestionInjection({
    required String electionId,
    required String questionText,
    required List<Map<String, dynamic>> options,
    required int correctAnswerIndex,
    String? questionImageUrl,
    String difficultyLevel = 'medium',
    String injectionPosition = 'end',
    DateTime? scheduledFor,
  }) async {
    try {
      if (!_auth.isAuthenticated) {
        throw Exception('User must be authenticated');
      }

      final userId = _auth.currentUser!.id;

      final response = await _client
          .from('live_question_injection_queue')
          .insert({
            'election_id': electionId,
            'creator_id': userId,
            'question_text': questionText,
            'options': options,
            'correct_answer_index': correctAnswerIndex,
            'question_image_url': questionImageUrl,
            'difficulty_level': difficultyLevel,
            'injection_position': injectionPosition,
            'injection_status': scheduledFor != null ? 'scheduled' : 'pending',
            'scheduled_for': scheduledFor?.toIso8601String(),
          })
          .select()
          .single();

      return response['id'] as String;
    } catch (e) {
      debugPrint('Create live question injection error: $e');
      return null;
    }
  }

  /// Broadcast live question to active voters
  Future<Map<String, dynamic>> broadcastLiveQuestion({
    required String injectionId,
    required String electionId,
  }) async {
    try {
      final response = await _client.rpc(
        'broadcast_live_question',
        params: {'p_injection_id': injectionId, 'p_election_id': electionId},
      );

      return Map<String, dynamic>.from(response);
    } catch (e) {
      debugPrint('Broadcast live question error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Get live question injection queue
  Future<List<Map<String, dynamic>>> getLiveQuestionInjectionQueue(
    String electionId,
  ) async {
    try {
      final response = await _client
          .from('live_question_injection_queue')
          .select()
          .eq('election_id', electionId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get live question injection queue error: $e');
      return [];
    }
  }

  /// Get live question broadcast analytics
  Future<Map<String, dynamic>> getLiveQuestionBroadcastAnalytics(
    String injectionId,
  ) async {
    try {
      final broadcast = await _client
          .from('live_question_broadcasts')
          .select()
          .eq('injection_id', injectionId)
          .maybeSingle();

      final analytics = await _client
          .from('live_question_response_analytics')
          .select()
          .eq('injection_id', injectionId)
          .maybeSingle();

      return {'broadcast': broadcast ?? {}, 'analytics': analytics ?? {}};
    } catch (e) {
      debugPrint('Get live question broadcast analytics error: $e');
      return {};
    }
  }

  /// Update live question injection
  Future<bool> updateLiveQuestionInjection({
    required String injectionId,
    required Map<String, dynamic> updates,
  }) async {
    try {
      await _client
          .from('live_question_injection_queue')
          .update(updates)
          .eq('id', injectionId);

      return true;
    } catch (e) {
      debugPrint('Update live question injection error: $e');
      return false;
    }
  }

  /// Delete live question injection
  Future<bool> deleteLiveQuestionInjection(String injectionId) async {
    try {
      await _client
          .from('live_question_injection_queue')
          .delete()
          .eq('id', injectionId);

      return true;
    } catch (e) {
      debugPrint('Delete live question injection error: $e');
      return false;
    }
  }

  /// Stream live questions for real-time updates
  Stream<List<Map<String, dynamic>>> streamLiveQuestions(String electionId) {
    return _client
        .from('election_mcqs')
        .stream(primaryKey: ['id'])
        .eq('election_id', electionId)
        .order('question_order')
        .map((data) => List<Map<String, dynamic>>.from(data));
  }

  /// Upload MCQ option image
  Future<String?> uploadOptionImage({
    required String mcqId,
    required int optionIndex,
    required String imagePath,
  }) async {
    try {
      if (kIsWeb) {
        debugPrint(
          'uploadOptionImage: File-based upload not supported on web. Use bytes upload instead.',
        );
        return null;
      }
      final file = File(imagePath);
      final bytes = await file.readAsBytes();
      final fileName =
          'mcq_option_${mcqId}_${optionIndex}_${DateTime.now().millisecondsSinceEpoch}.jpg';

      final uploadPath = await _client.storage
          .from('election-media')
          .uploadBinary('mcq-options/$fileName', bytes);

      final imageUrl = _client.storage
          .from('election-media')
          .getPublicUrl('mcq-options/$fileName');

      // Store metadata
      await _client.from('mcq_option_image_metadata').insert({
        'mcq_id': mcqId,
        'option_index': optionIndex,
        'original_image_url': imageUrl,
        'image_format': 'jpg',
      });

      return imageUrl;
    } catch (e) {
      debugPrint('Upload option image error: $e');
      return null;
    }
  }

  /// Get MCQ option image metadata
  Future<List<Map<String, dynamic>>> getOptionImageMetadata(
    String mcqId,
  ) async {
    try {
      final response = await _client
          .from('mcq_option_image_metadata')
          .select()
          .eq('mcq_id', mcqId)
          .order('option_index');

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get option image metadata error: $e');
      return [];
    }
  }

  /// Export MCQ image gallery
  Future<String?> exportImageGallery({
    required String electionId,
    String exportFormat = 'zip',
    bool includeVotingResults = true,
  }) async {
    try {
      if (!_auth.isAuthenticated) {
        throw Exception('User must be authenticated');
      }

      final userId = _auth.currentUser!.id;

      // Get all MCQ questions with images
      final questions = await getMCQQuestions(electionId);
      int totalImages = 0;

      for (var question in questions) {
        final options = List<Map<String, dynamic>>.from(question['options']);
        totalImages += options.where((opt) => opt['image_url'] != null).length;
      }

      final response = await _client
          .from('mcq_image_gallery_exports')
          .insert({
            'election_id': electionId,
            'creator_id': userId,
            'export_format': exportFormat,
            'total_images': totalImages,
            'includes_voting_results': includeVotingResults,
          })
          .select()
          .single();

      return response['id'] as String;
    } catch (e) {
      debugPrint('Export image gallery error: $e');
      return null;
    }
  }

  /// Get free-text answers for election
  Future<List<Map<String, dynamic>>> getFreeTextAnswers({
    required String electionId,
    String? mcqId,
    int limit = 100,
    int offset = 0,
  }) async {
    try {
      var query = _client
          .from('free_text_answers')
          .select()
          .eq('election_id', electionId);

      if (mcqId != null) {
        query = query.eq('mcq_id', mcqId);
      }

      final response = await query
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get free-text answers error: $e');
      return [];
    }
  }

  /// Get free-text answer analytics
  Future<Map<String, dynamic>> getFreeTextAnalytics({
    required String electionId,
    String? mcqId,
  }) async {
    try {
      final response = await _client.rpc(
        'get_free_text_analytics',
        params: {'p_election_id': electionId, 'p_mcq_id': mcqId},
      );

      if (response is List && response.isNotEmpty) {
        return Map<String, dynamic>.from(response.first);
      }

      return {
        'total_responses': 0,
        'average_character_count': 0.0,
        'sentiment_distribution': {},
        'common_themes': [],
        'moderation_flags': 0,
      };
    } catch (e) {
      debugPrint('Get free-text analytics error: $e');
      return {
        'total_responses': 0,
        'average_character_count': 0.0,
        'sentiment_distribution': {},
        'common_themes': [],
        'moderation_flags': 0,
      };
    }
  }

  /// Export free-text answers to CSV
  Future<String> exportFreeTextAnswersToCSV({
    required String electionId,
    String? mcqId,
  }) async {
    try {
      final answers = await getFreeTextAnswers(
        electionId: electionId,
        mcqId: mcqId,
        limit: 10000,
      );

      final csv = StringBuffer();
      csv.writeln(
        'Question ID,Voter ID,Answer Text,Character Count,Sentiment,Themes,Created At',
      );

      for (var answer in answers) {
        final themes = (answer['themes'] as List?)?.join('; ') ?? '';
        csv.writeln(
          '"${answer['mcq_id']}",'
          '"${answer['voter_id']}",'
          '"${answer['answer_text']?.replaceAll('"', '""')}",'
          '${answer['character_count']},'
          '"${answer['sentiment_label']}",'
          '"$themes",'
          '"${answer['created_at']}"',
        );
      }

      return csv.toString();
    } catch (e) {
      debugPrint('Export free-text answers error: $e');
      return '';
    }
  }

  /// Export free-text answers to JSON
  Future<String> exportFreeTextAnswersToJSON({
    required String electionId,
    String? mcqId,
  }) async {
    try {
      final answers = await getFreeTextAnswers(
        electionId: electionId,
        mcqId: mcqId,
        limit: 10000,
      );

      return jsonEncode(answers);
    } catch (e) {
      debugPrint('Export free-text answers JSON error: $e');
      return '[]';
    }
  }

  /// Analyze text with OpenAI
  Future<Map<String, dynamic>> _analyzeTextWithAI(String text) async {
    try {
      final analysis = await OpenAIService.analyzeTextSentiment(text: text);

      return {
        'sentiment_score': analysis['sentiment_score'] ?? 0.0,
        'sentiment_label': analysis['sentiment_label'] ?? 'neutral',
        'themes': analysis['themes'] ?? [],
        'moderation_flag': analysis['moderation_flag'] ?? false,
        'moderation_reason': analysis['moderation_reason'],
        'confidence': analysis['confidence'] ?? 0.0,
      };
    } catch (e) {
      debugPrint('AI text analysis error: $e');
      return {
        'sentiment_score': 0.0,
        'sentiment_label': 'neutral',
        'themes': [],
        'moderation_flag': false,
        'moderation_reason': null,
        'confidence': 0.0,
      };
    }
  }
}
