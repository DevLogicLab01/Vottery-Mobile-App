import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import './supabase_service.dart';
import './auth_service.dart';

/// Service for unified analytics across marketplace, groups, and moderation
class UnifiedAnalyticsService {
  static UnifiedAnalyticsService? _instance;
  static UnifiedAnalyticsService get instance =>
      _instance ??= UnifiedAnalyticsService._();

  UnifiedAnalyticsService._();

  SupabaseClient get _client => SupabaseService.instance.client;
  AuthService get _auth => AuthService.instance;

  /// Get marketplace analytics
  Future<Map<String, dynamic>> getMarketplaceAnalytics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final start =
          startDate ?? DateTime.now().subtract(const Duration(days: 30));
      final end = endDate ?? DateTime.now();

      // Top performing services
      final topServices = await _client
          .rpc('get_top_performing_services')
          .limit(10);

      // Service demand by category
      final categoryDemand = await _client
          .from('marketplace_services')
          .select('category')
          .eq('is_active', true);

      final categoryBreakdown = <String, int>{};
      for (final service in categoryDemand) {
        final cat = service['category'] as String? ?? 'Other';
        categoryBreakdown[cat] = (categoryBreakdown[cat] ?? 0) + 1;
      }

      // Creator performance leaderboard
      final creatorMetrics = await _client
          .from('creator_performance_metrics')
          .select('*, user_profiles(full_name, avatar_url)')
          .gte('metric_date', start.toIso8601String().split('T')[0])
          .lte('metric_date', end.toIso8601String().split('T')[0])
          .order('marketplace_revenue', ascending: false)
          .limit(20);

      // Conversion funnel
      final orders = await _client
          .from('marketplace_orders')
          .select('order_status')
          .gte('ordered_at', start.toIso8601String())
          .lte('ordered_at', end.toIso8601String());

      final conversionFunnel = {
        'total_orders': orders.length,
        'in_progress': orders
            .where((o) => o['order_status'] == 'in_progress')
            .length,
        'completed': orders
            .where((o) => o['order_status'] == 'completed')
            .length,
        'cancelled': orders
            .where((o) => o['order_status'] == 'cancelled')
            .length,
      };

