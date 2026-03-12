// No changes needed - the code is correct. The errors are due to missing Flutter SDK or package dependencies in the analysis environment, not code issues.
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../../theme/app_theme.dart';

/// Widget displaying engagement correlation analysis
class EngagementCorrelationWidget extends StatelessWidget {
  final Map<String, dynamic> correlationData;

  const EngagementCorrelationWidget({super.key, required this.correlationData});

  @override
  Widget build(BuildContext context) {
    final byComplexity =
        correlationData['by_complexity'] as Map<String, dynamic>? ?? {};
    final byDuration =
        correlationData['by_duration'] as Map<String, dynamic>? ?? {};

    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 8.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'By Voting Method Complexity',
            style: GoogleFonts.inter(
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          SizedBox(height: 1.5.h),
          if (byComplexity.isEmpty)
            Text(
              'No data available',
              style: GoogleFonts.inter(fontSize: 12.sp, color: Colors.grey),
            )
          else
            ...byComplexity.entries.map((entry) {
              final rate = (entry.value as num?)?.toDouble() ?? 0.0;
              return _buildCorrelationRow(
                _formatVotingMethod(entry.key),
                rate,
                _getComplexityColor(rate),
              );
            }),
          SizedBox(height: 3.h),
          Text(
            'By Election Duration',
            style: GoogleFonts.inter(
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          SizedBox(height: 1.5.h),
          if (byDuration.isEmpty)
            Text(
              'No data available',
              style: GoogleFonts.inter(fontSize: 12.sp, color: Colors.grey),
            )
          else
            ...byDuration.entries.map((entry) {
              final rate = (entry.value as num?)?.toDouble() ?? 0.0;
              return _buildCorrelationRow(
                _formatDuration(entry.key),
                rate,
                _getComplexityColor(rate),
              );
            }),
          SizedBox(height: 2.h),
          Container(
            padding: EdgeInsets.all(2.w),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Row(
              children: [
                Icon(Icons.lightbulb_outline, color: Colors.blue.shade700),
                SizedBox(width: 2.w),
                Expanded(
                  child: Text(
                    'Complex voting methods and longer durations correlate with higher abstention rates',
                    style: GoogleFonts.inter(
                      fontSize: 11.sp,
                      color: Colors.blue.shade900,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCorrelationRow(String label, double rate, Color color) {
    return Container(
      margin: EdgeInsets.only(bottom: 1.5.h),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12.sp,
                color: AppTheme.textPrimaryLight,
              ),
            ),
          ),
          Container(
            width: 30.w,
            height: 8,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(4.0),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: (rate / 30).clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4.0),
                ),
              ),
            ),
          ),
          SizedBox(width: 2.w),
          SizedBox(
            width: 12.w,
            child: Text(
              '${rate.toStringAsFixed(1)}%',
              style: GoogleFonts.inter(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: color,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Color _getComplexityColor(double rate) {
    if (rate > 20) return Colors.red;
    if (rate > 15) return Colors.orange;
    return Colors.green;
  }

  String _formatVotingMethod(String method) {
    switch (method) {
      case 'plurality':
        return 'Plurality (Simple)';
      case 'ranked_choice':
        return 'Ranked Choice (Complex)';
      case 'approval':
        return 'Approval (Medium)';
      case 'plus_minus':
        return 'Plus-Minus (Medium)';
      default:
        return method;
    }
  }

  String _formatDuration(String duration) {
    switch (duration) {
      case 'short':
        return 'Short (≤1 day)';
      case 'medium':
        return 'Medium (2-7 days)';
      case 'long':
        return 'Long (>7 days)';
      default:
        return duration;
    }
  }
}
