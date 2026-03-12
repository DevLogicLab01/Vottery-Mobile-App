import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/feed_ranking_service.dart';
import '../../services/supabase_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/error_boundary_wrapper.dart';
import '../../widgets/shimmer_skeleton_loader.dart';
import './widgets/ab_test_performance_widget.dart';
import './widgets/feed_metrics_chart_widget.dart';
import './widgets/ranking_explanation_widget.dart';
import './widgets/strategy_comparison_widget.dart';
import './widgets/user_assignment_widget.dart';

/// Feed Ranking Analytics Dashboard
/// A/B testing framework with performance metrics and ranking explanations
class FeedRankingAnalyticsDashboard extends StatefulWidget {
  const FeedRankingAnalyticsDashboard({super.key});

  @override
  State<FeedRankingAnalyticsDashboard> createState() =>
      _FeedRankingAnalyticsDashboardState();
}

class _FeedRankingAnalyticsDashboardState
    extends State<FeedRankingAnalyticsDashboard> {
  final FeedRankingService _feedRanking = FeedRankingService.instance;
  final SupabaseService _supabase = SupabaseService.instance;

  bool _isLoading = true;
  Map<String, dynamic>? _userAssignment;
  List<Map<String, dynamic>> _feedMetrics = [];
  List<Map<String, dynamic>> _strategyPerformance = [];
  List<Map<String, dynamic>> _personalizedFeed = [];

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);

    try {
      final userId = _supabase.client.auth.currentUser?.id;
      if (userId == null) return;

      final results = await Future.wait([
        _loadUserAssignment(userId),
        _loadFeedMetrics(),
        _loadStrategyPerformance(),
        _feedRanking.getPersonalizedFeed(contentType: 'election', limit: 10),
      ]);

      setState(() {
        _userAssignment = results[0] as Map<String, dynamic>?;
        _feedMetrics = results[1] as List<Map<String, dynamic>>;
        _strategyPerformance = results[2] as List<Map<String, dynamic>>;
        _personalizedFeed = results[3] as List<Map<String, dynamic>>;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Load dashboard data error: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<Map<String, dynamic>?> _loadUserAssignment(String userId) async {
    try {
      final assignment = await _supabase.client
          .from('ab_test_assignments')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      // If no assignment, create one randomly
      if (assignment == null) {
        final testGroups = ['control', 'algorithm_v1', 'algorithm_v2'];
        final randomGroup = testGroups[DateTime.now().millisecond % 3];

        await _supabase.client.from('ab_test_assignments').insert({
          'user_id': userId,
          'test_group': randomGroup,
        });

        return {'test_group': randomGroup};
      }

      return assignment;
    } catch (e) {
      debugPrint('Load user assignment error: $e');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> _loadFeedMetrics() async {
    try {
      final metrics = await _supabase.client
          .from('feed_performance_metrics')
          .select()
          .order('metric_date', ascending: false)
          .limit(30);

      return metrics;
    } catch (e) {
      debugPrint('Load feed metrics error: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _loadStrategyPerformance() async {
    try {
      final performance = await _supabase.client
          .from('ranking_strategy_performance')
          .select()
          .order('avg_ranking_score', ascending: false);

      return performance;
    } catch (e) {
      debugPrint('Load strategy performance error: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return ErrorBoundaryWrapper(
      screenName: 'FeedRankingAnalyticsDashboard',
      onRetry: _loadDashboardData,
      child: Scaffold(
        backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
        appBar: AppBar(
          title: Text(
            'Feed Ranking Analytics',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          backgroundColor: const Color(0xFF1976D2),
          elevation: 0,
        ),
        body: _isLoading
            ? const SkeletonDashboard()
            : RefreshIndicator(
                onRefresh: _loadDashboardData,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.all(3.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // User A/B Test Assignment
                      if (_userAssignment != null)
                        UserAssignmentWidget(assignment: _userAssignment!),
                      SizedBox(height: 2.h),

                      // A/B Test Performance Comparison
                      ABTestPerformanceWidget(metrics: _feedMetrics),
                      SizedBox(height: 2.h),

                      // Feed Metrics Chart
                      FeedMetricsChartWidget(metrics: _feedMetrics),
                      SizedBox(height: 2.h),

                      // Strategy Comparison
                      StrategyComparisonWidget(
                        strategies: _strategyPerformance,
                      ),
                      SizedBox(height: 2.h),

                      // Personalized Feed with Ranking Explanations
                      Text(
                        'Your Personalized Feed',
                        style: TextStyle(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 1.h),
                      ..._personalizedFeed.map(
                        (item) => RankingExplanationWidget(item: item),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
