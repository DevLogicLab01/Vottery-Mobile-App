import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../../widgets/custom_icon_widget.dart';

/// Real-time Adaptation Widget
/// Monitors user behavior changes with immediate feed adjustment capabilities
class RealTimeAdaptationWidget extends StatelessWidget {
  final Map<String, dynamic>? metrics;

  const RealTimeAdaptationWidget({super.key, required this.metrics});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (metrics == null || metrics!.isEmpty) {
      return _buildEmptyState(theme);
    }

    final adaptationRate = metrics!['adaptation_rate'] as double? ?? 0.0;
    final behaviorChanges = metrics!['behavior_changes_detected'] as int? ?? 0;
    final feedAdjustments = metrics!['feed_adjustments_made'] as int? ?? 0;

    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CustomIconWidget(
                iconName: 'autorenew',
                color: Colors.green,
                size: 24,
              ),
              SizedBox(width: 2.w),
              Text(
                'Real-time Adaptation',
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          _buildMetricRow(
            theme,
            'Adaptation Rate',
            '${(adaptationRate * 100).toStringAsFixed(1)}%',
          ),
          SizedBox(height: 1.h),
          _buildMetricRow(
            theme,
            'Behavior Changes Detected',
            '$behaviorChanges',
          ),
          SizedBox(height: 1.h),
          _buildMetricRow(theme, 'Feed Adjustments Made', '$feedAdjustments'),
        ],
      ),
    );
  }

  Widget _buildMetricRow(ThemeData theme, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10.sp,
            color: theme.colorScheme.onSurface.withAlpha(153),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 11.sp,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
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
          'No adaptation metrics available',
          style: GoogleFonts.inter(
            fontSize: 12.sp,
            color: theme.colorScheme.onSurface.withAlpha(153),
          ),
        ),
      ),
    );
  }
}
