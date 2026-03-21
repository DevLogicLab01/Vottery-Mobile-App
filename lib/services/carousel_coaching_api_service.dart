import 'dart:async';
import './claude_carousel_coach_service.dart';
import './supabase_service.dart';
import 'package:flutter/foundation.dart';

/// Carousel Coaching API Service
/// Extends Claude Carousel Coach with streaming API and action automation
class CarouselCoachingAPIService extends ClaudeCarouselCoachService {
  static CarouselCoachingAPIService? _instance;
  static CarouselCoachingAPIService get instance =>
      _instance ??= CarouselCoachingAPIService._();

  CarouselCoachingAPIService._() : super();

  final SupabaseService _supabaseService = SupabaseService.instance;

  // ============================================
  // STREAMING COACH ENDPOINT
  // ============================================

  /// Stream coach response with Server-Sent Events pattern
  @override
  Stream<String> streamCoachResponse({
    required String question,
    List<Map<String, dynamic>>? conversationHistory,
  }) async* {
    try {
      final userId = _supabaseService.client.auth.currentUser?.id;
      if (userId == null) {
        yield 'Please log in to access the coaching service.';
        return;
      }

      // Gather creator performance data
      final creatorData = await gatherCreatorData();

      // Route question to appropriate handler
      final questionType = await routeQuestion(question);

      // Get relevant context based on question type
      await _getContextForQuestionType(
        questionType,
        creatorData,
      );

      // Stream response from Claude
      String fullResponse = '';
      await for (final chunk in super.streamCoachResponse(
        question: question,
        conversationHistory: conversationHistory,
      )) {
        fullResponse = chunk;
        yield chunk;
      }

      // Post-processing: Extract and create action items
      await _processResponseForActions(userId, fullResponse);
    } catch (e) {
      debugPrint('Error in streaming coach response: $e');
      yield 'I apologize, but I encountered an error. Please try again.';
    }
  }

  // ============================================
  // CONTEXT GATHERING
  // ============================================

  Future<Map<String, dynamic>> _getContextForQuestionType(
    String questionType,
    Map<String, dynamic> creatorData,
  ) async {
    switch (questionType) {
      case 'performance_query':
        return await _getPerformanceContext(creatorData);
      case 'content_strategy_question':
        return await _getContentStrategyContext(creatorData);
      case 'monetization_question':
        return await _getMonetizationContext(creatorData);
      default:
        return creatorData;
    }
  }

  Future<Map<String, dynamic>> _getPerformanceContext(
    Map<String, dynamic> creatorData,
  ) async {
    try {
      final userId = _supabaseService.client.auth.currentUser?.id;
      if (userId == null) return creatorData;

      final carouselAnalytics = await _supabaseService.client
          .from('carousel_analytics')
          .select()
          .eq('creator_user_id', userId)
          .order('created_at', ascending: false)
          .limit(10);

      return {...creatorData, 'recent_analytics': carouselAnalytics};
    } catch (e) {
      return creatorData;
    }
  }

  Future<Map<String, dynamic>> _getContentStrategyContext(
    Map<String, dynamic> creatorData,
  ) async {
    try {
      final userId = _supabaseService.client.auth.currentUser?.id;
      if (userId == null) return creatorData;

      final contentPerformance = await _supabaseService.client
          .from('carousel_content_performance')
          .select()
          .eq('creator_user_id', userId)
          .order('engagement_score', ascending: false)
          .limit(20);

      return {...creatorData, 'top_performing_content': contentPerformance};
    } catch (e) {
      return creatorData;
    }
  }

  Future<Map<String, dynamic>> _getMonetizationContext(
    Map<String, dynamic> creatorData,
  ) async {
    try {
      final userId = _supabaseService.client.auth.currentUser?.id;
      if (userId == null) return creatorData;

      final revenueData = await _supabaseService.client
          .from('creator_revenue_analytics')
          .select()
          .eq('creator_user_id', userId)
          .order('date', ascending: false)
          .limit(30);

      return {...creatorData, 'revenue_history': revenueData};
    } catch (e) {
      return creatorData;
    }
  }

  // ============================================
  // ACTION ITEM AUTOMATION
  // ============================================

  Future<void> _processResponseForActions(
    String userId,
    String response,
  ) async {
    try {
      // Extract action items using multiple patterns
      final actionItems = _extractActionItems(response);

      for (final item in actionItems) {
        await _createActionItem(userId, item);

        // Trigger Supabase updates if action relates to coaching plan
        if (item['relates_to_plan'] == true) {
          await _updateCoachingPlan(userId, item);
        }
      }

      // Send notification if action items were created
      if (actionItems.isNotEmpty) {
        await _notifyCreatorOfNewActions(userId, actionItems.length);
      }
    } catch (e) {
      debugPrint('Error processing response for actions: $e');
    }
  }

  List<Map<String, dynamic>> _extractActionItems(String response) {
    final items = <Map<String, dynamic>>[];

    // Pattern 1: "Action:" format
    final actionPattern = RegExp(
      r'Action:\s*([^\n]+)(?:\s*Expected Outcome:\s*([^\n]+))?',
      caseSensitive: false,
    );

    // Pattern 2: "Recommendation:" format
    final recommendationPattern = RegExp(
      r'Recommendation:\s*([^\n]+)',
      caseSensitive: false,
    );

    // Pattern 3: "Next step:" format
    final nextStepPattern = RegExp(
      r'Next step:\s*([^\n]+)',
      caseSensitive: false,
    );

    // Extract from all patterns
    for (final match in actionPattern.allMatches(response)) {
      final description = match.group(1)?.trim();
      final outcome = match.group(2)?.trim();

      if (description != null && description.isNotEmpty) {
        items.add({
          'description': description,
          'expected_outcome': outcome ?? 'Improved performance',
          'category': _categorizeAction(description),
          'priority': _determinePriority(description),
          'relates_to_plan': _relatesToCoachingPlan(description),
        });
      }
    }

    for (final match in recommendationPattern.allMatches(response)) {
      final description = match.group(1)?.trim();
      if (description != null && description.isNotEmpty) {
        items.add({
          'description': description,
          'expected_outcome': 'Follow recommendation',
          'category': 'content',
          'priority': 'medium',
          'relates_to_plan': false,
        });
      }
    }

    for (final match in nextStepPattern.allMatches(response)) {
      final description = match.group(1)?.trim();
      if (description != null && description.isNotEmpty) {
        items.add({
          'description': description,
          'expected_outcome': 'Complete next step',
          'category': 'strategy',
          'priority': 'high',
          'relates_to_plan': true,
        });
      }
    }

    return items;
  }

