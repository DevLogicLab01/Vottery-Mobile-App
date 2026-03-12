import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../../widgets/custom_icon_widget.dart';

/// Claude Reasoning Dashboard Widget
/// User behavior insights, preference evolution tracking, engagement prediction models
class ClaudeReasoningDashboardWidget extends StatelessWidget {
  final Map<String, dynamic>? insights;

  const ClaudeReasoningDashboardWidget({super.key, required this.insights});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (insights == null || insights!.isEmpty) {
      return _buildEmptyState(theme);
    }

    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple.withAlpha(26), Colors.blue.withAlpha(13)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.purple.withAlpha(77)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CustomIconWidget(
                iconName: 'psychology',
                color: Colors.purple,
                size: 28,
              ),
              SizedBox(width: 2.w),
              Text(
                'Claude AI Insights',
                style: GoogleFonts.inter(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Text(
            'Claude analyzes user behavior patterns to provide contextual reasoning for personalized content recommendations.',
            style: GoogleFonts.inter(
              fontSize: 10.sp,
              color: theme.colorScheme.onSurface.withAlpha(179),
            ),
          ),
          SizedBox(height: 2.h),
          _buildInsightMetric('Behavior Patterns Analyzed', '100+', theme),
          SizedBox(height: 1.h),
          _buildInsightMetric(
            'Preference Evolution Tracked',
            'Real-time',
            theme,
          ),
          SizedBox(height: 1.h),
          _buildInsightMetric('Engagement Predictions', 'Active', theme),
        ],
      ),
    );
  }

  Widget _buildInsightMetric(String label, String value, ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10.sp,
            color: theme.colorScheme.onSurface,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 10.sp,
            fontWeight: FontWeight.w600,
            color: Colors.purple,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Center(
        child: Text(
          'No Claude insights available',
          style: GoogleFonts.inter(
            fontSize: 12.sp,
            color: theme.colorScheme.onSurface.withAlpha(153),
          ),
        ),
      ),
    );
  }
}
