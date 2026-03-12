import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../../widgets/custom_icon_widget.dart';

/// Behavioral Pattern Analysis Widget
/// Claude-powered analysis of user voting history, interaction frequency, time spent
class BehavioralPatternAnalysisWidget extends StatelessWidget {
  final Map<String, dynamic>? patterns;

  const BehavioralPatternAnalysisWidget({super.key, required this.patterns});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (patterns == null || patterns!.isEmpty) {
      return _buildEmptyState(theme);
    }

    final votingFrequency = patterns!['voting_frequency'] as int? ?? 0;
    final interactionCount = patterns!['interaction_count'] as int? ?? 0;
    final socialConnections = patterns!['social_connections'] as int? ?? 0;
    final avgTimeSpent = patterns!['avg_time_spent'] as double? ?? 0.0;

    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        children: [
          _buildPatternRow(
            theme,
            'Voting History',
            '$votingFrequency votes',
            'how_to_vote',
            Colors.blue,
          ),
          SizedBox(height: 2.h),
          _buildPatternRow(
            theme,
            'Interaction Frequency',
            '$interactionCount interactions',
            'touch_app',
            Colors.green,
          ),
          SizedBox(height: 2.h),
          _buildPatternRow(
            theme,
            'Social Connections',
            '$socialConnections connections',
            'groups',
            Colors.purple,
          ),
          SizedBox(height: 2.h),
          _buildPatternRow(
            theme,
            'Avg Time Spent',
            '${avgTimeSpent.toStringAsFixed(1)}s per item',
            'schedule',
            Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _buildPatternRow(
    ThemeData theme,
    String label,
    String value,
    String iconName,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(2.w),
          decoration: BoxDecoration(
            color: color.withAlpha(26),
            shape: BoxShape.circle,
          ),
          child: CustomIconWidget(iconName: iconName, color: color, size: 24),
        ),
        SizedBox(width: 3.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 11.sp,
                  color: theme.colorScheme.onSurface.withAlpha(153),
                ),
              ),
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
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
          'No behavioral data available',
          style: GoogleFonts.inter(
            fontSize: 12.sp,
            color: theme.colorScheme.onSurface.withAlpha(153),
          ),
        ),
      ),
    );
  }
}
