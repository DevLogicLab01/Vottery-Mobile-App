import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class AlertRuleConfigurationWidget extends StatelessWidget {
  final Map<String, dynamic> alertConfig;
  final VoidCallback onRuleCreated;

  const AlertRuleConfigurationWidget({
    super.key,
    required this.alertConfig,
    required this.onRuleCreated,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: Padding(
            padding: EdgeInsets.all(4.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.rule,
                      color: theme.colorScheme.primary,
                      size: 20.sp,
                    ),
                    SizedBox(width: 2.w),
                    Text(
                      'Alert Rule Configuration',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 2.h),
                Text(
                  'Configure custom alert rules for different error types with admin controls.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withAlpha(179),
                  ),
                ),
                SizedBox(height: 3.h),
                _buildRuleCard(
                  theme,
                  'Critical Error Rate',
                  'Triggers when error rate exceeds ${alertConfig['critical_errors_per_minute'] ?? 10} errors/min',
                  Icons.error,
                  Colors.red,
                  'critical',
                ),
                SizedBox(height: 2.h),
                _buildRuleCard(
                  theme,
                  'AI Service Failures',
                  'Triggers when AI failures exceed ${alertConfig['ai_service_failures_per_hour'] ?? 5} failures/hour',
                  Icons.smart_toy,
                  Colors.orange,
                  'high',
                ),
                SizedBox(height: 2.h),
                _buildRuleCard(
                  theme,
                  'Daily Crashes',
                  'Triggers when crashes exceed ${alertConfig['crashes_per_day'] ?? 100} crashes/day',
                  Icons.bug_report,
                  Colors.red,
                  'critical',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRuleCard(
    ThemeData theme,
    String title,
    String description,
    IconData icon,
    Color color,
    String severity,
  ) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: color.withAlpha(13),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: color.withAlpha(51)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(2.w),
            decoration: BoxDecoration(
              color: color.withAlpha(26),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Icon(icon, color: color, size: 20.sp),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(width: 2.w),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 2.w,
                        vertical: 0.5.h,
                      ),
                      decoration: BoxDecoration(
                        color: color.withAlpha(51),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: Text(
                        severity.toUpperCase(),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: color,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 0.5.h),
                Text(
                  description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withAlpha(153),
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.check_circle, color: Colors.green, size: 18.sp),
        ],
      ),
    );
  }
}
