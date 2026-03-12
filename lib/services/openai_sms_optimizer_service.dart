import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import './supabase_service.dart';
import './auth_service.dart';
import './ai/ai_service_base.dart';
import './ai/gemini_chat_service.dart';

/// SMS Optimizer Service — uses Gemini via ai-proxy (same as Web). No OpenAI key required.
/// AI-powered SMS content optimization with length reduction, personalization, and engagement enhancement.
class OpenAISMSOptimizerService {
  static OpenAISMSOptimizerService? _instance;
  static OpenAISMSOptimizerService get instance =>
      _instance ??= OpenAISMSOptimizerService._();

  OpenAISMSOptimizerService._() {
    _initializeService();
  }

  static const String apiKey = String.fromEnvironment('OPENAI_API_KEY');
  late final Dio _dio;
  final _supabase = SupabaseService.instance.client;
  final _auth = AuthService.instance;
  bool _openAiAvailable = false;

  void _initializeService() {
    _openAiAvailable = apiKey.isNotEmpty;
    if (!_openAiAvailable) {
      debugPrint('✅ OpenAISMSOptimizerService using Gemini via ai-proxy (no OpenAI key)');
    } else {
      _dio = Dio(
        BaseOptions(
          baseUrl: 'https://api.openai.com/v1',
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $apiKey',
          },
        ),
      );
      debugPrint('✅ OpenAISMSOptimizerService initialized (OpenAI fallback available)');
    }
  }

  /// Optimize SMS length (fit within 160 characters)
  Future<OptimizationResult> optimizeLength(String messageBody) async {
    try {
      if (messageBody.length <= 160) {
        return OptimizationResult(
          success: true,
          originalMessage: messageBody,
          optimizedMessage: messageBody,
          optimizationType: 'length',
          characterSavings: 0,
        );
      }

      final prompt =
          '''
Optimize this SMS to fit 160 characters while preserving meaning.

Original: "$messageBody"

Rules:
- Keep urgent info
- Remove filler words
- Use abbreviations if needed
- Maintain clarity
- Return ONLY the optimized message (no explanation)
''';

      final optimizedMessage = await _callGeminiOrOpenAI(prompt);

      // Validate length
      if (optimizedMessage.length > 160) {
        throw Exception('Optimization failed: still too long');
      }

      final characterSavings = messageBody.length - optimizedMessage.length;

      // Log optimization (optimization_type: 'gemini' when using Gemini — matches Web)
      await _logOptimization(
        originalMessage: messageBody,
        optimizedMessage: optimizedMessage,
        optimizationType: 'gemini',
        characterSavings: characterSavings,
      );

      return OptimizationResult(
        success: true,
        originalMessage: messageBody,
        optimizedMessage: optimizedMessage,
        optimizationType: 'length',
        characterSavings: characterSavings,
      );
    } catch (e) {
      debugPrint('Optimize length error: $e');
      return OptimizationResult(
        success: false,
        originalMessage: messageBody,
        optimizedMessage: messageBody,
        optimizationType: 'length',
        error: e.toString(),
      );
    }
  }

  /// Personalize SMS content
  Future<OptimizationResult> personalizeSMS({
    required String messageBody,
    required Map<String, dynamic> userData,
  }) async {
    try {
      final prompt =
          '''
Personalize this SMS for the user.

User info:
- Name: ${userData['name'] ?? 'User'}
- Tier: ${userData['tier'] ?? 'Free'}
- Last activity: ${userData['last_activity'] ?? 'Unknown'}

Original message: "$messageBody"

Rules:
- Add personal touch
- Reference user activity if relevant
- Adjust tone for tier
- Keep under 160 characters
- Return ONLY the personalized message (no explanation)
''';

      final optimizedMessage = await _callGeminiOrOpenAI(prompt);

      // Log optimization (optimization_type: 'gemini' — matches Web)
      await _logOptimization(
        originalMessage: messageBody,
        optimizedMessage: optimizedMessage,
        optimizationType: 'gemini',
      );

      return OptimizationResult(
        success: true,
        originalMessage: messageBody,
        optimizedMessage: optimizedMessage,
        optimizationType: 'personalization',
      );
    } catch (e) {
      debugPrint('Personalize SMS error: $e');
      return OptimizationResult(
        success: false,
        originalMessage: messageBody,
        optimizedMessage: messageBody,
        optimizationType: 'personalization',
        error: e.toString(),
      );
    }
  }

  /// Enhance engagement
  Future<OptimizationResult> enhanceEngagement(String messageBody) async {
    try {
      final prompt =
          '''
Improve this SMS for engagement.

Current: "$messageBody"

Add:
- Urgency (limited time)
- Social proof (others acting)
- Clear CTA (action button)

Keep under 160 characters.
Return ONLY the optimized message (no explanation).
''';

      final optimizedMessage = await _callGeminiOrOpenAI(prompt);

      // Log optimization (optimization_type: 'gemini' — matches Web)
      await _logOptimization(
        originalMessage: messageBody,
        optimizedMessage: optimizedMessage,
        optimizationType: 'gemini',
      );

      return OptimizationResult(
        success: true,
        originalMessage: messageBody,
        optimizedMessage: optimizedMessage,
        optimizationType: 'engagement',
      );
    } catch (e) {
      debugPrint('Enhance engagement error: $e');
      return OptimizationResult(
        success: false,
        originalMessage: messageBody,
        optimizedMessage: messageBody,
        optimizationType: 'engagement',
        error: e.toString(),
      );
    }
  }

  /// Validate tone
  Future<ToneValidationResult> validateTone({
    required String messageBody,
    required String expectedTone,
  }) async {
    try {
      final prompt =
          '''
Classify the tone of this SMS.

Message: "$messageBody"

Options: professional, friendly, urgent, casual

Return ONLY the tone classification (one word, lowercase).
''';

      final detectedTone = await _callGeminiOrOpenAI(prompt);
      final toneMatch =
          detectedTone.trim().toLowerCase() == expectedTone.toLowerCase();

      return ToneValidationResult(
        success: true,
        detectedTone: detectedTone.trim().toLowerCase(),
        expectedTone: expectedTone.toLowerCase(),
        toneMatch: toneMatch,
      );
    } catch (e) {
      debugPrint('Validate tone error: $e');
      return ToneValidationResult(
        success: false,
        detectedTone: 'unknown',
        expectedTone: expectedTone,
        toneMatch: false,
        error: e.toString(),
      );
    }
  }

  /// Generate A/B test variations
  Future<List<String>> generateABVariations(String messageBody) async {
    try {
      final prompt =
          '''
Generate 3 SMS variations for A/B testing.

Original: "$messageBody"

Variation 1: Emotional appeal
Variation 2: Rational/logical
Variation 3: Urgency/scarcity

All under 160 chars.
Return ONLY the 3 variations, separated by "|||" (no labels, no explanation).
''';

      final response = await _callGeminiOrOpenAI(prompt);
      final variations = response.split('|||').map((v) => v.trim()).toList();

      return variations.take(3).toList();
    } catch (e) {
      debugPrint('Generate A/B variations error: $e');
      return [messageBody];
    }
  }

  /// Get optimization analytics (uses created_at, original_length/optimized_length — aligned with Web/Supabase).
  Future<Map<String, dynamic>> getOptimizationAnalytics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      var query = _supabase.from('sms_optimization_history').select();

      if (startDate != null) {
        query = query.gte('created_at', startDate.toIso8601String());
      }
      if (endDate != null) {
        query = query.lte('created_at', endDate.toIso8601String());
      }

      final optimizations = await query;

      final totalOptimizations = optimizations.length;
      final totalSavings = optimizations.fold<int>(
        0,
        (sum, o) => sum + ((o['original_length'] as int? ?? 0) - (o['optimized_length'] as int? ?? 0)),
      );
      final avgCharacterReduction = totalOptimizations > 0 ? totalSavings ~/ totalOptimizations : 0;

      final byType = <String, int>{};
      for (final opt in optimizations) {
        final type = opt['optimization_type'] as String? ?? 'gemini';
        byType[type] = (byType[type] ?? 0) + 1;
      }

      return {
        'total_optimizations': totalOptimizations,
        'avg_character_reduction': avgCharacterReduction,
        'by_type': byType,
      };
    } catch (e) {
      debugPrint('Get optimization analytics error: $e');
      return {};
    }
  }

  /// Call Gemini via ai-proxy (primary); fallback to OpenAI if configured and Gemini fails.
  Future<String> _callGeminiOrOpenAI(String prompt) async {
    try {
      return await GeminiChatService.sendChat(
        [{'role': 'user', 'content': prompt}],
        maxTokens: 200,
        temperature: 0.3,
      );
    } catch (e) {
      if (_openAiAvailable) {
        return await _callOpenAI(prompt);
      }
      rethrow;
    }
  }

  /// Fallback: call OpenAI API (only when OPENAI_API_KEY is set and Gemini failed).
  Future<String> _callOpenAI(String prompt) async {
    try {
      final response = await _dio.post(
        '/chat/completions',
        data: {
          'model': 'gpt-4o-mini',
          'messages': [
            {'role': 'user', 'content': prompt},
          ],
          'max_tokens': 200,
        },
      );

      final content = response.data['choices'][0]['message']['content'];
      return content.toString().trim();
    } on DioException catch (e) {
      throw Exception(
        'OpenAI API error: ${e.response?.data['error']?['message'] ?? e.message}',
      );
    }
  }

  /// Log optimization to database (columns aligned with Web/Supabase: original_content, optimized_content, optimization_type 'gemini').
  Future<void> _logOptimization({
    required String originalMessage,
    required String optimizedMessage,
    required String optimizationType,
    int? characterSavings,
  }) async {
    try {
      await _supabase.from('sms_optimization_history').insert({
        'original_content': originalMessage,
        'optimized_content': optimizedMessage,
        'original_length': originalMessage.length,
        'optimized_length': optimizedMessage.length,
        'optimization_type': optimizationType,
        'parameters': {'character_savings': characterSavings},
        'created_at': DateTime.now().toIso8601String(),
      });

      // Update daily analytics
      await _updateDailyAnalytics(optimizationType);
    } catch (e) {
      debugPrint('Log optimization error: $e');
    }
  }

  /// Update daily analytics (optional; table openai_optimization_analytics may exist for legacy).
  Future<void> _updateDailyAnalytics(String optimizationType) async {
    try {
      final today = DateTime.now();
      final dateStr =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      final existing = await _supabase
          .from('openai_optimization_analytics')
          .select()
          .eq('date', dateStr)
          .maybeSingle();

      if (existing == null) {
        await _supabase.from('openai_optimization_analytics').insert({
          'date': dateStr,
          'total_optimizations': 1,
          'total_api_calls': 1,
        });
      } else {
        await _supabase
            .from('openai_optimization_analytics')
            .update({
              'total_optimizations': (existing['total_optimizations'] as int? ?? 0) + 1,
              'total_api_calls': (existing['total_api_calls'] as int? ?? 0) + 1,
            })
            .eq('date', dateStr);
      }
    } catch (e) {
      debugPrint('Update daily analytics error: $e');
    }
  }
}

/// Optimization Result
class OptimizationResult {
  final bool success;
  final String originalMessage;
  final String optimizedMessage;
  final String optimizationType;
  final int? characterSavings;
  final String? error;

  OptimizationResult({
    required this.success,
    required this.originalMessage,
    required this.optimizedMessage,
    required this.optimizationType,
    this.characterSavings,
    this.error,
  });
}

/// Tone Validation Result
class ToneValidationResult {
  final bool success;
  final String detectedTone;
  final String expectedTone;
  final bool toneMatch;
  final String? error;

  ToneValidationResult({
    required this.success,
    required this.detectedTone,
    required this.expectedTone,
    required this.toneMatch,
    this.error,
  });
}
