import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import './supabase_service.dart';
import './claude_service.dart';

/// Claude Carousel Optimization Coach Service
/// AI-powered creator coaching with performance analysis and streaming support
class ClaudeCarouselCoachService {
  static ClaudeCarouselCoachService? _instance;
  static ClaudeCarouselCoachService get instance =>
      _instance ??= ClaudeCarouselCoachService._();

  ClaudeCarouselCoachService._();
  ClaudeCarouselCoachService();

  final SupabaseService _supabaseService = SupabaseService.instance;
  final ClaudeService _claudeService = ClaudeService.instance;

  /// Stream coach response with real-time text generation
  Stream<String> streamCoachResponse({
    required String question,
    List<Map<String, dynamic>>? conversationHistory,
  }) async* {
    try {
      final userId = _supabaseService.client.auth.currentUser?.id;
      if (userId == null) {
        yield 'Please log in to ask questions.';
        return;
      }

      final creatorData = await gatherCreatorData();
      final prompt = _buildStreamingPrompt(
        question,
        creatorData,
        conversationHistory,
      );

      String fullResponse = '';

      await for (final chunk in _claudeService.streamClaudeAPI(prompt)) {
        fullResponse += chunk;
        yield fullResponse;
      }

      // Save complete conversation after streaming
      await _saveConversation(userId, question, fullResponse);

      // Extract and create action items
      await _extractAndCreateActionItems(userId, fullResponse);
    } catch (e) {
      debugPrint('Error streaming coach response: $e');
      yield 'Sorry, I encountered an error. Please try again.';
    }
  }

  String _buildStreamingPrompt(
    String question,
    Map<String, dynamic> creatorData,
    List<Map<String, dynamic>>? history,
  ) {
    final profile =
        creatorData['creator_profile'] as Map<String, dynamic>? ?? {};
    final carouselPerf =
        creatorData['carousel_performance'] as Map<String, dynamic>? ?? {};
    final revenue =
        creatorData['revenue_metrics'] as Map<String, dynamic>? ?? {};

    final contextBuilder = StringBuffer();
    contextBuilder.writeln(
      'You are an expert carousel content optimization coach.',
    );
    contextBuilder.writeln('\nCreator Profile:');
    contextBuilder.writeln('- Tier: ${profile['tier'] ?? 'Bronze'}');
    contextBuilder.writeln(
      '- Total Earnings: \$${revenue['total_earnings'] ?? 0}',
    );

    if (carouselPerf.isNotEmpty) {
      contextBuilder.writeln('\nCarousel Performance:');
      carouselPerf.forEach((type, metrics) {
        final m = metrics as Map<String, dynamic>;
        contextBuilder.writeln(
          '- $type: ${m['engagement_rate']?.toStringAsFixed(1) ?? 0}% engagement',
        );
      });
    }

    if (history != null && history.isNotEmpty) {
      contextBuilder.writeln('\nConversation History:');
      for (final msg in history.take(5)) {
        contextBuilder.writeln('User: ${msg['question']}');
        contextBuilder.writeln(
          'Coach: ${msg['claude_response']?.substring(0, 100) ?? ''}...',
        );
      }
    }

    contextBuilder.writeln('\nCreator Question: "$question"');
    contextBuilder.writeln(
      '\nProvide actionable coaching advice. If you suggest specific actions, format them as:',
    );
    contextBuilder.writeln('Action: [specific action description]');
    contextBuilder.writeln('Expected Outcome: [measurable result]');

    return contextBuilder.toString();
  }

  Future<void> _saveConversation(
    String userId,
    String question,
    String response,
  ) async {
    try {
      await _supabaseService.client.from('coach_chat_history').insert({
        'creator_user_id': userId,
        'question': question,
        'claude_response': response,
      });
    } catch (e) {
      debugPrint('Error saving conversation: $e');
    }
  }

  Future<void> _extractAndCreateActionItems(
    String userId,
    String response,
  ) async {
    try {
      final actionPattern = RegExp(
        r'Action:\s*([^\n]+)(?:\s*Expected Outcome:\s*([^\n]+))?',
        caseSensitive: false,
      );

      final matches = actionPattern.allMatches(response);

      for (final match in matches) {
        final actionDescription = match.group(1)?.trim();
        final expectedOutcome = match.group(2)?.trim();

        if (actionDescription != null && actionDescription.isNotEmpty) {
          await _supabaseService.client.from('coaching_action_items').insert({
            'creator_user_id': userId,
            'action_category': 'content',
            'action_description': actionDescription,
            'expected_outcome': expectedOutcome ?? 'Improved performance',
            'priority': 'medium',
            'status': 'auto_generated',
          });
        }
      }
    } catch (e) {
      debugPrint('Error extracting action items: $e');
    }
  }