      return {
        'top_services': topServices ?? [],
        'category_breakdown': categoryBreakdown,
        'creator_leaderboard': creatorMetrics,
        'conversion_funnel': conversionFunnel,
      };
    } catch (e) {
      debugPrint('Get marketplace analytics error: $e');
      return {};
    }
  }

  /// Get groups analytics
  Future<Map<String, dynamic>> getGroupsAnalytics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final start =
          startDate ?? DateTime.now().subtract(const Duration(days: 30));
      final end = endDate ?? DateTime.now();

      // Member growth tracking
      final memberGrowth = await _client
          .from('group_engagement_metrics')
          .select('metric_date, new_members')
          .gte('metric_date', start.toIso8601String().split('T')[0])
          .lte('metric_date', end.toIso8601String().split('T')[0])
          .order('metric_date', ascending: true);

      // Active group rankings
      final activeGroups = await _client
          .from('group_engagement_metrics')
          .select('*, user_groups(name)')
          .gte('metric_date', start.toIso8601String().split('T')[0])
          .order('engagement_rate', ascending: false)
          .limit(10);

      // Group health scores
      final healthScores = await _client.rpc('get_group_health_scores');

      // Engagement metrics
      final engagementData = await _client
          .from('group_engagement_metrics')
          .select(
            'post_count, comment_count, event_count, event_attendance_rate',
          )
          .gte('metric_date', start.toIso8601String().split('T')[0])
          .lte('metric_date', end.toIso8601String().split('T')[0]);

      final avgPostsPerDay = engagementData.isEmpty
          ? 0.0
          : engagementData.fold<double>(
                  0,
                  (sum, m) => sum + (m['post_count'] as int? ?? 0),
                ) /
                engagementData.length;

      final avgCommentsPerPost = engagementData.isEmpty
          ? 0.0
          : engagementData.fold<double>(
                  0,
                  (sum, m) => sum + (m['comment_count'] as int? ?? 0),
                ) /
                engagementData.fold<int>(
                  0,
                  (sum, m) => sum + (m['post_count'] as int? ?? 0),
                );

      return {
        'member_growth': memberGrowth,
        'active_groups': activeGroups,
        'health_scores': healthScores ?? [],
        'avg_posts_per_day': avgPostsPerDay,
        'avg_comments_per_post': avgCommentsPerPost,
      };
    } catch (e) {
      debugPrint('Get groups analytics error: $e');
      return {};
    }
  }

  /// Get content moderation analytics
  Future<Map<String, dynamic>> getModerationAnalytics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final start =
          startDate ?? DateTime.now().subtract(const Duration(days: 30));
      final end = endDate ?? DateTime.now();

      // Violations by category
      final violations = await _client
          .from('moderation_log')
          .select('violation_categories, is_safe, removed_automatically')
          .gte('created_at', start.toIso8601String())
          .lte('created_at', end.toIso8601String());

      final violationsByCategory = <String, int>{};
      for (final log in violations) {
        if (log['is_safe'] == false) {
          final categories = log['violation_categories'] as List? ?? [];
          for (final cat in categories) {
            violationsByCategory[cat] = (violationsByCategory[cat] ?? 0) + 1;
          }
        }
      }

      final totalViolations = violations
          .where((v) => v['is_safe'] == false)
          .length;
      final autoRemoved = violations
          .where((v) => v['removed_automatically'] == true)
          .length;
      final autoRemovalRate = totalViolations > 0
          ? (autoRemoved / totalViolations) * 100
          : 0.0;

      // Appeals statistics
      final appeals = await _client
          .from('content_appeals')
          .select('status')
          .gte('submitted_at', start.toIso8601String())
          .lte('submitted_at', end.toIso8601String());

      final totalAppeals = appeals.length;
      final approvedAppeals = appeals
          .where((a) => a['status'] == 'approved')
          .length;
      final falsePositiveRate = totalAppeals > 0
          ? (approvedAppeals / totalAppeals) * 100
          : 0.0;

      // Moderator performance
      final moderatorStats = await _client
          .from('moderation_reviews')
          .select('assigned_to, reviewed_at, status')
          .not('reviewed_at', 'is', null)
          .gte('assigned_at', start.toIso8601String())
          .lte('assigned_at', end.toIso8601String());

      return {
        'violations_by_category': violationsByCategory,
        'total_violations': totalViolations,
        'auto_removal_rate': autoRemovalRate,
        'false_positive_rate': falsePositiveRate,
        'total_appeals': totalAppeals,
        'moderator_stats': moderatorStats,
      };
    } catch (e) {
      debugPrint('Get moderation analytics error: $e');
      return {};
    }
  }

  /// Get unified cross-platform insights
  Future<Map<String, dynamic>> getUnifiedInsights() async {
    try {
      // User journey tracking
      final userJourneys = await _client.rpc('get_user_journey_analytics');

      // Revenue correlation
      final revenueCorrelation = await _client.rpc('get_revenue_correlation');

      // Moderation impact
      final moderationImpact = await _client.rpc('get_moderation_impact');

      return {
        'user_journeys': userJourneys ?? {},
        'revenue_correlation': revenueCorrelation ?? {},
        'moderation_impact': moderationImpact ?? {},
      };
    } catch (e) {
      debugPrint('Get unified insights error: $e');
      return {};
    }
  }

  /// Get analytics snapshot for date
  Future<Map<String, dynamic>?> getAnalyticsSnapshot(DateTime date) async {
    try {
      final dateStr = date.toIso8601String().split('T')[0];

      final snapshot = await _client
          .from('analytics_snapshots')
          .select()
          .eq('snapshot_date', dateStr)
          .maybeSingle();

      return snapshot;
    } catch (e) {
      debugPrint('Get analytics snapshot error: $e');
      return null;
    }
  }

  /// Refresh analytics snapshot
  Future<bool> refreshAnalyticsSnapshot(DateTime date) async {
    try {
      final dateStr = date.toIso8601String().split('T')[0];

      await _client.rpc(
        'refresh_analytics_snapshot',
        params: {'p_date': dateStr},
      );

      return true;
    } catch (e) {
      debugPrint('Refresh analytics snapshot error: $e');
      return false;
    }
  }
}
