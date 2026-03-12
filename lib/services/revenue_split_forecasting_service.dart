import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'ai/ai_service_base.dart';

/// Revenue Split Forecasting Service (Mobile).
///
/// Calls the shared `ai-proxy` Supabase Edge Function (Anthropic Claude)
/// to generate split optimization recommendations for the Platform Optimization panel.
/// Mirrors Web revenueSplitForecastingService.generateClaudeOptimizations.
class RevenueSplitForecastingService {
  RevenueSplitForecastingService._();

  static RevenueSplitForecastingService? _instance;
  static RevenueSplitForecastingService get instance =>
      _instance ??= RevenueSplitForecastingService._();

  /// Generate Claude optimization suggestions for revenue split.
  /// [currentSplit] e.g. { creatorPercentage: 70, platformPercentage: 30 }
  /// [historicalData] optional list of historical performance records.
  Future<Map<String, dynamic>?> generateClaudeOptimizations(
    Map<String, dynamic> currentSplit, [
    Map<String, dynamic>? options,
  ]) async {
    try {
      final historical = options?['historical'] as List<dynamic>? ?? [];
      final prompt = '''
You are a strategic revenue optimization expert. Analyze the current revenue split and historical performance data to provide actionable optimization suggestions.

Current Split:
Creator: ${currentSplit['creatorPercentage'] ?? 70}%
Platform: ${currentSplit['platformPercentage'] ?? 30}%

Historical Performance:
${jsonEncode(historical)}

Provide:
1. Optimal revenue split recommendations with reasoning
2. Strategic timing for split changes
3. Creator morale impact predictions
4. Platform sustainability analysis
5. Risk assessment for each recommendation
6. Implementation roadmap

Format as JSON with keys: recommendations (array with title, newSplit, reasoning, impact, risk, confidence), strategicTiming, implementationSteps
''';

      final response = await AIServiceBase.invokeWithRetry('ai-proxy', {
        'provider': 'anthropic',
        'method': 'messages',
        'payload': {
          'messages': [
            {'role': 'user', 'content': prompt}
          ],
          'model': 'claude-3-5-sonnet-20241022',
          'max_tokens': 4096,
          'temperature': 0.7,
        },
      });

      String rawText;
      try {
        final content = response['content'];
        if (content is List && content.isNotEmpty) {
          final first = content.first;
          if (first is Map && first['text'] is String) {
            rawText = first['text'] as String;
          } else {
            rawText = response.toString();
          }
        } else {
          rawText = response.toString();
        }
      } catch (e) {
        debugPrint(
            'RevenueSplitForecastingService: fallback to response.toString(): $e');
        rawText = response.toString();
      }

      try {
        return jsonDecode(rawText) as Map<String, dynamic>;
      } catch (e) {
        debugPrint(
            'RevenueSplitForecastingService: JSON parse error: $e');
        return null;
      }
    } catch (e) {
      debugPrint('RevenueSplitForecastingService error: $e');
      return null;
    }
  }
}