  /// Get conversation history
  Future<List<Map<String, dynamic>>> getConversationHistory({
    int limit = 20,
  }) async {
    try {
      final userId = _supabaseService.client.auth.currentUser?.id;
      if (userId == null) return [];

      final response = await _supabaseService.client
          .from('coach_chat_history')
          .select()
          .eq('creator_user_id', userId)
          .order('asked_at', ascending: false)
          .limit(limit);

      return (response as List<dynamic>).cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('Error getting conversation history: $e');
      return [];
    }
  }

  /// Intelligent question routing
  Future<String> routeQuestion(String question) async {
    final lowerQuestion = question.toLowerCase();

    if (lowerQuestion.contains('performance') ||
        lowerQuestion.contains('engagement') ||
        lowerQuestion.contains('analytics')) {
      return 'performance_query';
    } else if (lowerQuestion.contains('content') ||
        lowerQuestion.contains('strategy') ||
        lowerQuestion.contains('posting')) {
      return 'content_strategy_question';
    } else if (lowerQuestion.contains('revenue') ||
        lowerQuestion.contains('monetization') ||
        lowerQuestion.contains('earnings')) {
      return 'monetization_question';
    }

    return 'general_question';
  }

  /// Gather comprehensive creator performance data
  Future<Map<String, dynamic>> gatherCreatorData() async {
    try {
      final userId = _supabaseService.client.auth.currentUser?.id;
      if (userId == null) return {};

      final profile = await _supabaseService.client
          .from('user_profiles')
          .select('tier, created_at')
          .eq('id', userId)
          .maybeSingle();

      final carouselPerformance = await _getCarouselPerformanceByType(userId);
      final revenueMetrics = await _getRevenueMetrics(userId);

      return {
        'creator_profile': profile ?? {},
        'carousel_performance': carouselPerformance,
        'revenue_metrics': revenueMetrics,
      };
    } catch (e) {
      debugPrint('Error gathering creator data: $e');
      return {};
    }
  }

  Future<Map<String, dynamic>> _getCarouselPerformanceByType(
    String userId,
  ) async {
    try {
      final response = await _supabaseService.client
          .from('carousel_interactions')
          .select('carousel_type, interaction_type, converted')
          .eq('user_id', userId)
          .limit(1000);

      final byType = <String, Map<String, dynamic>>{};

      for (final interaction in response) {
        final carouselType = interaction['carousel_type'] as String;
        if (!byType.containsKey(carouselType)) {
          byType[carouselType] = {
            'total': 0,
            'engagements': 0,
            'conversions': 0,
          };
        }

        byType[carouselType]!['total'] =
            (byType[carouselType]!['total'] as int) + 1;

        if (interaction['interaction_type'] == 'tap' ||
            interaction['interaction_type'] == 'hold') {
          byType[carouselType]!['engagements'] =
              (byType[carouselType]!['engagements'] as int) + 1;
        }

        if (interaction['converted'] == true) {
          byType[carouselType]!['conversions'] =
              (byType[carouselType]!['conversions'] as int) + 1;
        }
      }

      byType.forEach((key, value) {
        final total = value['total'] as int;
        value['engagement_rate'] = total > 0
            ? ((value['engagements'] as int) / total * 100)
            : 0.0;
        value['conversion_rate'] = total > 0
            ? ((value['conversions'] as int) / total * 100)
            : 0.0;
      });

      return byType;
    } catch (e) {
      debugPrint('Error getting carousel performance: $e');
      return {};
    }
  }

  Future<Map<String, dynamic>> _getRevenueMetrics(String userId) async {
    try {
      final response = await _supabaseService.client
          .from('carousel_transactions')
          .select('amount, transaction_type')
          .eq('creator_user_id', userId)
          .limit(1000);

      final totalEarnings = response.fold<double>(
        0.0,
        (sum, t) => sum + ((t['amount'] as num?)?.toDouble() ?? 0.0),
      );

      return {'total_earnings': totalEarnings};
    } catch (e) {
      debugPrint('Error getting revenue metrics: $e');
      return {};
    }
  }

  /// Generate coaching plan using Claude AI
  Future<Map<String, dynamic>> generateCoachingPlan(
    Map<String, dynamic> creatorData,
  ) async {
    try {
      final prompt = _buildCoachingPrompt(creatorData);
      final response = await _claudeService.callClaudeAPI(prompt);
      final coachingPlan = _parseCoachingResponse(response);

      await _storeCoachingSession(creatorData, coachingPlan);
      return coachingPlan;
    } catch (e) {
      debugPrint('Error generating coaching plan: $e');
      return _getDefaultCoachingPlan();
    }
  }

  String _buildCoachingPrompt(Map<String, dynamic> creatorData) {
    final profile =
        creatorData['creator_profile'] as Map<String, dynamic>? ?? {};
    final revenue =
        creatorData['revenue_metrics'] as Map<String, dynamic>? ?? {};

    return '''
You are an expert carousel content coach.

Creator: Tier ${profile['tier'] ?? 'Bronze'}, Earnings: \$${revenue['total_earnings'] ?? 0}

Provide coaching in JSON:
{
  "performance_assessment": {"strengths": [], "weaknesses": [], "opportunities": []},
  "carousel_recommendations": {"horizontal": [], "vertical": [], "gradient": []},
  "action_plan": [{"week": 1, "focus": "", "actions": [], "expected_outcome": "", "priority": "high"}]
}
''';
  }

