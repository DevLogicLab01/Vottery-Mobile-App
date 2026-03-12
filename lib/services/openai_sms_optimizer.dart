import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import './supabase_service.dart';
import './auth_service.dart';
import './ai/ai_service_base.dart';
import './ai/gemini_chat_service.dart';

/// SMS Optimizer — uses Gemini via ai-proxy (same as Web). AI-powered SMS enhancement.
class OpenAISMSOptimizer {
  static OpenAISMSOptimizer? _instance;
  static OpenAISMSOptimizer get instance =>
      _instance ??= OpenAISMSOptimizer._();

  OpenAISMSOptimizer._();

  SupabaseClient get _client => SupabaseService.instance.client;
  AuthService get _auth => AuthService.instance;

  // Character limit for single SMS
  static const int singleSMSLimit = 160;

  // =====================================================
  // CONTENT LENGTH OPTIMIZATION
  // =====================================================

  /// Optimize SMS content to fit 160 characters
  Future<Map<String, dynamic>?> optimizeLength(String messageBody) async {
    try {
      if (messageBody.length <= singleSMSLimit) {
        return {
          'original_message': messageBody,
          'optimized_message': messageBody,
          'character_savings': 0,
          'optimization_applied': false,
        };
      }

      final prompt =
          '''
Optimize this SMS to fit 160 characters while preserving meaning and urgency.

Original message (${messageBody.length} chars):
"$messageBody"

Rules:
- Keep critical information
- Remove filler words
- Use standard abbreviations (e.g., "&" for "and")
- Maintain professional tone
- Must be under 160 characters

Return ONLY the optimized message text, no explanation.''';

      final optimizedMessage = await GeminiChatService.sendChat(
        [{'role': 'user', 'content': prompt}],
        maxTokens: 100,
        temperature: 0.3,
      );

      // Validate length
      if (optimizedMessage.length > singleSMSLimit) {
        throw Exception('Optimized message still exceeds 160 characters');
      }

      final result = {
        'original_message': messageBody,
        'optimized_message': optimizedMessage,
        'character_savings': messageBody.length - optimizedMessage.length,
        'optimization_applied': true,
        'original_length': messageBody.length,
        'optimized_length': optimizedMessage.length,
      };

      // Log optimization (optimization_type: 'gemini' — matches Web)
      await _logOptimization(
        originalMessage: messageBody,
        optimizedMessage: optimizedMessage,
        optimizationType: 'gemini',
        characterSavings: result['character_savings'] as int,
      );

      return result;
    } catch (e) {
      debugPrint('Optimize length error: $e');
      return null;
    }
  }

  // =====================================================
  // PERSONALIZATION ENHANCEMENT
  // =====================================================

  /// Personalize SMS with user data
  Future<Map<String, dynamic>?> personalizeMessage({
    required String messageBody,
    required Map<String, dynamic> userData,
  }) async {
    try {
      final userName = userData['name'] ?? 'User';
      final userTier = userData['tier'] ?? 'Free';
      final lastActivity = userData['last_activity'] ?? 'recently';

      final prompt =
          '''
Personalize this SMS for the user with their data.

Original message:
"$messageBody"

User information:
- Name: $userName
- Tier: $userTier
- Last Activity: $lastActivity

Rules:
- Add personal touch using name
- Reference user activity if relevant
- Adjust tone for tier level
- Keep under 160 characters
- Make it feel personal, not automated

Return ONLY the personalized message text, no explanation.''';

      final personalizedMessage = await GeminiChatService.sendChat(
        [{'role': 'user', 'content': prompt}],
        maxTokens: 100,
        temperature: 0.5,
      );

      final result = {
        'original_message': messageBody,
        'personalized_message': personalizedMessage,
        'personalization_applied': true,
        'user_data_used': userData.keys.toList(),
      };

      await _logOptimization(
        originalMessage: messageBody,
        optimizedMessage: personalizedMessage,
        optimizationType: 'gemini',
      );

      return result;
    } catch (e) {
      debugPrint('Personalize message error: $e');
      return null;
    }
  }

  // =====================================================
  // ENGAGEMENT OPTIMIZATION
  // =====================================================

