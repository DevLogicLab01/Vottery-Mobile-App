import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class PerformanceMetricsWidget extends StatelessWidget {
  final Map<String, dynamic> statistics;
  final List<Map<String, dynamic>> alertHistory;

  const PerformanceMetricsWidget({
    super.key,
    required this.statistics,
    required this.alertHistory,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Alert Performance Metrics', style: theme.textTheme.titleLarge),
        SizedBox(height: 2.h),
        _buildMetricCard(
          theme,
          'Total Active Alerts',
          '${statistics['total_active_alerts'] ?? 0}',
          Icons.notifications_active,
          Colors.blue,
        ),
        SizedBox(height: 2.h),
        _buildMetricCard(
          theme,
          'Critical Alerts',
          '${statistics['critical_alerts'] ?? 0}',
          Icons.warning,
          Colors.red,
        ),
        SizedBox(height: 2.h),
        _buildMetricCard(
          theme,
          'High Priority Alerts',
          '${statistics['high_alerts'] ?? 0}',
          Icons.priority_high,
          Colors.orange,
        ),
        SizedBox(height: 2.h),
        _buildMetricCard(
          theme,
          'Medium Priority Alerts',
          '${statistics['medium_alerts'] ?? 0}',
          Icons.info,
          Colors.yellow.shade700,
        ),
        SizedBox(height: 2.h),
        _buildMetricCard(
          theme,
          'Active Rules',
          '${statistics['total_active_rules'] ?? 0}',
          Icons.rule,
          Colors.green,
        ),
        SizedBox(height: 3.h),
        Text('Alert Trends', style: theme.textTheme.titleMedium),
        SizedBox(height: 1.h),
        Card(
          child: Padding(
            padding: EdgeInsets.all(4.w),
            child: Column(
              children: [
                Text(
                  'Last 24 Hours',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  '${alertHistory.length} alerts triggered',
                  style: theme.textTheme.bodyLarge,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard(
    ThemeData theme,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(2.w),
              decoration: BoxDecoration(
                color: color.withAlpha(51),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20.sp),
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    value,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
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
}
