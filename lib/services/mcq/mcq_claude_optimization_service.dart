import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../claude_service.dart';
import '../supabase_service.dart';
import '../auth_service.dart';
import '../../models/mcq_optimization_suggestion.dart';

/// Service for MCQ-specific Claude AI optimization pipeline
class MCQClaudeOptimizationService {
  static MCQClaudeOptimizationService? _instance;
  static MCQClaudeOptimizationService get instance =>
      _instance ??= MCQClaudeOptimizationService._();

  MCQClaudeOptimizationService._();

  SupabaseClient get _client => SupabaseService.instance.client;
  AuthService get _auth => AuthService.instance;

  /// Analyze low-performing MCQ questions (accuracy < 60%)
  Future<List<Map<String, dynamic>>> analyzeLowPerformingQuestions(
    String electionId,
  ) async {
    try {
      // Query questions with accuracy < 60%
      final response = await _client.rpc(
        'get_low_performing_mcqs',
        params: {'p_election_id': electionId, 'p_accuracy_threshold': 0.6},
      );

      if (response != null && response is List) {
        return List<Map<String, dynamic>>.from(response);
      }

      // Fallback: direct query approach
      final mcqs = await _client
          .from('election_mcqs')
          .select(
            'mcq_id, question_text, options, correct_answer_index, difficulty_level',
          )
          .eq('election_id', electionId);

      final List<Map<String, dynamic>> lowPerforming = [];

      for (final mcq in mcqs) {
        final mcqId = mcq['mcq_id'];
        final responses = await _client
            .from('voter_mcq_responses')
            .select('selected_answer_index, correct_answer_index')
            .eq('mcq_id', mcqId);

        if (responses.isEmpty) continue;

        int correct = 0;
        for (final r in responses) {
          if (r['selected_answer_index'] == r['correct_answer_index']) {
            correct++;
          }
        }

        final accuracy = correct / responses.length;
        if (accuracy < 0.6) {
          lowPerforming.add({
            ...mcq,
            'accuracy_rate': accuracy,
            'total_responses': responses.length,
          });
        }
      }

      return lowPerforming;
    } catch (e) {
      debugPrint('analyzeLowPerformingQuestions error: $e');
      return [];
    }
  }

  /// Generate Claude optimization suggestions for a single MCQ question
  Future<MCQOptimizationSuggestion> generateOptimizationSuggestions(
    Map<String, dynamic> question, {
    double accuracyRate = 0.45,
  }) async {
    final questionText = question['question_text'] as String? ?? '';
    final rawOptions = question['options'];
    final List<String> options = _parseOptions(rawOptions);
    final correctIndex = question['correct_answer_index'] as int? ?? 0;
    final correctAnswer = options.isNotEmpty && correctIndex < options.length
        ? options[correctIndex]
        : '';

    final optionLabels = ['A', 'B', 'C', 'D', 'E'];
    final optionsText = options
        .asMap()
        .entries
        .map(
          (e) =>
              '${optionLabels[e.key < optionLabels.length ? e.key : 0]}) ${e.value}',
        )
        .join('\n');

    final accuracyPercent = (accuracyRate * 100).toStringAsFixed(1);

    final prompt =
        '''
You are an expert quiz designer. Analyze this multiple choice question for clarity and effectiveness.

Question: $questionText

Options:
$optionsText

Correct Answer: $correctAnswer
Current Performance: $accuracyPercent% of voters answered correctly.

Provide optimization suggestions in the following JSON format ONLY (no extra text):
{
  "improved_question_text": "<clearer, more concise version of the question>",
  "improved_options": ["<option A>", "<option B>", "<option C>", "<option D>"],
  "difficulty_recommendation": "<easier|maintain|harder>",
  "alternative_question_text": "<alternative question testing same concept>",
  "alternative_options": ["<option A>", "<option B>", "<option C>", "<option D>"],
  "projected_accuracy_improvement": <number between 5 and 30>,
  "confidence_score": <number between 60 and 95>,
  "reasoning": "<brief explanation of why these changes will improve accuracy>"
}

Focus on:
1) Improved question wording (more clear/concise)
2) Better answer options (eliminate ambiguity, improve distractors)
3) Difficulty adjustment recommendation
4) Alternative question testing same concept
5) Expected accuracy improvement percentage
''';

    try {
      final responseText = await ClaudeService.instance
          .callClaudeAPI(prompt)
          .timeout(const Duration(seconds: 30));

      // Extract JSON from response
      final jsonMatch = RegExp(
        r'\{[\s\S]*\}',
        multiLine: true,
      ).firstMatch(responseText);

      if (jsonMatch != null) {
        final jsonStr = jsonMatch.group(0)!;
        final parsed = jsonDecode(jsonStr) as Map<String, dynamic>;
        return MCQOptimizationSuggestion.fromJson(
          parsed,
          originalQuestionText: questionText,
          originalOptions: options,
          currentAccuracy: accuracyRate * 100,
        );
      }
    } catch (e) {
      debugPrint('generateOptimizationSuggestions error: $e');
    }

    // Fallback suggestion
    return MCQOptimizationSuggestion(
      originalQuestionText: questionText,
      improvedQuestionText: 'Consider rephrasing: $questionText',
      originalOptions: options,
      improvedOptions: options,
      difficultyRecommendation: accuracyRate < 0.4 ? 'easier' : 'maintain',
      alternativeQuestionText: 'Alternative: $questionText',
      alternativeOptions: options,
      projectedAccuracyImprovement: 10.0,
      currentAccuracy: accuracyRate * 100,
      reasoning:
          'Unable to generate AI suggestions. Please check your Claude API configuration.',
      confidenceScore: 50.0,
    );
  }

  /// Store optimization history in database
  Future<void> saveOptimizationHistory({
    required String mcqId,
    required MCQOptimizationSuggestion suggestion,
    required String optimizationType,
  }) async {
    try {
      if (!_auth.isAuthenticated) return;

      await _client.from('mcq_optimization_history').insert({
        'mcq_id': mcqId,
        'original_question_text': suggestion.originalQuestionText,
        'original_options': suggestion.originalOptions,
        'improved_question_text': suggestion.improvedQuestionText,
        'improved_options': suggestion.improvedOptions,
        'optimization_type': optimizationType,
        'applied_by': _auth.currentUser?.id,
        'accuracy_before': suggestion.currentAccuracy,
      });
    } catch (e) {
      debugPrint('saveOptimizationHistory error: $e');
    }
  }

  List<String> _parseOptions(dynamic raw) {
    if (raw is List) {
      return raw.map((e) {
        if (e is String) return e;
        if (e is Map) return e['text']?.toString() ?? '';
        return e.toString();
      }).toList();
    }
    return [];
  }
}