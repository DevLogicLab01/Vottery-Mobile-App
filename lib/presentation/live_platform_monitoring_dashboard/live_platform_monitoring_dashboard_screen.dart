import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/platform_analytics_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/error_boundary_wrapper.dart';

/// Live Platform Monitoring: active users, concurrent elections, revenue, ad performance, 30s refresh.
class LivePlatformMonitoringDashboardScreen extends StatefulWidget {
  const LivePlatformMonitoringDashboardScreen({super.key});

  @override
  State<LivePlatformMonitoringDashboardScreen> createState() =>
      _LivePlatformMonitoringDashboardScreenState();
}

class _LivePlatformMonitoringDashboardScreenState
    extends State<LivePlatformMonitoringDashboardScreen> {
  final PlatformAnalyticsService _analytics =
      PlatformAnalyticsService.instance;

  bool _loading = true;
  String _timeRange = '24h';
  Map<String, dynamic> _engagement = {};
  Map<String, dynamic> _elections = {};
  Map<String, dynamic> _revenue = {};
  Map<String, dynamic> _adRoi = {};
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadAll();
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) _loadAll(silent: true);
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadAll({bool silent = false}) async {
    if (!silent) setState(() => _loading = true);
    try {
      final results = await Future.wait([
        _analytics.getEngagementMetrics(timeRange: _timeRange),
        _analytics.getElectionPerformance(timeRange: _timeRange),
        _analytics.getRevenueMetrics(timeRange: _timeRange),
        _analytics.getAdROIMetrics(timeRange: _timeRange),
      ]);
      if (mounted) {
        setState(() {
          _engagement = results[0];
          _elections = results[1];
          _revenue = results[2];
          _adRoi = results[3];
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ErrorBoundaryWrapper(
      screenName: 'LivePlatformMonitoringDashboard',
      onRetry: () => _loadAll(),
      child: Scaffold(
        backgroundColor: AppTheme.backgroundLight,
        appBar: CustomAppBar(
          title: 'Live Platform Monitoring',
          variant: CustomAppBarVariant.withBack,
          actions: [
            Icon(Icons.refresh, size: 22.sp),
            SizedBox(width: 2.w),
          ],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadAll,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.all(4.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Platform metrics (30s refresh)',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      _section(theme, 'Active Users & Engagement', [
                        _tile('Active Users', '${_engagement['activeUsers'] ?? 0}'),
                        _tile('Total Posts', '${_engagement['totalPosts'] ?? 0}'),
                        _tile('Likes / Comments / Shares', '${_engagement['totalLikes'] ?? 0} / ${_engagement['totalComments'] ?? 0} / ${_engagement['totalShares'] ?? 0}'),
                        _tile('Engagement Rate', '${(_engagement['engagementRate'] ?? 0).toStringAsFixed(2)}'),
                      ]),
                      _section(theme, 'Concurrent Elections', [
                        _tile('Active Elections', '${_elections['activeElections'] ?? 0}'),
                        _tile('Completed (period)', '${_elections['completedElections'] ?? 0}'),
                        _tile('Total Votes', '${_elections['totalVotes'] ?? 0}'),
                      ]),
                      _section(theme, 'Revenue Streams', [
                        _tile('Revenue (period)', '\$${(_revenue['totalRevenue'] ?? 0).toStringAsFixed(2)}'),
                        _tile('Transactions', '${_revenue['transactionCount'] ?? 0}'),
                      ]),
                      _section(theme, 'Ad Campaign Performance', [
                        _tile('Total Spend', '\$${(_adRoi['totalSpend'] ?? 0).toStringAsFixed(2)}'),
                        _tile('Engagements', '${_adRoi['totalEngagements'] ?? 0}'),
                        _tile('ROI (engagement/spend)', '${(_adRoi['roi'] ?? 0).toStringAsFixed(2)}'),
                      ]),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _section(ThemeData theme, String title, List<Widget> tiles) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(bottom: 1.h),
          child: Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryLight,
            ),
          ),
        ),
        Card(
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(children: tiles),
        ),
        SizedBox(height: 2.h),
      ],
    );
  }

  Widget _tile(String label, String value) {
    return ListTile(
      title: Text(label, style: TextStyle(fontSize: 12.sp)),
      trailing: Text(
        value,
        style: TextStyle(
          fontSize: 13.sp,
          fontWeight: FontWeight.w600,
          color: AppTheme.textPrimaryLight,
        ),
      ),
    );
  }
}
