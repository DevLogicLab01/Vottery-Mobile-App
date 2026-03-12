import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../../widgets/custom_icon_widget.dart';

/// A/B Testing Framework Widget
/// Compares Claude vs semantic similarity rankings with performance metrics
class ABTestingFrameworkWidget extends StatelessWidget {
  final Map<String, dynamic>? results;

  const ABTestingFrameworkWidget({super.key, required this.results});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (results == null || results!.isEmpty) {
      return _buildEmptyState(theme);
    }

    final claudeConversionRate =
        results!['claude_conversion_rate'] as double? ?? 0.0;
    final semanticConversionRate =
        results!['semantic_conversion_rate'] as double? ?? 0.0;
    final claudeSatisfaction =
        results!['claude_satisfaction'] as double? ?? 0.0;
    final semanticSatisfaction =
        results!['semantic_satisfaction'] as double? ?? 0.0;

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
          Text(
            'Claude vs Semantic Similarity',
            style: GoogleFonts.inter(
              fontSize: 13.sp,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 2.h),
          _buildComparisonRow(
            theme,
            'Conversion Rate',
            claudeConversionRate,
            semanticConversionRate,
          ),
          SizedBox(height: 2.h),
          _buildComparisonRow(
            theme,
            'User Satisfaction',
            claudeSatisfaction,
            semanticSatisfaction,
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonRow(
    ThemeData theme,
    String metric,
    double claudeValue,
    double semanticValue,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          metric,
          style: GoogleFonts.inter(
            fontSize: 11.sp,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        SizedBox(height: 1.h),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                theme,
                'Claude',
                claudeValue,
                Colors.purple,
              ),
            ),
            SizedBox(width: 2.w),
            Expanded(
              child: _buildMetricCard(
                theme,
                'Semantic',
                semanticValue,
                Colors.blue,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard(
    ThemeData theme,
    String label,
    double value,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(2.w),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: color.withAlpha(77)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10.sp,
              color: theme.colorScheme.onSurface.withAlpha(153),
            ),
          ),
          SizedBox(height: 0.5.h),
          Text(
            '${(value * 100).toStringAsFixed(1)}%',
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
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
        child: Column(
          children: [
            CustomIconWidget(
              iconName: 'science',
              color: theme.colorScheme.onSurface.withAlpha(77),
              size: 40,
            ),
            SizedBox(height: 1.h),
            Text(
              'No A/B testing data available',
              style: GoogleFonts.inter(
                fontSize: 12.sp,
                color: theme.colorScheme.onSurface.withAlpha(153),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
