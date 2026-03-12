import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class AlertGroupingSystemWidget extends StatelessWidget {
  final Map<String, int> alertCounts;
  final int maxAlertsPerHour;

  const AlertGroupingSystemWidget({
    super.key,
    required this.alertCounts,
    required this.maxAlertsPerHour,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
                  Icons.group_work,
                  color: theme.colorScheme.primary,
                  size: 20.sp,
                ),
                SizedBox(width: 2.w),
                Text(
                  'Alert Grouping System',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 2.h),
            Container(
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: Colors.blue.withAlpha(26),
                borderRadius: BorderRadius.circular(12.0),
                border: Border.all(color: Colors.blue.withAlpha(77)),
              ),
              child: Row(
                children: [
                  Icon(Icons.shield, color: Colors.blue, size: 20.sp),
                  SizedBox(width: 3.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Alert Storm Prevention',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 0.5.h),
                        Text(
                          'Maximum $maxAlertsPerHour alerts per error type per hour',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withAlpha(153),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              'Alert Counts (Current Hour)',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 1.h),
            if (alertCounts.isEmpty)
              Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 4.h),
                  child: Column(
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 40.sp,
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        'No alerts sent in the current hour',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...alertCounts.entries.map(
                (entry) => _buildAlertCountCard(
                  theme,
                  entry.key,
                  entry.value,
                  maxAlertsPerHour,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertCountCard(
    ThemeData theme,
    String errorType,
    int count,
    int maxCount,
  ) {
    final isNearLimit = count >= maxCount - 1;
    final color = isNearLimit ? Colors.orange : Colors.blue;

    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: color.withAlpha(13),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: color.withAlpha(51)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  errorType.replaceAll('_', ' ').toUpperCase(),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                '$count / $maxCount',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          LinearProgressIndicator(
            value: count / maxCount,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
          if (isNearLimit) ...[
            SizedBox(height: 1.h),
            Row(
              children: [
                Icon(Icons.warning_amber, color: Colors.orange, size: 14.sp),
                SizedBox(width: 1.w),
                Text(
                  'Approaching alert limit',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