  /// Improve SMS engagement with urgency and CTAs
  Future<Map<String, dynamic>?> optimizeEngagement(String messageBody) async {
    try {
      final prompt =
          '''
Improve this SMS for maximum engagement and click-through rates.

Original message:
"$messageBody"

Enhancement strategies:
- Add urgency (limited time, scarcity)
- Include social proof ("Join 10,000+ users")
- Clear call-to-action
- Create FOMO (fear of missing out)
- Keep under 160 characters

Return ONLY the enhanced message text, no explanation.''';

      final engagedMessage = await GeminiChatService.sendChat(
        [{'role': 'user', 'content': prompt}],
        maxTokens: 100,
        temperature: 0.6,
      );

      final result = {
        'original_message': messageBody,
        'engaged_message': engagedMessage,
        'engagement_applied': true,
      };

      // Log optimization
      await _logOptimization(
        originalMessage: messageBody,
        optimizedMessage: engagedMessage,
        optimizationType: 'engagement',
      );

      return result;
    } catch (e) {
      debugPrint('Optimize engagement error: $e');
      return null;
    }
  }

  // =====================================================
  // TONE VALIDATION
  // =====================================================

  /// Validate message tone against brand guidelines
  Future<Map<String, dynamic>?> validateTone({
    required String messageBody,
    required String expectedTone,
  }) async {
    try {
      final prompt =
          '''
Classify the tone of this SMS message.

Message:
"$messageBody"

Expected tone: $expectedTone

Possible tones: professional, friendly, urgent, casual

Return JSON format:
{
  "detected_tone": "<tone>",
  "matches_expected": true/false,
  "confidence": 0.0-1.0
}''';

      final raw = await GeminiChatService.sendChat(
        [{'role': 'user', 'content': prompt}],
        maxTokens: 50,
        temperature: 0.2,
      );
      final response = _parseJsonFromText(raw);

      return {
        'message': messageBody,
        'expected_tone': expectedTone,
        'detected_tone': response['detected_tone'],
        'matches_expected': response['matches_expected'],
        'confidence': response['confidence'],
      };
    } catch (e) {
      debugPrint('Validate tone error: $e');
      return null;
    }
  }

  // =====================================================
  // A/B TEST GENERATION
  // =====================================================

  /// Generate A/B test variations
  Future<List<Map<String, dynamic>>> generateABTestVariations(
    String messageBody,
  ) async {
    try {
      final prompt =
          '''
Generate 3 SMS variations for A/B testing.

Original message:
"$messageBody"

Variations:
1. Emotional appeal (empathy, excitement)
2. Rational/logical (facts, benefits)
3. Urgency/scarcity (limited time, FOMO)

Each variation must be under 160 characters.

Return JSON array:
[
  {"variation": "A", "approach": "emotional", "message": "..."},
  {"variation": "B", "approach": "rational", "message": "..."},
  {"variation": "C", "approach": "urgency", "message": "..."}
]''';

      final raw = await GeminiChatService.sendChat(
        [{'role': 'user', 'content': prompt}],
        maxTokens: 300,
        temperature: 0.7,
      );
      final parsed = _parseJsonOrListFromText(raw);
      final variations = parsed is List
          ? List<dynamic>.from(parsed)
          : (parsed['variations'] as List<dynamic>? ?? []);

      return variations
          .map((v) => Map<String, dynamic>.from(v as Map))
          .toList();
    } catch (e) {
      debugPrint('Generate A/B test variations error: $e');
      return [];
    }
  }

  // =====================================================
  // SEGMENT CALCULATION
  // =====================================================

  /// Calculate SMS segments and cost
  Map<String, dynamic> calculateSegments(String messageBody) {
    final length = messageBody.length;
    final segments = (length / singleSMSLimit).ceil();
    final costPerSegment = 0.01; // $0.01 per segment
    final totalCost = segments * costPerSegment;

    return {
      'message_length': length,
      'segments_needed': segments,
      'cost_per_segment': costPerSegment,
      'total_cost': totalCost,
      'is_multi_segment': segments > 1,
      'characters_over_limit': length > singleSMSLimit
          ? length - singleSMSLimit
          : 0,
    };
  }

  // =====================================================
  // OPTIMIZATION ANALYTICS
  // =====================================================