  Map<String, dynamic> _parseCoachingResponse(String response) {
    try {
      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(response);
      if (jsonMatch != null) {
        return jsonDecode(jsonMatch.group(0)!) as Map<String, dynamic>;
      }
      return _getDefaultCoachingPlan();
    } catch (e) {
      return _getDefaultCoachingPlan();
    }
  }

  Map<String, dynamic> _getDefaultCoachingPlan() {
    return {
      'performance_assessment': {
        'strengths': ['Consistent posting'],
        'weaknesses': ['Low conversion rate'],
        'opportunities': ['Expand carousel types'],
      },
      'carousel_recommendations': {
        'horizontal': ['Focus on Jolts with trending topics'],
        'vertical': ['Create more Groups'],
        'gradient': ['Experiment with Topics'],
      },
      'action_plan': [
        {
          'week': 1,
          'focus': 'Optimize posting times',
          'actions': ['Post 3 Jolts between 7-9 PM'],
          'expected_outcome': '+15% engagement',
          'priority': 'high',
        },
        {
          'week': 2,
          'focus': 'Content diversification',
          'actions': ['Create 2 election posts'],
          'expected_outcome': '+200 followers',
          'priority': 'high',
        },
      ],
    };
  }

  Future<void> _storeCoachingSession(
    Map<String, dynamic> creatorData,
    Map<String, dynamic> coachingPlan,
  ) async {
    try {
      final userId = _supabaseService.client.auth.currentUser?.id;
      if (userId == null) return;

      final response = await _supabaseService.client
          .from('carousel_coaching_sessions')
          .insert({
            'creator_user_id': userId,
            'performance_data': jsonEncode(creatorData),
            'claude_analysis': jsonEncode(coachingPlan),
            'coaching_plan': jsonEncode(coachingPlan['action_plan']),
          })
          .select()
          .single();

      final sessionId = response['session_id'] as String;
      final actionPlan = coachingPlan['action_plan'] as List<dynamic>? ?? [];

      for (final action in actionPlan) {
        await _supabaseService.client.from('coaching_action_items').insert({
          'session_id': sessionId,
          'creator_user_id': userId,
          'week_number': action['week'],
          'action_category': 'content',
          'action_description': (action['actions'] as List).join(', '),
          'expected_outcome': action['expected_outcome'],
          'priority': action['priority'],
        });
      }
    } catch (e) {
      debugPrint('Error storing coaching session: $e');
    }
  }

  /// Get coaching history
  Future<List<Map<String, dynamic>>> getCoachingHistory() async {
    try {
      final userId = _supabaseService.client.auth.currentUser?.id;
      if (userId == null) return [];

      final response = await _supabaseService.client
          .from('carousel_coaching_sessions')
          .select()
          .eq('creator_user_id', userId)
          .order('session_date', ascending: false)
          .limit(10);

      return (response as List<dynamic>).cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('Error getting coaching history: $e');
      return [];
    }
  }

  /// Get action items
  Future<List<Map<String, dynamic>>> getActionItems() async {
    try {
      final userId = _supabaseService.client.auth.currentUser?.id;
      if (userId == null) return [];

      final response = await _supabaseService.client
          .from('coaching_action_items')
          .select()
          .eq('creator_user_id', userId)
          .inFilter('status', ['pending', 'in_progress'])
          .order('week_number');

      return (response as List<dynamic>).cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('Error getting action items: $e');
      return [];
    }
  }

  /// Update action item status
  Future<bool> updateActionItemStatus(String actionId, String status) async {
    try {
      await _supabaseService.client
          .from('coaching_action_items')
          .update({
            'status': status,
            if (status == 'completed')
              'completed_at': DateTime.now().toIso8601String(),
          })
          .eq('action_id', actionId);

      return true;
    } catch (e) {
      debugPrint('Error updating action item: $e');
      return false;
    }
  }

  /// Ask coach question
  Future<String> askCoachQuestion(String question) async {
    try {
      final userId = _supabaseService.client.auth.currentUser?.id;
      if (userId == null) return 'Please log in to ask questions.';

      final creatorData = await gatherCreatorData();
      final prompt =
          '''
You are a carousel coach. Creator asks: "$question"

Context: ${jsonEncode(creatorData)}

Provide helpful answer.''';

      final response = await _claudeService.callClaudeAPI(prompt);

      await _supabaseService.client.from('coach_chat_history').insert({
        'creator_user_id': userId,
        'question': question,
        'claude_response': response,
      });

      return response;
    } catch (e) {
      debugPrint('Error asking coach question: $e');
      return 'Sorry, I encountered an error. Please try again.';
    }
  }
}
