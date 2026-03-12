import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../../widgets/custom_icon_widget.dart';

/// Feed Performance Overview Widget
/// Displays ranking effectiveness metrics, user engagement improvements, Claude API status
class FeedPerformanceOverviewWidget extends StatelessWidget {
  final Map<String, dynamic>? metrics;
  final String claudeApiStatus;

  const FeedPerformanceOverviewWidget({
    super.key,
    required this.metrics,
    required this.claudeApiStatus,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rankingEffectiveness =
        metrics?['ranking_effectiveness'] as double? ?? 0.0;
    final engagementImprovement =
        metrics?['engagement_improvement'] as double? ?? 0.0;
    final avgConfidenceScore =
        metrics?['avg_confidence_score'] as double? ?? 0.0;

    return Container(
      margin: EdgeInsets.all(3.w),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMetricItem(
                'Ranking Effectiveness',
                '${(rankingEffectiveness * 100).toStringAsFixed(1)}%',
                'trending_up',
              ),
              _buildMetricItem(
                'Engagement',
                '+${(engagementImprovement * 100).toStringAsFixed(1)}%',
                'show_chart',
              ),
              _buildMetricItem(
                'Confidence',
                (avgConfidenceScore * 100).toStringAsFixed(0),
                'psychology',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem(String label, String value, String iconName) {
    return Column(
      children: [
        CustomIconWidget(iconName: iconName, color: Colors.white, size: 28),
        SizedBox(height: 0.5.h),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 14.sp,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 9.sp,
            color: Colors.white.withAlpha(230),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
