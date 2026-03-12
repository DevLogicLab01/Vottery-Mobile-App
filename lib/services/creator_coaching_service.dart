import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'ai/ai_service_base.dart';
import 'enhanced_revenue_analytics_service.dart';

/// Mobile Creator Coaching service.
///
/// Uses existing revenue analytics snapshots and the shared `ai-proxy`
/// Supabase Edge Function (Anthropic Claude) to generate a lightweight
/// coaching summary plus prioritized recommendations for creators.
class CreatorCoachingService {
  CreatorCoachingService._();

  static CreatorCoachingService? _instance;
  static CreatorCoachingService get instance =>
      _instance ??= CreatorCoachingService._();

  final EnhancedRevenueAnalyticsService _analytics =
      EnhancedRevenueAnalyticsService.instance;

  /// Fetches creator analytics and asks Claude for a concise coaching plan.
  Future<CreatorCoachingResult> getCoachingSummary() async {
    try {
      // Gather existing analytics (all server-side; no new tables needed)
      final breakdown = await _analytics.getRevenueBreakdown();
      final trends = await _analytics.getHistoricalTrends();
      final performance = await _analytics.getPerformanceMetrics();
      final taxPreview = await _analytics.getTaxLiabilityPreview();

      final context = <String, dynamic>{
        'breakdown': breakdown,
        'historical_trends': trends.take(6).toList(),
        'performance_metrics': performance,
        'tax_preview': taxPreview,
      };

      final prompt = '''
You are an experienced creator monetization coach for a social platform called Vottery.

Use the JSON analytics below to generate a concise, mobile-friendly coaching summary
for the creator. Focus on: earning optimization, content strategy, and payout stability.

Return a JSON object with:
- "summary": short 2-3 sentence overview
- "priority_insights": array of 3-5 items, each with:
  - "title": short headline
  - "description": 2-4 sentence explanation
  - "impact": "low" | "medium" | "high"
  - "timeframe": "this week" | "this month" | "next 90 days"
- "next_steps": array of 3-6 concrete bullet-point style strings

Creator analytics:
${jsonEncode(context)}
''';

      final response = await AIServiceBase.invokeWithRetry('ai-proxy', {
        'provider': 'anthropic',
        'method': 'creator-coaching',
        'payload': {
          'model': 'claude-3-5-sonnet-20241022',
          'messages': [
            {
              'role': 'user',
              'content': prompt,
            }
          ],
          'max_tokens': 900,
          'temperature': 0.4,
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
        debugPrint('CreatorCoachingService: fallback to response.toString(): $e');
        rawText = response.toString();
      }

      Map<String, dynamic> parsed;
      try {
        parsed = jsonDecode(rawText) as Map<String, dynamic>;
      } catch (e) {
        debugPrint('CreatorCoachingService: JSON parse error, returning raw text: $e');
        parsed = {
          'summary': rawText,
          'priority_insights': const [],
          'next_steps': const [],
        };
      }

      final summary = (parsed['summary'] as String?)?.trim() ?? '';
      final insightsRaw = parsed['priority_insights'] as List<dynamic>? ?? const [];
      final nextStepsRaw = parsed['next_steps'] as List<dynamic>? ?? const [];

      final insights = insightsRaw
          .whereType<Map>()
          .map((m) => Map<String, dynamic>.from(m))
          .toList();

      final nextSteps = nextStepsRaw
          .map((e) => e.toString())
          .where((s) => s.trim().isNotEmpty)
          .toList();

      return CreatorCoachingResult(
        summary: summary,
        priorityInsights: insights,
        nextSteps: nextSteps,
      );
    } catch (e, stack) {
      debugPrint('CreatorCoachingService error: $e\n$stack');
      // Safe fallback for UI
      return const CreatorCoachingResult(
        summary:
            'We could not load personalized coaching right now. Try again in a moment.',
        priorityInsights: [],
        nextSteps: [],
      );
    }
  }
}

class CreatorCoachingResult {
  final String summary;
  final List<Map<String, dynamic>> priorityInsights;
  final List<String> nextSteps;

  const CreatorCoachingResult({
    required this.summary,
    required this.priorityInsights,
    required this.nextSteps,
  });
}

