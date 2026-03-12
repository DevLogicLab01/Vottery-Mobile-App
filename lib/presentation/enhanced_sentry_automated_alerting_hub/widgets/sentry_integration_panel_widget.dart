import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class SentryIntegrationPanelWidget extends StatelessWidget {
  final Map<String, dynamic> errorRateStats;
  final Map<String, dynamic> alertConfig;
  final VoidCallback onRefresh;

  const SentryIntegrationPanelWidget({
    super.key,
    required this.errorRateStats,
    required this.alertConfig,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final errorRate = errorRateStats['error_rate'] as double? ?? 0.0;
    final criticalThreshold =
        alertConfig['critical_errors_per_minute'] as int? ?? 10;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.integration_instructions,
                  color: theme.colorScheme.primary,
                  size: 20.sp,
                ),
                SizedBox(width: 2.w),
                Text(
                  'Sentry Integration Panel',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: onRefresh,
                ),
              ],
            ),
            SizedBox(height: 2.h),
            _buildErrorRateChart(
              theme,
              errorRate,
              criticalThreshold.toDouble(),
            ),
            SizedBox(height: 2.h),
            _buildStatisticsGrid(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorRateChart(
    ThemeData theme,
    double errorRate,
    double threshold,
  ) {
    final isAboveThreshold = errorRate > threshold;

    return Container(
      height: 20.h,
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: isAboveThreshold
            ? Colors.red.withAlpha(26)
            : Colors.green.withAlpha(26),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: isAboveThreshold
              ? Colors.red.withAlpha(77)
              : Colors.green.withAlpha(77),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Error Rate Monitoring',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 1.h),
          Row(
            children: [
              Text(
                '${errorRate.toStringAsFixed(2)} errors/min',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: isAboveThreshold ? Colors.red : Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                decoration: BoxDecoration(
                  color: isAboveThreshold
                      ? Colors.red.withAlpha(51)
                      : Colors.green.withAlpha(51),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Text(
                  isAboveThreshold ? 'CRITICAL' : 'NORMAL',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: isAboveThreshold ? Colors.red : Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          LinearProgressIndicator(
            value: (errorRate / threshold).clamp(0.0, 1.0),
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation<Color>(
              isAboveThreshold ? Colors.red : Colors.green,
            ),
          ),
          SizedBox(height: 0.5.h),
          Text(
            'Threshold: $threshold errors/min',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withAlpha(153),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsGrid(ThemeData theme) {
    final stats = [
      {
        'label': 'Critical',
        'value': '${errorRateStats['critical_count'] ?? 0}',
        'icon': Icons.priority_high,
        'color': Colors.red,
      },
      {
        'label': 'High',
        'value': '${errorRateStats['high_count'] ?? 0}',
        'icon': Icons.warning,
        'color': Colors.orange,
      },
      {
        'label': 'Medium',
        'value': '${errorRateStats['medium_count'] ?? 0}',
        'icon': Icons.info,
        'color': Colors.blue,
      },
      {
        'label': 'Open',
        'value': '${errorRateStats['open_count'] ?? 0}',
        'icon': Icons.pending,
        'color': Colors.purple,
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 3.w,
        mainAxisSpacing: 2.h,
        childAspectRatio: 2.5,
      ),
      itemCount: stats.length,
      itemBuilder: (context, index) {
        final stat = stats[index];
        return Container(
          padding: EdgeInsets.all(3.w),
          decoration: BoxDecoration(
            color: (stat['color'] as Color).withAlpha(26),
            borderRadius: BorderRadius.circular(12.0),
            border: Border.all(color: (stat['color'] as Color).withAlpha(77)),
          ),
          child: Row(
            children: [
              Icon(
                stat['icon'] as IconData,
                color: stat['color'] as Color,
                size: 18.sp,
              ),
              SizedBox(width: 2.w),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    stat['value'] as String,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: stat['color'] as Color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    stat['label'] as String,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withAlpha(153),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
