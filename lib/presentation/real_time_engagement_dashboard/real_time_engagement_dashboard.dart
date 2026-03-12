import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'dart:async';
import '../../services/supabase_service.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/error_boundary_wrapper.dart';
import '../../widgets/shimmer_skeleton_loader.dart';
import './widgets/live_metrics_header_widget.dart';
import './widgets/active_users_card_widget.dart';
import './widgets/votes_cast_card_widget.dart';
import './widgets/vp_earned_card_widget.dart';
import './widgets/quests_completed_card_widget.dart';
import './widgets/top_elections_widget.dart';
import './widgets/top_creators_widget.dart';
import './widgets/conversion_funnel_widget.dart';

class RealTimeEngagementDashboard extends StatefulWidget {
  const RealTimeEngagementDashboard({super.key});

  @override
  State<RealTimeEngagementDashboard> createState() =>
      _RealTimeEngagementDashboardState();
}

class _RealTimeEngagementDashboardState
    extends State<RealTimeEngagementDashboard> {
  Timer? _refreshTimer;
  bool _isLoading = true;
  DateTime _lastRefresh = DateTime.now();

  Map<String, dynamic> _liveMetrics = {};
  List<Map<String, dynamic>> _topElections = [];
  List<Map<String, dynamic>> _topCreators = [];
  Map<String, dynamic> _conversionFunnels = {};

  @override
  void initState() {
    super.initState();
    _loadData();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _startAutoRefresh() {
    // Auto-refresh every 30 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        _getLiveMetrics(),
        _getTopElections(),
        _getTopCreators(),
        _getConversionFunnels(),
      ]);

      setState(() {
        _liveMetrics = results[0] as Map<String, dynamic>;
        _topElections = results[1] as List<Map<String, dynamic>>;
        _topCreators = results[2] as List<Map<String, dynamic>>;
        _conversionFunnels = results[3] as Map<String, dynamic>;
        _lastRefresh = DateTime.now();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading data: $e')));
      }
    }
  }

  Future<Map<String, dynamic>> _getLiveMetrics() async {
    try {
      final response = await SupabaseService.instance.client.rpc(
        'get_live_engagement_metrics',
      );

      return Map<String, dynamic>.from(response ?? {});
    } catch (e) {
      debugPrint('Get live metrics error: $e');
      return {};
    }
  }

  Future<List<Map<String, dynamic>>> _getTopElections() async {
    try {
      final response = await SupabaseService.instance.client.rpc(
        'get_top_active_elections',
        params: {'result_limit': 5},
      );

      return List<Map<String, dynamic>>.from(response ?? []);
    } catch (e) {
      debugPrint('Get top elections error: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _getTopCreators() async {
    try {
      final response = await SupabaseService.instance.client.rpc(
        'get_top_active_creators',
        params: {'result_limit': 5},
      );

      return List<Map<String, dynamic>>.from(response ?? []);
    } catch (e) {
      debugPrint('Get top creators error: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> _getConversionFunnels() async {
    try {
      final response = await SupabaseService.instance.client.rpc(
        'get_conversion_funnel_metrics',
      );

      return Map<String, dynamic>.from(response ?? {});
    } catch (e) {
      debugPrint('Get conversion funnels error: $e');
      return {};
    }
  }

  @override
  Widget build(BuildContext context) {
    return ErrorBoundaryWrapper(
      screenName: 'Real-Time Engagement',
      child: Scaffold(
        appBar: CustomAppBar(
          title: 'Real-Time Engagement',
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadData,
              tooltip: 'Refresh',
            ),
          ],
        ),
        body: _isLoading
            ? const ShimmerSkeletonLoader(child: SizedBox.expand())
            : RefreshIndicator(
                onRefresh: _loadData,
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(3.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Live Metrics Header
                      LiveMetricsHeaderWidget(lastRefresh: _lastRefresh),
                      SizedBox(height: 2.h),

                      // Metric Cards Grid
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 2.w,
                        mainAxisSpacing: 2.h,
                        childAspectRatio: 1.5,
                        children: [
                          ActiveUsersCardWidget(
                            count: _liveMetrics['active_users_5min'] ?? 0,
                            trend: _liveMetrics['active_users_trend'] ?? 0.0,
                          ),
                          VotesCastCardWidget(
                            count: _liveMetrics['votes_last_hour'] ?? 0,
                            velocity: _liveMetrics['vote_velocity'] ?? 0.0,
                          ),
                          VpEarnedCardWidget(
                            amount: _liveMetrics['vp_earned_last_hour'] ?? 0,
                            breakdown: _liveMetrics['vp_breakdown'] ?? {},
                          ),
                          QuestsCompletedCardWidget(
                            count: _liveMetrics['quests_last_hour'] ?? 0,
                            completionRate:
                                _liveMetrics['quest_completion_rate'] ?? 0.0,
                          ),
                        ],
                      ),
                      SizedBox(height: 3.h),

                      // Top 5 Active Elections
                      TopElectionsWidget(elections: _topElections),
                      SizedBox(height: 3.h),

                      // Top 5 Active Creators
                      TopCreatorsWidget(creators: _topCreators),
                      SizedBox(height: 3.h),

                      // Conversion Funnels
                      ConversionFunnelWidget(funnels: _conversionFunnels),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
