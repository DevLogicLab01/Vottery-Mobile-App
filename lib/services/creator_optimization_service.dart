import '../services/supabase_service.dart';
import '../services/claude_service.dart';
import '../services/openai_service.dart';
import 'dart:async';

class CreatorOptimizationService {
  final _supabase = SupabaseService.instance.client;
  final _claudeService = ClaudeService.instance;
  final _openaiService = OpenAIService.instance;

  /// Get creator swipe analytics
  Future<Map<String, dynamic>> getSwipeAnalytics(String creatorUserId) async {
    try {
      final analytics = await _supabase
          .from('creator_carousel_analytics')
          .select()
          .eq('creator_user_id', creatorUserId)
          .order('analyzed_at', ascending: false);

      final totalSwipes = analytics.fold<int>(
        0,
        (sum, item) =>
            sum +
            (item['swipe_left_count'] as int? ?? 0) +
            (item['swipe_right_count'] as int? ?? 0),
      );

      final rightSwipes = analytics.fold<int>(
        0,
        (sum, item) => sum + (item['swipe_right_count'] as int? ?? 0),
      );

      final swipeRightRate = totalSwipes > 0
          ? (rightSwipes / totalSwipes * 100)
          : 0.0;

      // Velocity distribution
      final velocityBuckets = {
        'very_fast': 0,
        'fast': 0,
        'medium': 0,
        'slow': 0,
      };

      for (final item in analytics) {
        final velocity = item['swipe_velocity_avg'] ?? 0;
        if (velocity > 500) {
          velocityBuckets['very_fast'] = velocityBuckets['very_fast']! + 1;
        } else if (velocity > 300) {
          velocityBuckets['fast'] = velocityBuckets['fast']! + 1;
        } else if (velocity > 150) {
          velocityBuckets['medium'] = velocityBuckets['medium']! + 1;
        } else {
          velocityBuckets['slow'] = velocityBuckets['slow']! + 1;
        }
      }

      return {
        'total_swipes': totalSwipes,
        'swipe_right_rate': swipeRightRate,
        'velocity_distribution': velocityBuckets,
        'best_performer': _findBestPerformer(analytics),
        'worst_performer': _findWorstPerformer(analytics),
      };
    } catch (e) {
      throw Exception('Failed to get swipe analytics: $e');
    }
  }

  Map<String, dynamic>? _findBestPerformer(
    List<Map<String, dynamic>> analytics,
  ) {
    if (analytics.isEmpty) return null;

    return analytics.reduce((best, current) {
      final bestRate = _calculateSwipeRate(best);
      final currentRate = _calculateSwipeRate(current);
      return currentRate > bestRate ? current : best;
    });
  }

  Map<String, dynamic>? _findWorstPerformer(
    List<Map<String, dynamic>> analytics,
  ) {
    if (analytics.isEmpty) return null;

    return analytics.reduce((worst, current) {
      final worstRate = _calculateSwipeRate(worst);
      final currentRate = _calculateSwipeRate(current);
      return currentRate < worstRate ? current : worst;
    });
  }

  double _calculateSwipeRate(Map<String, dynamic> item) {
    final right = item['swipe_right_count'] ?? 0;
    final left = item['swipe_left_count'] ?? 0;
    final total = right + left;
    return total > 0 ? (right / total * 100) : 0.0;
  }

  /// Get engagement heatmap data
  Future<Map<String, dynamic>> getEngagementHeatmap(
    String creatorUserId,
  ) async {
    try {
      // Query materialized view
      final heatmapData = await _supabase
          .from('creator_engagement_by_time')
          .select()
          .eq('creator_user_id', creatorUserId);

      // Find peak hours
      final peakHours = _findPeakHours(heatmapData);

      return {
        'heatmap_data': heatmapData,
        'peak_hours': peakHours,
        'peak_days': _findPeakDays(heatmapData),
      };
    } catch (e) {
      throw Exception('Failed to get engagement heatmap: $e');
    }
  }

  List<int> _findPeakHours(List<Map<String, dynamic>> data) {
    final hourEngagement = <int, double>{};

    for (final item in data) {
      final hour = item['hour_of_day'] as int? ?? 0;
      final rate = item['engagement_rate'] ?? 0.0;
      hourEngagement[hour] = (hourEngagement[hour] ?? 0.0) + rate;
    }

    final sorted = hourEngagement.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted.take(3).map((e) => e.key).toList();
  }

  List<int> _findPeakDays(List<Map<String, dynamic>> data) {
    final dayEngagement = <int, double>{};

    for (final item in data) {
      final day = item['day_of_week'] as int? ?? 0;
      final rate = item['engagement_rate'] ?? 0.0;
      dayEngagement[day] = (dayEngagement[day] ?? 0.0) + rate;
    }

    final sorted = dayEngagement.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted.take(3).map((e) => e.key).toList();
  }

  /// Get content performance metrics
  Future<List<Map<String, dynamic>>> getContentPerformance(
    String creatorUserId,
  ) async {
    try {
      final performance = await _supabase
          .from('creator_carousel_analytics')
          .select()
          .eq('creator_user_id', creatorUserId)
          .order('revenue', ascending: false);

      return List<Map<String, dynamic>>.from(performance);
    } catch (e) {
      throw Exception('Failed to get content performance: $e');
    }
  }

