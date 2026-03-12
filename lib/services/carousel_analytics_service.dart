import 'dart:async';

import 'package:flutter/foundation.dart';

import './supabase_service.dart';

/// Carousel Analytics Service
/// Tracks all carousel interactions and calculates engagement metrics
class CarouselAnalyticsService {
  static CarouselAnalyticsService? _instance;
  static CarouselAnalyticsService get instance =>
      _instance ??= CarouselAnalyticsService._();

  CarouselAnalyticsService._();

  final SupabaseService _supabaseService = SupabaseService.instance;

  // ============================================
  // INTERACTION TRACKING
  // ============================================

  /// Track swipe event
  Future<void> trackSwipe({
    required String carouselType,
    required String contentType,
    required String contentId,
    required String direction, // 'left', 'right', 'up', 'down'
    required double velocity,
  }) async {
    try {
      final userId = _supabaseService.client.auth.currentUser?.id;
      if (userId == null) return;

      await _supabaseService.client.from('carousel_interactions').insert({
        'user_id': userId,
        'carousel_type': carouselType,
        'content_type': contentType,
        'content_id': contentId,
        'interaction_type': 'swipe',
        'swipe_direction': direction,
        'swipe_velocity': velocity,
        'interaction_timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Error tracking swipe: $e');
    }
  }

  /// Track content view
  Future<void> trackContentView({
    required String carouselType,
    required String contentType,
    required String contentId,
    required double viewDurationSeconds,
    required double viewportPercentage,
  }) async {
    try {
      final userId = _supabaseService.client.auth.currentUser?.id;
      if (userId == null) return;

      await _supabaseService.client.from('carousel_interactions').insert({
        'user_id': userId,
        'carousel_type': carouselType,
        'content_type': contentType,
        'content_id': contentId,
        'interaction_type': 'view',
        'view_duration_seconds': viewDurationSeconds,
        'interaction_timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Error tracking content view: $e');
    }
  }

  /// Track tap event
  Future<void> trackTap({
    required String carouselType,
    required String contentType,
    required String contentId,
    required String actionTaken, // 'view', 'play', 'join', 'vote'
  }) async {
    try {
      final userId = _supabaseService.client.auth.currentUser?.id;
      if (userId == null) return;

      await _supabaseService.client.from('carousel_interactions').insert({
        'user_id': userId,
        'carousel_type': carouselType,
        'content_type': contentType,
        'content_id': contentId,
        'interaction_type': 'tap',
        'interaction_timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Error tracking tap: $e');
    }
  }

  /// Track conversion event
  Future<void> trackConversion({
    required String carouselType,
    required String contentType,
    required String contentId,
    required String conversionType, // 'join_group', 'vote', 'follow', 'watch'
  }) async {
    try {
      final userId = _supabaseService.client.auth.currentUser?.id;
      if (userId == null) return;

      await _supabaseService.client.from('carousel_interactions').insert({
        'user_id': userId,
        'carousel_type': carouselType,
        'content_type': contentType,
        'content_id': contentId,
        'interaction_type': 'conversion',
        'converted': true,
        'interaction_timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Error tracking conversion: $e');
    }
  }

  // ============================================
  // TRENDING SCORE CALCULATION
  // ============================================

  /// Calculate trending score for content
  /// Formula: (views * 0.3) + (engagement_rate * 0.4) + (recency_factor * 0.3)
  Future<double> calculateTrendingScore({
    required String contentType,
    required String contentId,
    required int views,
    required int likes,
    required int comments,
    required int shares,
    required DateTime createdAt,
  }) async {
    // Engagement rate
    final engagementRate = views > 0
        ? ((likes + comments + shares) / views) * 100
        : 0.0;

    // Recency factor (decays over 7 days)
    final hoursSinceCreated = DateTime.now()
        .difference(createdAt)
        .inHours
        .toDouble();
    final recencyFactor = (100 - (hoursSinceCreated / 168 * 100)).clamp(0, 100);

    // Weighted trending score
    final trendingScore =
        (views * 0.3) + (engagementRate * 0.4) + (recencyFactor * 0.3);

    return trendingScore.clamp(0, 100);
  }

  /// Update trending scores for all content (scheduled job)
  Future<void> updateAllTrendingScores() async {
    try {
      // Update Jolts trending scores
      final jolts = await _supabaseService.client
          .from('carousel_content_jolts')
          .select(
            'jolt_id, views_count, likes_count, comments_count, shares_count, created_at',
          )
          .eq('is_active', true);

      for (final jolt in jolts) {
        final score = await calculateTrendingScore(
          contentType: 'jolts',
          contentId: jolt['jolt_id'],
          views: jolt['views_count'] ?? 0,
          likes: jolt['likes_count'] ?? 0,
          comments: jolt['comments_count'] ?? 0,
          shares: jolt['shares_count'] ?? 0,
          createdAt: DateTime.parse(jolt['created_at']),
        );

        await _supabaseService.client
            .from('carousel_content_jolts')
            .update({'trending_score': score})
            .eq('jolt_id', jolt['jolt_id']);
      }

      // Update Topics trending scores
      final topics = await _supabaseService.client
          .from('carousel_content_trending_topics')
          .select('topic_id, total_posts, trending_since')
          .eq('is_active', true);

      for (final topic in topics) {
        final hoursSinceTrending = DateTime.now()
            .difference(DateTime.parse(topic['trending_since']))
            .inHours;
        final growthFactor =
            (topic['total_posts'] ?? 0) / (hoursSinceTrending + 1);
        final score = (growthFactor * 10).clamp(0, 100);

        await _supabaseService.client
            .from('carousel_content_trending_topics')
            .update({'trend_score': score})
            .eq('topic_id', topic['topic_id']);
      }
    } catch (e) {
      debugPrint('Error updating trending scores: $e');
    }
  }

  // ============================================
  // ANALYTICS QUERIES
  // ============================================

  /// Get carousel performance metrics
  Future<Map<String, dynamic>> getCarouselPerformance({
    required String carouselType,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final start =
          startDate ?? DateTime.now().subtract(const Duration(days: 7));
      final end = endDate ?? DateTime.now();

      final response = await _supabaseService.client
          .from('carousel_performance_aggregated')
          .select()
          .eq('carousel_type', carouselType)
          .gte('date', start.toIso8601String())
          .lte('date', end.toIso8601String())
          .single();

      return response;
    } catch (e) {
      debugPrint('Error getting carousel performance: $e');
      return {};
    }
  }

  /// Get top performing content
  Future<List<Map<String, dynamic>>> getTopPerformingContent({
    required String contentType,
    int limit = 10,
  }) async {
    try {
      final response = await _supabaseService.client.rpc(
        'get_top_performing_content',
        params: {'p_content_type': contentType, 'p_limit': limit},
      );

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error getting top performing content: $e');
      return [];
    }
  }

  /// Get engagement metrics summary
  Future<Map<String, dynamic>> getEngagementSummary({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final start =
          startDate ?? DateTime.now().subtract(const Duration(days: 1));
      final end = endDate ?? DateTime.now();

      final response = await _supabaseService.client.rpc(
        'get_engagement_summary',
        params: {
          'p_start_date': start.toIso8601String(),
          'p_end_date': end.toIso8601String(),
        },
      );

      return response ?? {};
    } catch (e) {
      debugPrint('Error getting engagement summary: $e');
      return {
        'total_swipes': 0,
        'total_views': 0,
        'total_conversions': 0,
        'avg_view_duration': 0.0,
        'conversion_rate': 0.0,
      };
    }
  }

  /// Get conversion funnel data
  Future<Map<String, int>> getConversionFunnel({
    required String carouselType,
  }) async {
    try {
      final response = await _supabaseService.client.rpc(
        'get_conversion_funnel',
        params: {'p_carousel_type': carouselType},
      );

      return Map<String, int>.from(response ?? {});
    } catch (e) {
      debugPrint('Error getting conversion funnel: $e');
      return {'views': 0, 'interactions': 0, 'conversions': 0};
    }
  }

  /// Get swipe direction distribution
  Future<Map<String, int>> getSwipeDistribution({
    required String carouselType,
  }) async {
    try {
      final response = await _supabaseService.client
          .from('carousel_interactions')
          .select('swipe_direction')
          .eq('carousel_type', carouselType)
          .eq('interaction_type', 'swipe');

      final distribution = <String, int>{};
      for (final row in response) {
        final direction = row['swipe_direction'] as String?;
        if (direction != null) {
          distribution[direction] = (distribution[direction] ?? 0) + 1;
        }
      }

      return distribution;
    } catch (e) {
      debugPrint('Error getting swipe distribution: $e');
      return {};
    }
  }

  /// Get engagement over time
  Future<List<Map<String, dynamic>>> getEngagementOverTime({
    required String carouselType,
    int days = 7,
  }) async {
    try {
      final startDate = DateTime.now().subtract(Duration(days: days));

      final response = await _supabaseService.client
          .from('carousel_performance_aggregated')
          .select()
          .eq('carousel_type', carouselType)
          .gte('date', startDate.toIso8601String())
          .order('date', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error getting engagement over time: $e');
      return [];
    }
  }
}
