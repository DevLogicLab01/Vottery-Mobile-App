import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

class StatisticsCardWidget extends StatelessWidget {
  final int totalVotes;
  final double successRate;
  final int currentStreak;

  const StatisticsCardWidget({
    super.key,
    required this.totalVotes,
    required this.successRate,
    required this.currentStreak,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primaryContainer,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              CustomIconWidget(
                iconName: 'analytics',
                color: theme.colorScheme.onPrimary,
                size: 24,
              ),
              SizedBox(width: 2.w),
              Text(
                'Your Voting Statistics',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 3.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                context: context,
                icon: 'how_to_vote',
                value: totalVotes.toString(),
                label: 'Total Votes',
                theme: theme,
              ),
              Container(
                width: 1,
                height: 6.h,
                color: theme.colorScheme.onPrimary.withValues(alpha: 0.3),
              ),
              _buildStatItem(
                context: context,
                icon: 'emoji_events',
                value: '${successRate.toStringAsFixed(1)}%',
                label: 'Success Rate',
                theme: theme,
              ),
              Container(
                width: 1,
                height: 6.h,
                color: theme.colorScheme.onPrimary.withValues(alpha: 0.3),
              ),
              _buildStatItem(
                context: context,
                icon: 'local_fire_department',
                value: currentStreak.toString(),
                label: 'Win Streak',
                theme: theme,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required BuildContext context,
    required String icon,
    required String value,
    required String label,
    required ThemeData theme,
  }) {
    return Column(
      children: [
        CustomIconWidget(
          iconName: icon,
          color: theme.colorScheme.onPrimary,
          size: 28,
        ),
        SizedBox(height: 1.h),
        Text(
          value,
          style: theme.textTheme.headlineSmall?.copyWith(
            color: theme.colorScheme.onPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: 0.5.h),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onPrimary.withValues(alpha: 0.9),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
