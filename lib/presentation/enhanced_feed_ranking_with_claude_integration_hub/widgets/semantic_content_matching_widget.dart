import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../../widgets/custom_icon_widget.dart';

/// Semantic Content Matching Widget
/// Elections matched to user interests with confidence scoring 0-100%
class SemanticContentMatchingWidget extends StatelessWidget {
  final List<Map<String, dynamic>> matches;

  const SemanticContentMatchingWidget({super.key, required this.matches});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (matches.isEmpty) {
      return _buildEmptyState(theme);
    }

    return Column(
      children: matches.map((match) {
        return _buildMatchCard(match, theme);
      }).toList(),
    );
  }

  Widget _buildMatchCard(Map<String, dynamic> match, ThemeData theme) {
    final election = match['election'] as Map<String, dynamic>?;
    final title = election?['title'] as String? ?? 'Election';
    final confidenceScore = match['confidence_score'] as double? ?? 0.0;
    final semanticScore = match['semantic_similarity_score'] as double? ?? 0.0;

    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
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
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                decoration: BoxDecoration(
                  color: _getConfidenceColor(confidenceScore).withAlpha(26),
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(
                    color: _getConfidenceColor(confidenceScore),
                  ),
                ),
                child: Text(
                  '${(confidenceScore * 100).toStringAsFixed(0)}%',
                  style: GoogleFonts.inter(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w600,
                    color: _getConfidenceColor(confidenceScore),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Row(
            children: [
              CustomIconWidget(
                iconName: 'psychology',
                color: theme.colorScheme.primary,
                size: 16,
              ),
              SizedBox(width: 1.w),
              Text(
                'Semantic Match: ${(semanticScore * 100).toStringAsFixed(1)}%',
                style: GoogleFonts.inter(
                  fontSize: 10.sp,
                  color: theme.colorScheme.onSurface.withAlpha(153),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getConfidenceColor(double score) {
    if (score >= 0.8) return Colors.green;
    if (score >= 0.6) return Colors.blue;
    if (score >= 0.4) return Colors.orange;
    return Colors.red;
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
          'No semantic matches available',
          style: GoogleFonts.inter(
            fontSize: 12.sp,
            color: theme.colorScheme.onSurface.withAlpha(153),
          ),
        ),
      ),
    );
  }
}