  String _categorizeAction(String description) {
    final lower = description.toLowerCase();

    if (lower.contains('content') ||
        lower.contains('post') ||
        lower.contains('create')) {
      return 'content';
    } else if (lower.contains('engagement') ||
        lower.contains('audience') ||
        lower.contains('interact')) {
      return 'engagement';
    } else if (lower.contains('revenue') ||
        lower.contains('monetize') ||
        lower.contains('earnings')) {
      return 'monetization';
    } else if (lower.contains('optimize') ||
        lower.contains('improve') ||
        lower.contains('enhance')) {
      return 'optimization';
    }

    return 'general';
  }

  String _determinePriority(String description) {
    final lower = description.toLowerCase();

    if (lower.contains('urgent') ||
        lower.contains('immediate') ||
        lower.contains('critical')) {
      return 'high';
    } else if (lower.contains('soon') ||
        lower.contains('important') ||
        lower.contains('should')) {
      return 'medium';
    }

    return 'low';
  }

  bool _relatesToCoachingPlan(String description) {
    final lower = description.toLowerCase();
    return lower.contains('plan') ||
        lower.contains('week') ||
        lower.contains('milestone') ||
        lower.contains('goal');
  }

  Future<void> _createActionItem(
    String userId,
    Map<String, dynamic> item,
  ) async {
    try {
      await _supabaseService.client.from('coaching_action_items').insert({
        'creator_user_id': userId,
        'action_category': item['category'],
        'action_description': item['description'],
        'expected_outcome': item['expected_outcome'],
        'priority': item['priority'],
        'status': 'auto_generated',
      });
    } catch (e) {
      debugPrint('Error creating action item: $e');
    }
  }

  Future<void> _updateCoachingPlan(
    String userId,
    Map<String, dynamic> item,
  ) async {
    try {
      // Get current coaching plan
      final plan = await _supabaseService.client
          .from('coaching_plans')
          .select()
          .eq('creator_user_id', userId)
          .eq('status', 'active')
          .maybeSingle();

      if (plan != null) {
        // Add action to appropriate week
        final currentWeek = _getCurrentWeek(plan['start_date'] as String);
        await _addActionToWeek(plan['plan_id'] as String, currentWeek, item);
      }
    } catch (e) {
      debugPrint('Error updating coaching plan: $e');
    }
  }

  int _getCurrentWeek(String startDate) {
    final start = DateTime.parse(startDate);
    final now = DateTime.now();
    final daysDiff = now.difference(start).inDays;
    return (daysDiff / 7).floor() + 1;
  }

  Future<void> _addActionToWeek(
    String planId,
    int week,
    Map<String, dynamic> item,
  ) async {
    try {
      await _supabaseService.client.from('coaching_plan_actions').insert({
        'plan_id': planId,
        'week_number': week,
        'action_description': item['description'],
        'expected_outcome': item['expected_outcome'],
        'status': 'pending',
      });
    } catch (e) {
      debugPrint('Error adding action to week: $e');
    }
  }

  Future<void> _notifyCreatorOfNewActions(
    String userId,
    int actionCount,
  ) async {
    try {
      // This would integrate with your notification service
      debugPrint('Notifying creator $userId of $actionCount new action items');
    } catch (e) {
      debugPrint('Error notifying creator: $e');
    }
  }

  // ============================================
  // CONVERSATION MANAGEMENT
  // ============================================

  /// Save message to conversation history
  Future<void> saveMessage({
    required String question,
    required String response,
  }) async {
    try {
      final userId = _supabaseService.client.auth.currentUser?.id;
      if (userId == null) return;

      await _supabaseService.client.from('coach_chat_history').insert({
        'creator_user_id': userId,
        'question': question,
        'claude_response': response,
      });
    } catch (e) {
      debugPrint('Error saving message: $e');
    }
  }

  /// Get action items for user
  @override
  Future<List<Map<String, dynamic>>> getActionItems({
    String? status,
    int limit = 50,
  }) async {
    try {
      final userId = _supabaseService.client.auth.currentUser?.id;
      if (userId == null) return [];

      var query = _supabaseService.client
          .from('coaching_action_items')
          .select()
          .eq('creator_user_id', userId);

      if (status != null) {
        query = query.eq('status', status);
      }

      final response = await query
          .order('created_at', ascending: false)
          .limit(limit);
      return (response as List<dynamic>).cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('Error getting action items: $e');
      return [];
    }
  }

  /// Mark action item as completed
  Future<bool> completeActionItem(String actionItemId) async {
    try {
      await _supabaseService.client
          .from('coaching_action_items')
          .update({
            'status': 'completed',
            'completed_at': DateTime.now().toIso8601String(),
          })
          .eq('action_item_id', actionItemId);

      return true;
    } catch (e) {
      debugPrint('Error completing action item: $e');
      return false;
    }
  }
}
