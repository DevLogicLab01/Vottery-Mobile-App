import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

class ModerationStatsOverviewWidget extends StatelessWidget {
  final Map<String, int> stats;

  const ModerationStatsOverviewWidget({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(bottom: BorderSide(color: theme.dividerColor)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              context,
              'Flagged',
              stats['flagged'] ?? 0,
              'flag',
              const Color(0xFFF59E0B),
            ),
          ),
          SizedBox(width: 2.w),
          Expanded(
            child: _buildStatCard(
              context,
              'Pending',
              stats['pending'] ?? 0,
              'pending',
              const Color(0xFF3B82F6),
            ),
          ),
          SizedBox(width: 2.w),
          Expanded(
            child: _buildStatCard(
              context,
              'Appeals',
              stats['appeals'] ?? 0,
              'gavel',
              const Color(0xFF8B5CF6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    int count,
    String iconName,
    Color color,
  ) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          CustomIconWidget(iconName: iconName, color: color, size: 24),
          SizedBox(height: 1.h),
          Text(
            count.toString(),
            style: theme.textTheme.headlineSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.disabledColor,
            ),
          ),
        ],
      ),
    );
  }
}