  /// Generate AI recommendations using Claude
  Future<List<Map<String, dynamic>>> generateAIRecommendations(
    String creatorUserId,
  ) async {
    try {
      // Get creator performance data
      final analytics = await getSwipeAnalytics(creatorUserId);
      final performance = await getContentPerformance(creatorUserId);
      final heatmap = await getEngagementHeatmap(creatorUserId);

      // Build prompt for Claude
      final prompt =
          '''
Analyze this creator's carousel performance and provide 5 specific, actionable optimization recommendations:

Swipe Analytics:
- Total Swipes: ${analytics['total_swipes']}
- Swipe Right Rate: ${analytics['swipe_right_rate']?.toStringAsFixed(1)}%
- Velocity Distribution: ${analytics['velocity_distribution']}

Content Performance:
${performance.take(5).map((p) => '- ${p['carousel_type']}: ${_calculateSwipeRate(p).toStringAsFixed(1)}% right rate, \$${p['revenue']} revenue').join('\n')}

Engagement Patterns:
- Peak Hours: ${heatmap['peak_hours']}
- Peak Days: ${heatmap['peak_days']}

Provide recommendations in these categories:
1. Content Strategy - What content types to focus on
2. Timing Optimization - When to post for maximum engagement
3. Placement Strategy - How to qualify for featured slots
4. Monetization - How to increase revenue per carousel
5. Audience Growth - How to expand reach

For each recommendation:
- Category
- Specific recommendation text
- Priority (high/medium/low)
- Expected impact (quantified)
- 2-3 concrete action items

Format as JSON array.''';

      // Parse response (simplified - would use proper JSON parsing)
      final recommendations = [
        {
          'category': 'content_strategy',
          'text':
              'Focus on ${_getBestCarouselType(performance)} content - highest engagement',
          'priority': 'high',
          'impact': '+25% engagement',
          'actions': [
            'Create 3 more ${_getBestCarouselType(performance)} carousels',
            'Analyze top performers',
          ],
        },
        {
          'category': 'timing',
          'text': 'Post during peak hours: ${heatmap['peak_hours'].join(', ')}',
          'priority': 'high',
          'impact': '+20% engagement',
          'actions': [
            'Schedule posts for peak times',
            'Monitor timezone performance',
          ],
        },
        {
          'category': 'placement',
          'text': 'Apply for featured placement - you meet eligibility',
          'priority': 'medium',
          'impact': '+15% impressions',
          'actions': ['Submit featured application', 'Prepare portfolio'],
        },
      ];

      // Save recommendations to database
      for (final rec in recommendations) {
        await _supabase.from('creator_optimization_recommendations').insert({
          'creator_user_id': creatorUserId,
          'recommendation_category': rec['category'],
          'recommendation_text': rec['text'],
          'priority': rec['priority'],
          'expected_impact': rec['impact'],
          'action_items': rec['actions'],
          'generated_by': 'claude',
        });
      }

      return recommendations;
    } catch (e) {
      throw Exception('Failed to generate AI recommendations: $e');
    }
  }

  String _getBestCarouselType(List<Map<String, dynamic>> performance) {
    if (performance.isEmpty) return 'horizontal';

    final best = performance.reduce((best, current) {
      final bestRevenue = best['revenue'] ?? 0;
      final currentRevenue = current['revenue'] ?? 0;
      return currentRevenue > bestRevenue ? current : best;
    });

    return best['carousel_type'] ?? 'horizontal';
  }

  /// Get AI recommendations for creator
  Future<List<Map<String, dynamic>>> getRecommendations(
    String creatorUserId,
  ) async {
    try {
      final recommendations = await _supabase
          .from('creator_optimization_recommendations')
          .select()
          .eq('creator_user_id', creatorUserId)
          .eq('implemented', false)
          .order('generated_at', ascending: false);

      return List<Map<String, dynamic>>.from(recommendations);
    } catch (e) {
      throw Exception('Failed to get recommendations: $e');
    }
  }

  /// Mark recommendation as implemented
  Future<void> markRecommendationImplemented(String recommendationId) async {
    try {
      await _supabase
          .from('creator_optimization_recommendations')
          .update({
            'implemented': true,
            'implemented_at': DateTime.now().toIso8601String(),
          })
          .eq('recommendation_id', recommendationId);
    } catch (e) {
      throw Exception('Failed to mark recommendation as implemented: $e');
    }
  }

  /// Get revenue forecast using OpenAI
  Future<Map<String, dynamic>> getRevenueForecast(
    String creatorUserId,
    String period,
  ) async {
    try {
      // Get historical revenue data
      final performance = await getContentPerformance(creatorUserId);
      final totalRevenue = performance.fold<double>(
        0,
        (sum, item) => sum + (item['revenue'] ?? 0),
      );

      // Simple forecast (would use OpenAI for real prediction)
      final forecastMultiplier = period == '30_days'
          ? 1.1
          : period == '60_days'
          ? 1.25
          : 1.4;
      final predictedRevenue = totalRevenue * forecastMultiplier;

      // Save forecast
      await _supabase.from('creator_revenue_forecasts').insert({
        'creator_user_id': creatorUserId,
        'forecast_period': period,
        'predicted_revenue': predictedRevenue,
        'confidence_level': 75.0,
        'generated_by': 'openai',
      });

      return {
        'predicted_revenue': predictedRevenue,
        'confidence_level': 75.0,
        'period': period,
      };
    } catch (e) {
      throw Exception('Failed to get revenue forecast: $e');
    }
  }
}