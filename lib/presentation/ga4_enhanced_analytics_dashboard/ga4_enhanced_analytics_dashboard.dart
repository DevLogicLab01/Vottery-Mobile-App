import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/ga4_analytics_service.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/error_boundary_wrapper.dart';
import '../../widgets/offline_status_badge.dart';

class Ga4EnhancedAnalyticsDashboard extends StatefulWidget {
  const Ga4EnhancedAnalyticsDashboard({super.key});

  @override
  State<Ga4EnhancedAnalyticsDashboard> createState() =>
      _Ga4EnhancedAnalyticsDashboardState();
}

class _Ga4EnhancedAnalyticsDashboardState
    extends State<Ga4EnhancedAnalyticsDashboard> {
  final GA4AnalyticsService _ga4 = GA4AnalyticsService.instance;

  bool _isLoading = true;
  Map<String, dynamic> _metrics = {};

  @override
  void initState() {
    super.initState();
    _loadMetrics();
    _ga4.trackScreenView(screenName: 'GA4 Enhanced Analytics Dashboard');
  }

  Future<void> _loadMetrics() async {
    setState(() => _isLoading = true);
    try {
      // For now, derive metrics from GA4 sessions & events proxies stored in Supabase (pre-aggregated)
      // In your backend, these should be fed by GA4 Measurement Protocol and nightly rollups.
      final client = SupabaseService.instance.client;
      final response = await client
          .from('ga4_aggregated_metrics_view')
          .select()
          .maybeSingle();

      setState(() {
        _metrics = response ?? {};
      });
    } catch (e) {
      debugPrint('Load GA4 metrics error: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ErrorBoundaryWrapper(
      screenName: 'Ga4EnhancedAnalyticsDashboard',
      onRetry: _loadMetrics,
      child: Scaffold(
        backgroundColor: AppTheme.backgroundLight,
        appBar: CustomAppBar(
          title: 'User & Election Analytics',
          variant: CustomAppBarVariant.withBack,
          actions: const [OfflineStatusBadge()],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadMetrics,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.all(4.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle(theme, 'Engagement & Participation'),
                      _buildMetricGrid([
                        _metricCard(
                          theme,
                          label: 'Participation Rate',
                          value: _formatPercent(_metrics['participation_rate']),
                        ),
                        _metricCard(
                          theme,
                          label: 'Vote Funnel Completion',
                          value:
                              _formatPercent(_metrics['vote_funnel_completion']),
                        ),
                        _metricCard(
                          theme,
                          label: 'Engagement Rate',
                          value: _formatPercent(_metrics['engagement_rate']),
                        ),
                        _metricCard(
                          theme,
                          label: 'Retention',
                          value: _formatPercent(_metrics['retention_rate']),
                        ),
                      ]),
                      SizedBox(height: 2.h),
                      _buildSectionTitle(theme, 'Virality & Growth'),
                      _buildMetricGrid([
                        _metricCard(
                          theme,
                          label: 'Virality Score',
                          value: _formatNumber(_metrics['virality_score']),
                        ),
                        _metricCard(
                          theme,
                          label: 'Audience Growth',
                          value:
                              _formatPercent(_metrics['audience_growth_rate']),
                        ),
                        _metricCard(
                          theme,
                          label: 'Share of Voice',
                          value: _formatPercent(_metrics['share_of_voice']),
                        ),
                        _metricCard(
                          theme,
                          label: 'Brand Mentions',
                          value: _formatNumber(_metrics['brand_mentions']),
                        ),
                      ]),
                      SizedBox(height: 2.h),
                      _buildSectionTitle(theme, 'Content & Watch Time'),
                      _buildMetricGrid([
                        _metricCard(
                          theme,
                          label: 'Avg Watch Time',
                          value:
                              '${_metrics['avg_watch_time_seconds'] ?? 0}s',
                        ),
                        _metricCard(
                          theme,
                          label: 'Video Views',
                          value: _formatNumber(_metrics['video_views']),
                        ),
                        _metricCard(
                          theme,
                          label: 'Story Completion',
                          value:
                              _formatPercent(_metrics['story_completion_rate']),
                        ),
                        _metricCard(
                          theme,
                          label: 'Saved Posts',
                          value: _formatNumber(_metrics['saved_posts']),
                        ),
                      ]),
                      SizedBox(height: 2.h),
                      _buildSectionTitle(theme, 'Acquisition & ROI'),
                      _buildMetricGrid([
                        _metricCard(
                          theme,
                          label: 'CTR',
                          value: _formatPercent(_metrics['click_through_rate']),
                        ),
                        _metricCard(
                          theme,
                          label: 'Conversion Rate',
                          value:
                              _formatPercent(_metrics['conversion_rate_overall']),
                        ),
                        _metricCard(
                          theme,
                          label: 'CAC',
                          value: _currency(_metrics['customer_acquisition_cost']),
                        ),
                        _metricCard(
                          theme,
                          label: 'CPC',
                          value: _currency(_metrics['cost_per_click']),
                        ),
                      ]),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildSectionTitle(ThemeData theme, String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: 1.h),
      child: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildMetricGrid(List<Widget> children) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      childAspectRatio: 1.8,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 1.5.h,
      crossAxisSpacing: 3.w,
      children: children,
    );
  }

  Widget _metricCard(ThemeData theme,
      {required String label, required String value}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: EdgeInsets.all(3.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  String _formatPercent(dynamic value) {
    if (value == null) return '0%';
    final numVal = (value as num).toDouble();
    return '${numVal.toStringAsFixed(1)}%';
    }

  String _formatNumber(dynamic value) {
    if (value == null) return '0';
    final numVal = (value as num).toInt();
    if (numVal >= 1000000) {
      return '${(numVal / 1000000).toStringAsFixed(1)}M';
    } else if (numVal >= 1000) {
      return '${(numVal / 1000).toStringAsFixed(1)}K';
    }
    return numVal.toString();
  }

  String _currency(dynamic value) {
    if (value == null) return '\$0';
    final numVal = (value as num).toDouble();
    return '\$${numVal.toStringAsFixed(2)}';
  }
}

