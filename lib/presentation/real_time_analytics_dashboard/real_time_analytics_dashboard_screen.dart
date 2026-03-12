import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/platform_analytics_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/error_boundary_wrapper.dart';

/// Dedicated Real-Time Analytics Dashboard: KPIs, engagement, elections, revenue, ad ROI, 30s refresh.
class RealTimeAnalyticsDashboardScreen extends StatefulWidget {
  const RealTimeAnalyticsDashboardScreen({super.key});

  @override
  State<RealTimeAnalyticsDashboardScreen> createState() =>
      _RealTimeAnalyticsDashboardScreenState();
}

class _RealTimeAnalyticsDashboardScreenState
    extends State<RealTimeAnalyticsDashboardScreen> {
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
          _engagement = results[0] as Map<String, dynamic>;
          _elections = results[1] as Map<String, dynamic>;
          _revenue = results[2] as Map<String, dynamic>;
          _adRoi = results[3] as Map<String, dynamic>;
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
      screenName: 'RealTimeAnalyticsDashboard',
      onRetry: () => _loadAll(),
      child: Scaffold(
        backgroundColor: AppTheme.backgroundLight,
        appBar: CustomAppBar(
          title: 'Real-Time Analytics',
          variant: CustomAppBarVariant.withBack,
          actions: [
            Padding(
              padding: EdgeInsets.only(right: 4.w),
              child: DropdownButton<String>(
                value: _timeRange,
                underline: const SizedBox(),
                items: const [
                  DropdownMenuItem(value: '24h', child: Text('24h')),
                  DropdownMenuItem(value: '7d', child: Text('7d')),
                  DropdownMenuItem(value: '30d', child: Text('30d')),
                ],
                onChanged: (v) {
                  if (v != null) {
                    setState(() => _timeRange = v);
                    _loadAll();
                  }
                },
              ),
            ),
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
                        'KPI Overview (auto-refresh 30s)',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      _metricGrid(theme, [
                        _card('Active Users', '${_engagement['activeUsers'] ?? 0}', Icons.people),
                        _card('Total Posts', '${_engagement['totalPosts'] ?? 0}', Icons.article),
                        _card('Engagement Rate', '${(_engagement['engagementRate'] ?? 0).toStringAsFixed(1)}%', Icons.trending_up),
                        _card('Active Elections', '${_elections['activeElections'] ?? 0}', Icons.how_to_vote),
                        _card('Total Votes', '${_elections['totalVotes'] ?? 0}', Icons.check_circle),
                        _card('Participation %', '${(_elections['participationRate'] ?? 0).toStringAsFixed(1)}%', Icons.percent),
                        _card('Revenue', '\$${(_revenue['totalRevenue'] ?? 0).toStringAsFixed(0)}', Icons.attach_money),
                        _card('Ad Engagements', '${_adRoi['totalEngagements'] ?? 0}', Icons.campaign),
                      ]),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _metricGrid(ThemeData theme, List<Widget> cards) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 2.h,
      crossAxisSpacing: 3.w,
      childAspectRatio: 1.4,
      children: cards,
    );
  }

  Widget _card(String label, String value, IconData icon) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 22.sp, color: AppTheme.primaryLight),
            SizedBox(height: 1.h),
            Text(
              value,
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryLight,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 11.sp,
                color: AppTheme.textSecondaryLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
