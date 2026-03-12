import 'dart:async';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import './supabase_service.dart';
import './claude_service.dart';

/// Carousel Performance Analytics Service
/// Tracks conversion funnels, swipe-engagement correlation, and performance regression
class CarouselPerformanceAnalyticsService {
  static CarouselPerformanceAnalyticsService? _instance;
  static CarouselPerformanceAnalyticsService get instance =>
      _instance ??= CarouselPerformanceAnalyticsService._();

  CarouselPerformanceAnalyticsService._();

  final SupabaseService _supabaseService = SupabaseService.instance;
  final ClaudeService _claudeService = ClaudeService.instance;

  // ============================================
  // FUNNEL TRACKING
  // ============================================

  /// Track funnel stage event
  Future<void> trackFunnelStage({
    required String carouselType,
    required String contentType,
    required String contentId,
    required String stageName,
    required String sessionId,
  }) async {
    try {
      final userId = _supabaseService.client.auth.currentUser?.id;
      if (userId == null) return;

      await _supabaseService.client.from('carousel_funnel_events').insert({
        'user_id': userId,
        'session_id': sessionId,
        'carousel_type': carouselType,
        'content_type': contentType,
        'content_id': contentId,
        'stage_name': stageName,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Error tracking funnel stage: $e');
    }
  }

  /// Get funnel analysis for carousel type
  Future<Map<String, dynamic>> getFunnelAnalysis({
    required String carouselType,
    String? contentType,
    int days = 7,
  }) async {
    try {
      final startDate = DateTime.now().subtract(Duration(days: days));

      final response = await _supabaseService.client
          .from('carousel_funnel_events')
          .select('stage_name')
          .eq('carousel_type', carouselType)
          .gte('timestamp', startDate.toIso8601String());

      if (response.isEmpty) {
        return _getDefaultFunnelAnalysis();
      }

      final data = response as List<dynamic>;
      final stageCounts = <String, int>{};

      for (var event in data) {
        final stage = event['stage_name'] as String;
        stageCounts[stage] = (stageCounts[stage] ?? 0) + 1;
      }

      final impressions = stageCounts['impression'] ?? 0;
      final views = stageCounts['view'] ?? 0;
      final interactions = stageCounts['interaction'] ?? 0;
      final detailViews = stageCounts['detail_view'] ?? 0;
      final conversions = stageCounts['conversion'] ?? 0;

      return {
        'carousel_type': carouselType,
        'period_days': days,
        'stage_counts': {
          'impression': impressions,
          'view': views,
          'interaction': interactions,
          'detail_view': detailViews,
          'conversion': conversions,
        },
        'conversion_rates': {
          'view_rate': impressions > 0 ? (views / impressions * 100) : 0.0,
          'interaction_rate': views > 0 ? (interactions / views * 100) : 0.0,
          'detail_rate': interactions > 0
              ? (detailViews / interactions * 100)
              : 0.0,
          'conversion_rate': detailViews > 0
              ? (conversions / detailViews * 100)
              : 0.0,
          'overall_conversion': impressions > 0
              ? (conversions / impressions * 100)
              : 0.0,
        },
        'drop_offs': {
          'impression_to_view': impressions > 0
              ? ((impressions - views) / impressions * 100)
              : 0.0,
          'view_to_interaction': views > 0
              ? ((views - interactions) / views * 100)
              : 0.0,
          'interaction_to_detail': interactions > 0
              ? ((interactions - detailViews) / interactions * 100)
              : 0.0,
          'detail_to_conversion': detailViews > 0
              ? ((detailViews - conversions) / detailViews * 100)
              : 0.0,
        },
      };
    } catch (e) {
      debugPrint('Error getting funnel analysis: $e');
      return _getDefaultFunnelAnalysis();
    }
  }

  Map<String, dynamic> _getDefaultFunnelAnalysis() {
    return {
      'carousel_type': 'unknown',
      'period_days': 7,
      'stage_counts': {
        'impression': 0,
        'view': 0,
        'interaction': 0,
        'detail_view': 0,
        'conversion': 0,
      },
      'conversion_rates': {
        'view_rate': 0.0,
        'interaction_rate': 0.0,
        'detail_rate': 0.0,
        'conversion_rate': 0.0,
        'overall_conversion': 0.0,
      },
      'drop_offs': {
        'impression_to_view': 0.0,
        'view_to_interaction': 0.0,
        'interaction_to_detail': 0.0,
        'detail_to_conversion': 0.0,
      },
    };
  }

  // ============================================
  // SWIPE-ENGAGEMENT CORRELATION
  // ============================================

  /// Analyze swipe-to-engagement correlation
  Future<Map<String, dynamic>> analyzeSwipeEngagementCorrelation({
    required String carouselType,
    int days = 30,
  }) async {
    try {
      final startDate = DateTime.now().subtract(Duration(days: days));

      final response = await _supabaseService.client
          .from('carousel_interactions')
          .select('swipe_direction, swipe_velocity, converted')
          .eq('carousel_type', carouselType)
          .eq('interaction_type', 'swipe')
          .gte('interaction_timestamp', startDate.toIso8601String());

      if (response.isEmpty) {
        return _getDefaultCorrelationAnalysis();
      }

      final data = response as List<dynamic>;
      final swipeData = <String, Map<String, dynamic>>{};

      for (var interaction in data) {
        final direction =
            interaction['swipe_direction'] as String? ?? 'unknown';
        final velocity =
            (interaction['swipe_velocity'] as num?)?.toDouble() ?? 0.0;
        final converted = interaction['converted'] as bool? ?? false;

        if (!swipeData.containsKey(direction)) {
          swipeData[direction] = {
            'count': 0,
            'total_velocity': 0.0,
            'conversions': 0,
          };
        }

        swipeData[direction]!['count'] =
            (swipeData[direction]!['count'] as int) + 1;
        swipeData[direction]!['total_velocity'] =
            (swipeData[direction]!['total_velocity'] as double) + velocity;
        if (converted) {
          swipeData[direction]!['conversions'] =
              (swipeData[direction]!['conversions'] as int) + 1;
        }
      }

      final analysis = <String, dynamic>{};
      for (var entry in swipeData.entries) {
        final direction = entry.key;
        final stats = entry.value;
        final count = stats['count'] as int;
        final avgVelocity = (stats['total_velocity'] as double) / count;
        final conversions = stats['conversions'] as int;
        final engagementRate = (conversions / count * 100);

        analysis[direction] = {
          'count': count,
          'avg_velocity': avgVelocity,
          'conversions': conversions,
          'engagement_rate': engagementRate,
        };
      }

      return {
        'carousel_type': carouselType,
        'period_days': days,
        'total_swipes': data.length,
        'by_direction': analysis,
        'insights': _generateCorrelationInsights(analysis),
      };
    } catch (e) {
      debugPrint('Error analyzing swipe-engagement correlation: $e');
      return _getDefaultCorrelationAnalysis();
    }
  }

  Map<String, dynamic> _getDefaultCorrelationAnalysis() {
    return {
      'carousel_type': 'unknown',
      'period_days': 30,
      'total_swipes': 0,
      'by_direction': {},
      'insights': [],
    };
  }

  List<String> _generateCorrelationInsights(Map<String, dynamic> analysis) {
    final insights = <String>[];

    if (analysis.containsKey('right') && analysis.containsKey('left')) {
      final rightRate = analysis['right']['engagement_rate'] as double;
      final leftRate = analysis['left']['engagement_rate'] as double;

      if (rightRate > leftRate * 1.5) {
        insights.add(
          'Right swipes show ${((rightRate / leftRate - 1) * 100).toStringAsFixed(0)}% higher engagement',
        );
      }
    }

    return insights;
  }

  // ============================================
  // PERFORMANCE REGRESSION DETECTION
  // ============================================

  /// Calculate and store performance baseline
  Future<void> calculateBaseline({
    required String carouselType,
    String? contentType,
    int days = 30,
  }) async {
    try {
      final analysis = await getFunnelAnalysis(
        carouselType: carouselType,
        contentType: contentType,
        days: days,
      );

      final conversionRates =
          analysis['conversion_rates'] as Map<String, dynamic>;
      final endDate = DateTime.now();
      final startDate = endDate.subtract(Duration(days: days));

      for (var entry in conversionRates.entries) {
        await _supabaseService.client
            .from('carousel_performance_baselines')
            .insert({
              'carousel_type': carouselType,
              'content_type': contentType,
              'metric_name': entry.key,
              'baseline_value': entry.value,
              'sample_size':
                  (analysis['stage_counts'] as Map)['impression'] ?? 0,
              'calculation_period_start': startDate.toIso8601String(),
              'calculation_period_end': endDate.toIso8601String(),
            });
      }
    } catch (e) {
      debugPrint('Error calculating baseline: $e');
    }
  }

  /// Detect performance regression
  Future<List<Map<String, dynamic>>> detectRegressions({
    required String carouselType,
    double threshold = 15.0,
  }) async {
    try {
      final currentAnalysis = await getFunnelAnalysis(
        carouselType: carouselType,
        days: 1,
      );

      final baselinesResponse = await _supabaseService.client
          .from('carousel_performance_baselines')
          .select()
          .eq('carousel_type', carouselType)
          .order('calculated_at', ascending: false)
          .limit(10);

      if (baselinesResponse.isEmpty) {
        return [];
      }

      final baselines = baselinesResponse as List<dynamic>;
      final regressions = <Map<String, dynamic>>[];
      final currentRates =
          currentAnalysis['conversion_rates'] as Map<String, dynamic>;

      for (var baseline in baselines) {
        final metricName = baseline['metric_name'] as String;
        final baselineValue = (baseline['baseline_value'] as num).toDouble();
        final currentValue =
            (currentRates[metricName] as num?)?.toDouble() ?? 0.0;

        if (baselineValue > 0) {
          final regressionPct =
              ((baselineValue - currentValue) / baselineValue * 100);

          if (regressionPct > threshold) {
            final alertData = {
              'carousel_type': carouselType,
              'metric_name': metricName,
              'baseline_value': baselineValue,
              'current_value': currentValue,
              'regression_percentage': regressionPct,
              'severity': _determineSeverity(regressionPct),
            };

            await _supabaseService.client
                .from('carousel_performance_alerts')
                .insert(alertData);

            regressions.add(alertData);
          }
        }
      }

      return regressions;
    } catch (e) {
      debugPrint('Error detecting regressions: $e');
      return [];
    }
  }

  String _determineSeverity(double regressionPct) {
    if (regressionPct > 30) return 'critical';
    if (regressionPct > 20) return 'major';
    if (regressionPct > 15) return 'moderate';
    return 'minor';
  }

  /// Get active performance alerts
  Future<List<Map<String, dynamic>>> getActiveAlerts() async {
    try {
      final response = await _supabaseService.client
          .from('carousel_performance_alerts')
          .select()
          .eq('status', 'active')
          .order('detected_at', ascending: false);

      return (response as List<dynamic>).cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('Error getting active alerts: $e');
      return [];
    }
  }

  /// Analyze regression root cause with Claude AI
  Future<Map<String, dynamic>> analyzeRegressionRootCause({
    required String alertId,
    required Map<String, dynamic> alertData,
  }) async {
    try {
      final prompt =
          '''
Analyze this carousel performance regression:

Carousel Type: ${alertData['carousel_type']}
Metric: ${alertData['metric_name']}
Baseline: ${alertData['baseline_value']}%
Current: ${alertData['current_value']}%
Regression: ${alertData['regression_percentage']}%

Provide analysis in JSON format:
{
  "likely_causes": ["cause1", "cause2"],
  "recommended_actions": ["action1", "action2"],
  "estimated_impact": "high|medium|low"
}
''';

      final responseString = await _claudeService.callClaudeAPI(prompt);
      // Parse the JSON string response to Map
      final response = jsonDecode(responseString) as Map<String, dynamic>;
      return response;
    } catch (e) {
      debugPrint('Error analyzing root cause: $e');
      return {
        'likely_causes': ['Unknown'],
        'recommended_actions': ['Investigate manually'],
        'estimated_impact': 'medium',
      };
    }
  }
}