  /// Get optimization analytics
  Future<Map<String, dynamic>> getOptimizationAnalytics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final start =
          startDate ?? DateTime.now().subtract(const Duration(days: 30));
      final end = endDate ?? DateTime.now();

      final optimizations = await _client
          .from('sms_optimization_history')
          .select()
          .gte('created_at', start.toIso8601String())
          .lte('created_at', end.toIso8601String());

      final totalOptimizations = optimizations.length;
      final totalCharacterSavings = optimizations.fold<int>(
        0,
        (sum, opt) => sum + ((opt['original_length'] as int? ?? 0) - (opt['optimized_length'] as int? ?? 0)),
      );

      final avgCharacterReduction = totalOptimizations > 0
          ? (totalCharacterSavings / totalOptimizations).round()
          : 0;

      // Group by optimization type
      final byType = <String, int>{};
      for (final opt in optimizations) {
        final type = opt['optimization_type'] as String;
        byType[type] = (byType[type] ?? 0) + 1;
      }

      return {
        'total_optimizations': totalOptimizations,
        'total_character_savings': totalCharacterSavings,
        'avg_character_reduction': avgCharacterReduction,
        'by_type': byType,
        'period': {
          'start': start.toIso8601String(),
          'end': end.toIso8601String(),
        },
      };
    } catch (e) {
      debugPrint('Get optimization analytics error: $e');
      return {};
    }
  }

  /// Get optimization history
  Future<List<Map<String, dynamic>>> getOptimizationHistory({
    String? optimizationType,
    int limit = 50,
  }) async {
    try {
      var query = _client.from('sms_optimization_history').select();

      if (optimizationType != null) {
        query = query.eq('optimization_type', optimizationType);
      }

      final response = await query
          .order('created_at', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get optimization history error: $e');
      return [];
    }
  }

  // =====================================================
  // HELPER METHODS
  // =====================================================

  /// Log optimization (columns aligned with Web/Supabase: original_content, optimized_content, optimization_type 'gemini').
  Future<void> _logOptimization({
    required String originalMessage,
    required String optimizedMessage,
    required String optimizationType,
    int? characterSavings,
  }) async {
    try {
      await _client.from('sms_optimization_history').insert({
        'original_content': originalMessage,
        'optimized_content': optimizedMessage,
        'original_length': originalMessage.length,
        'optimized_length': optimizedMessage.length,
        'optimization_type': optimizationType,
        'parameters': {'character_savings': characterSavings},
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Log optimization error: $e');
    }
  }

  static Map<String, dynamic> _parseJsonFromText(String text) {
    final p = _parseJsonOrListFromText(text);
    return p is Map<String, dynamic> ? p : {};
  }

  static dynamic _parseJsonOrListFromText(String text) {
    try {
      final match = RegExp(r'\{[\s\S]*\}|\[[\s\S]*\]').firstMatch(text);
      if (match != null) {
        final decoded = jsonDecode(match.group(0)!);
        if (decoded is List) return decoded;
        return Map<String, dynamic>.from(
          (decoded as Map).map((k, v) => MapEntry(k as String, v)),
        );
      }
    } catch (_) {}
    return <String, dynamic>{};
  }

  /// Update daily analytics
  Future<void> updateDailyAnalytics() async {
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final optimizations = await _client
          .from('sms_optimization_history')
          .select()
          .gte('created_at', startOfDay.toIso8601String())
          .lt('created_at', endOfDay.toIso8601String());

      final totalOptimizations = optimizations.length;
      final totalCharacterSavings = optimizations.fold<int>(
        0,
        (sum, opt) => sum + ((opt['original_length'] as int? ?? 0) - (opt['optimized_length'] as int? ?? 0)),
      );

      final avgCharacterReduction = totalOptimizations > 0
          ? (totalCharacterSavings / totalOptimizations).round()
          : 0;

      await _client.from('openai_optimization_analytics').upsert({
        'date': startOfDay.toIso8601String().split('T')[0],
        'total_optimizations': totalOptimizations,
        'avg_character_reduction': avgCharacterReduction,
        'total_api_calls': totalOptimizations,
        'total_cost': totalOptimizations * 0.001, // $0.001 per optimization
      });
    } catch (e) {
      debugPrint('Update daily analytics error: $e');
    }
  }
}
