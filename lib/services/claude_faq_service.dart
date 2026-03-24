import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import './auth_service.dart';
import './supabase_service.dart';

class ClaudeFAQService {
  static ClaudeFAQService? _instance;
  static ClaudeFAQService get instance => _instance ??= ClaudeFAQService._();

  ClaudeFAQService._();

  static const String apiKey = String.fromEnvironment('ANTHROPIC_API_KEY');
  static const String apiUrl = 'https://api.anthropic.com/v1/messages';
  static const String model = 'claude-sonnet-4-20250514';

  AuthService get _auth => AuthService.instance;
  dynamic get _client => SupabaseService.instance.client;

  // Conversation context storage (last 5 messages)
  final Map<String, List<Map<String, String>>> _conversationHistory = {};

  /// Ask Claude a question with context
  Future<Map<String, dynamic>> askQuestion({
    required String question,
    String? userId,
  }) async {
    try {
      if (apiKey.isEmpty || apiKey == 'your-anthropic-api-key-here') {
        return _getDefaultResponse(question);
      }

      final uid = userId ?? _auth.currentUser?.id ?? 'anonymous';

      // Get conversation history for context
      final history = _conversationHistory[uid] ?? [];

      // Build comprehensive prompt with knowledge base
      final prompt = _buildFAQPrompt(question, history);

      // Call Claude API
      final response = await _callClaudeAPI(prompt, history);

      // Parse and enhance response
      final result = _parseResponse(response, question);

      // Update conversation history
      _updateConversationHistory(uid, question, result['answer'] as String);

      // Store feedback for analytics
      await _storeFAQInteraction(uid, question, result['answer'] as String);

      return result;
    } catch (e) {
      debugPrint('Claude FAQ error: $e');
      return _getDefaultResponse(question);
    }
  }

  /// Build FAQ prompt with knowledge base
  String _buildFAQPrompt(String question, List<Map<String, String>> history) {
    final knowledgeBase = '''
You are a helpful support assistant for Vottery, a creator platform where users earn money through elections, voting, and content creation.

KNOWLEDGE BASE:

**VP (Vottery Points)**
- Virtual currency earned through platform participation
- Earned by: creating elections, receiving votes, completing quests, engagement
- Can be redeemed for real cash
- Conversion rate varies by creator tier

**Creator Tiers**
- Bronze: <1000 VP (5% bonus on earnings)
- Silver: 1000-5000 VP (10% bonus)
- Gold: 5000-20000 VP (15% bonus)
- Platinum: >20000 VP (20% bonus)

**Content Guidelines**
- No hate speech, misinformation, spam, or illegal content
- Elections must have clear, distinct options
- Respect copyright and intellectual property
- Follow community standards

**Account Verification**
- Required for withdrawals over \$100
- Requires government ID and proof of address
- Processing time: 1-3 business days
- Increases trust score and visibility

**Payment Methods**
- Bank transfer (most common)
- PayPal
- Stripe (cards and payouts where enabled)
- Minimum withdrawal: \$10
- Processing time: 3-5 business days

**Earnings Breakdown**
- Election creation: 10-50 VP based on engagement
- Vote received: 1-5 VP based on election quality
- Quest completion: 25-500 VP based on difficulty
- Daily streak bonus: up to 100 VP
- Referral bonus: 50 VP per active referral

**Technical Support**
- For urgent issues: Create support ticket
- For feature requests: Use feedback portal
- For account issues: Contact support@vottery.com
- Response time: <24 hours for urgent, <48 hours for general

**Common Issues**
- VP not showing: Refresh app, check transaction history
- Withdrawal pending: Normal processing time is 3-5 days
- Election not visible: Check privacy settings and content guidelines
- Login issues: Reset password or contact support

CONVERSATION CONTEXT:
''';

    // Add conversation history for context
    String contextStr = '';
    for (final msg in history) {
      contextStr += '${msg['role']}: ${msg['content']}\n';
    }

    return '''$knowledgeBase
$contextStr

USER QUESTION: $question

Provide a helpful, concise answer with step-by-step instructions when applicable. Format with markdown for readability. If the question is unclear or requires human support, suggest creating a support ticket.''';
  }

  /// Call Claude API
  Future<String> _callClaudeAPI(
    String prompt,
    List<Map<String, String>> history,
  ) async {
    try {
      // Build messages array with history
      final messages = [
        ...history.map(
          (msg) => {'role': msg['role'], 'content': msg['content']},
        ),
        {'role': 'user', 'content': prompt},
      ];

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': apiKey,
          'anthropic-version': '2023-06-01',
        },
        body: jsonEncode({
          'model': model,
          'max_tokens': 1024,
          'temperature': 0.7,
          'messages': messages,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['content'][0]['text'] as String;
      } else {
        debugPrint('Claude API error: ${response.statusCode} ${response.body}');
        return 'I apologize, but I am having trouble processing your request right now. Please try again or create a support ticket for assistance.';
      }
    } catch (e) {
      debugPrint('Claude API call error: $e');
      return 'I apologize, but I am having trouble connecting right now. Please try again or create a support ticket for assistance.';
    }
  }

