import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../../widgets/custom_icon_widget.dart';

/// Recommendation Explanation Widget
/// Natural language explanations for why content was recommended
class RecommendationExplanationWidget extends StatelessWidget {
  final Map<String, dynamic>? insights;

  const RecommendationExplanationWidget({super.key, required this.insights});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (insights == null || insights!.isEmpty) {
      return _buildEmptyState(theme);
    }

    final recommendations = insights!['insights'] as List<dynamic>? ?? [];

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
                iconName: 'lightbulb',
                color: Colors.amber,
                size: 24,
              ),
              SizedBox(width: 2.w),
              Text(
                'Why This Content?',
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          ...recommendations.take(3).map((rec) {
            final recMap = rec as Map<String, dynamic>;
            return _buildExplanationItem(
              recMap['explanation'] as String? ?? 'No explanation',
              theme,
            );
          }),
        ],
      ),
    );
  }

  Widget _buildExplanationItem(String explanation, ThemeData theme) {
    return Container(
      margin: EdgeInsets.only(bottom: 1.h),
      padding: EdgeInsets.all(2.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle, color: Colors.green, size: 16),
          SizedBox(width: 2.w),
          Expanded(
            child: Text(
              explanation,
              style: GoogleFonts.inter(
                fontSize: 10.sp,
                color: theme.colorScheme.onSurface,
              ),
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
        child: Text(
          'No explanations available',
          style: GoogleFonts.inter(
            fontSize: 12.sp,
            color: theme.colorScheme.onSurface.withAlpha(153),
          ),
        ),
      ),
    );
  }
}
