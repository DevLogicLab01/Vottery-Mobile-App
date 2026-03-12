import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

class FraudDetectionPanelWidget extends StatelessWidget {
  const FraudDetectionPanelWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.0.w),
      child: Container(
        padding: EdgeInsets.all(4.0.w),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CustomIconWidget(
                  iconName: 'shield',
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
                SizedBox(width: 2.0.w),
                Text(
                  'Fraud Detection',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 2.0.w,
                    vertical: 0.5.h,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'OpenAI GPT-5',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF10B981),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 2.0.h),
            _buildFraudItem(
              context,
              'Vote #12345',
              'Fraud Score: 78',
              78,
              'high',
            ),
            SizedBox(height: 1.0.h),
            _buildFraudItem(
              context,
              'Vote #12346',
              'Fraud Score: 45',
              45,
              'medium',
            ),
            SizedBox(height: 1.0.h),
            _buildFraudItem(
              context,
              'Vote #12347',
              'Fraud Score: 15',
              15,
              'low',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFraudItem(
    BuildContext context,
    String title,
    String subtitle,
    int score,
    String riskLevel,
  ) {
    final theme = Theme.of(context);
    Color riskColor;

    switch (riskLevel) {
      case 'critical':
      case 'high':
        riskColor = const Color(0xFFEF4444);
        break;
      case 'medium':
        riskColor = const Color(0xFFF59E0B);
        break;
      default:
        riskColor = const Color(0xFF10B981);
    }

    return Container(
      padding: EdgeInsets.all(3.0.w),
      decoration: BoxDecoration(
        color: riskColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: riskColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 0.5.h),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 2.0.w, vertical: 0.5.h),
            decoration: BoxDecoration(
              color: riskColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              riskLevel.toUpperCase(),
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
