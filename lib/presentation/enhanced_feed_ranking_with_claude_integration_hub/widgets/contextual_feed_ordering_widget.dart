import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

/// Contextual Feed Ordering Widget
/// Real-time content prioritization based on relevance algorithms
class ContextualFeedOrderingWidget extends StatelessWidget {
  final List<Map<String, dynamic>> matches;

  const ContextualFeedOrderingWidget({super.key, required this.matches});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
            'Feed Ordering Algorithm',
            style: GoogleFonts.inter(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            'Content is prioritized using:',
            style: GoogleFonts.inter(
              fontSize: 10.sp,
              color: theme.colorScheme.onSurface.withAlpha(153),
            ),
          ),
          SizedBox(height: 1.h),
          _buildAlgorithmFactor('Semantic Similarity', '30%', theme),
          _buildAlgorithmFactor('Collaborative Filtering', '30%', theme),
          _buildAlgorithmFactor('Recency Score', '20%', theme),
          _buildAlgorithmFactor('Popularity Score', '10%', theme),
          _buildAlgorithmFactor('Diversity Penalty', '10%', theme),
        ],
      ),
    );
  }

  Widget _buildAlgorithmFactor(String label, String weight, ThemeData theme) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 0.5.h),
      child: Row(
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
            weight,
            style: GoogleFonts.inter(
              fontSize: 10.sp,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}
