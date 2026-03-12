import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class LiveMonitoringDashboardWidget extends StatelessWidget {
  final Map<String, dynamic> engagementMetrics;
  final Map<String, dynamic> distributionEffectiveness;
  final VoidCallback onRefresh;

  const LiveMonitoringDashboardWidget({
    super.key,
    required this.engagementMetrics,
    required this.distributionEffectiveness,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: ListView(
        padding: EdgeInsets.all(4.w),
        children: [
          _buildEngagementMetricsSection(context),
          SizedBox(height: 2.h),
          _buildDistributionEffectivenessSection(context),
          SizedBox(height: 2.h),
          _buildPlatformHealthSection(context),
        ],
      ),
    );
  }

  Widget _buildEngagementMetricsSection(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.trending_up, color: theme.colorScheme.primary),
                SizedBox(width: 2.w),
                Text(
                  'Engagement Metrics',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 2.h),
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    context,
                    'User Satisfaction',
                    '${engagementMetrics['user_satisfaction']?.toStringAsFixed(1) ?? '0'}%',
                    Icons.sentiment_satisfied,
                    Colors.green,
                  ),
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: _buildMetricCard(
                    context,
                    'Engagement Rate',
                    '${engagementMetrics['engagement_rate']?.toStringAsFixed(1) ?? '0'}%',
                    Icons.touch_app,
                    Colors.blue,
                  ),
                ),
              ],
            ),
            SizedBox(height: 2.h),
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    context,
                    'Retention Rate',
                    '${engagementMetrics['retention_rate']?.toStringAsFixed(1) ?? '0'}%',
                    Icons.repeat,
                    Colors.purple,
                  ),
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: _buildMetricCard(
                    context,
                    'Avg Session',
                    '${engagementMetrics['avg_session_duration']?.toStringAsFixed(1) ?? '0'}m',
                    Icons.timer,
                    Colors.orange,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDistributionEffectivenessSection(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.analytics, color: theme.colorScheme.primary),
                SizedBox(width: 2.w),
                Text(
                  'Distribution Effectiveness',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 2.h),
            _buildPerformanceBar(
              context,
              'Election Performance',
              distributionEffectiveness['election_performance']?.toDouble() ??
                  0,
              Colors.purple,
            ),
            SizedBox(height: 1.5.h),
            _buildPerformanceBar(
              context,
              'Social Performance',
              distributionEffectiveness['social_performance']?.toDouble() ?? 0,
              Colors.blue,
            ),
            SizedBox(height: 1.5.h),
            _buildPerformanceBar(
              context,
              'Ad Performance',
              distributionEffectiveness['ad_performance']?.toDouble() ?? 0,
              Colors.green,
            ),
            SizedBox(height: 2.h),
            Container(
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.health_and_safety, color: Colors.blue, size: 24),
                  SizedBox(width: 3.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Overall Platform Health',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 0.5.h),
                        Text(
                          '${distributionEffectiveness['overall_health']?.toStringAsFixed(1) ?? '0'}% - Excellent',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlatformHealthSection(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.monitor_heart, color: theme.colorScheme.primary),
                SizedBox(width: 2.w),
                Text(
                  'Platform Health Metrics',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 2.h),
            _buildHealthIndicator(
              context,
              'Content Delivery',
              'Operational',
              Colors.green,
              Icons.check_circle,
            ),
            SizedBox(height: 1.h),
            _buildHealthIndicator(
              context,
              'User Experience',
              'Optimal',
              Colors.green,
              Icons.check_circle,
            ),
            SizedBox(height: 1.h),
            _buildHealthIndicator(
              context,
              'System Load',
              'Normal',
              Colors.blue,
              Icons.info,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          SizedBox(height: 1.h),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 0.5.h),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceBar(
    BuildContext context,
    String label,
    double value,
    Color color,
  ) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '${value.toStringAsFixed(1)}%',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        SizedBox(height: 0.5.h),
        ClipRRect(
          borderRadius: BorderRadius.circular(4.0),
          child: LinearProgressIndicator(
            value: value / 100,
            backgroundColor: color.withValues(alpha: 0.2),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 8,
          ),
        ),
      ],
    );
  }

  Widget _buildHealthIndicator(
    BuildContext context,
    String label,
    String status,
    Color color,
    IconData icon,
  ) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        SizedBox(width: 2.w),
        Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: Text(
            status,
            style: TextStyle(
              color: color,
              fontSize: 11.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