  /// Parse Claude response and add enhancements
  Map<String, dynamic> _parseResponse(String response, String question) {
    // Check for uncertainty indicators
    final uncertaintyWords = [
      'might',
      'possibly',
      'not sure',
      'unclear',
      'maybe',
    ];
    final hasUncertainty = uncertaintyWords.any(
      (word) => response.toLowerCase().contains(word),
    );

    // Extract related guides (simple keyword matching)
    final relatedGuides = _findRelatedGuides(question);

    // Suggest quick actions based on response content
    final quickActions = _extractQuickActions(response);

    return {
      'answer': response,
      'hasUncertainty': hasUncertainty,
      'relatedGuides': relatedGuides,
      'quickActions': quickActions,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// Find related guides based on question keywords
  List<Map<String, String>> _findRelatedGuides(String question) {
    final guides = <Map<String, String>>[];
    final lowerQuestion = question.toLowerCase();

    if (lowerQuestion.contains('withdraw') ||
        lowerQuestion.contains('earning') ||
        lowerQuestion.contains('money')) {
      guides.add({
        'title': 'Monetization Strategies',
        'category': 'monetization',
      });
    }

    if (lowerQuestion.contains('vp') || lowerQuestion.contains('point')) {
      guides.add({
        'title': 'Understanding VP System',
        'category': 'getting_started',
      });
    }

    if (lowerQuestion.contains('election') ||
        lowerQuestion.contains('create')) {
      guides.add({
        'title': 'Creating Engaging Content',
        'category': 'content_creation',
      });
    }

    if (lowerQuestion.contains('tier') || lowerQuestion.contains('level')) {
      guides.add({
        'title': 'Creator Tier Progression',
        'category': 'best_practices',
      });
    }

    return guides;
  }

  /// Extract quick actions from response
  List<String> _extractQuickActions(String response) {
    final actions = <String>[];
    final lowerResponse = response.toLowerCase();

    if (lowerResponse.contains('create') && lowerResponse.contains('ticket')) {
      actions.add('create_ticket');
    }

    if (lowerResponse.contains('guide') || lowerResponse.contains('tutorial')) {
      actions.add('view_guides');
    }

    if (lowerResponse.contains('withdraw') ||
        lowerResponse.contains('wallet')) {
      actions.add('open_wallet');
    }

    if (lowerResponse.contains('verify') ||
        lowerResponse.contains('verification')) {
      actions.add('start_verification');
    }

    return actions;
  }

  /// Update conversation history (keep last 5 messages)
  void _updateConversationHistory(
    String userId,
    String question,
    String answer,
  ) {
    final history = _conversationHistory[userId] ?? [];

    history.add({'role': 'user', 'content': question});
    history.add({'role': 'assistant', 'content': answer});

    // Keep only last 5 exchanges (10 messages)
    if (history.length > 10) {
      _conversationHistory[userId] = history.sublist(history.length - 10);
    } else {
      _conversationHistory[userId] = history;
    }
  }

  /// Clear conversation history for user
  void clearConversationHistory(String userId) {
    _conversationHistory.remove(userId);
  }

  /// Store FAQ interaction for analytics
  Future<void> _storeFAQInteraction(
    String userId,
    String question,
    String response,
  ) async {
    try {
      // Store in database for analytics (non-blocking)
      await _client.from('faq_feedback').insert({
        'user_id': userId,
        'question': question,
        'response': response,
        'helpful': true, // Default, can be updated later
      });
    } catch (e) {
      debugPrint('Store FAQ interaction error: $e');
    }
  }

  /// Submit feedback on FAQ response
  Future<bool> submitFeedback({
    required String userId,
    required String question,
    required String response,
    required bool helpful,
  }) async {
    try {
      await _client.from('faq_feedback').insert({
        'user_id': userId,
        'question': question,
        'response': response,
        'helpful': helpful,
      });
      return true;
    } catch (e) {
      debugPrint('Submit FAQ feedback error: $e');
      return false;
    }
  }

  /// Get default response when Claude is unavailable
  Map<String, dynamic> _getDefaultResponse(String question) {
    return {
      'answer':
          'I apologize, but I am currently unavailable. Please create a support ticket for assistance, and our team will respond within 24 hours.',
      'hasUncertainty': false,
      'relatedGuides': [],
      'quickActions': ['create_ticket'],
      'timestamp': DateTime.now().toIso8601String(),
    };
  }
}
