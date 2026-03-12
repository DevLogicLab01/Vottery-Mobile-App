import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../../widgets/custom_icon_widget.dart';

/// Gamification Score Widget
/// Displays overall gamification score (0-100) based on engagement level
class GamificationScoreWidget extends StatelessWidget {
  final int score;

  const GamificationScoreWidget({super.key, required this.score});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scoreColor = _getScoreColor(score);
    final scoreLabel = _getScoreLabel(score);

    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [scoreColor.withAlpha(51), scoreColor.withAlpha(13)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: scoreColor.withAlpha(77)),
      ),
      child: Row(
        children: [
          Container(
            width: 15.w,
            height: 15.w,
            decoration: BoxDecoration(
              color: scoreColor.withAlpha(51),
              shape: BoxShape.circle,
              border: Border.all(color: scoreColor, width: 3),
            ),
            child: Center(
              child: Text(
                '$score',
                style: GoogleFonts.inter(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: scoreColor,
                ),
              ),
            ),
          ),
          SizedBox(width: 4.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Gamification Score',
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                SizedBox(height: 0.5.h),
                Text(
                  scoreLabel,
                  style: GoogleFonts.inter(
                    fontSize: 10.sp,
                    color: theme.colorScheme.onSurface.withAlpha(153),
                  ),
                ),
                SizedBox(height: 1.h),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: LinearProgressIndicator(
                    value: score / 100,
                    minHeight: 1.h,
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                    valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 3.w),
          CustomIconWidget(
            iconName: _getScoreIcon(score),
            color: scoreColor,
            size: 32,
          ),
        ],
      ),
    );
  }

  Color _getScoreColor(int score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.blue;
    if (score >= 40) return Colors.orange;
    return Colors.red;
  }

  String _getScoreLabel(int score) {
    if (score >= 80) return 'Excellent Engagement! Keep it up!';
    if (score >= 60) return 'Good Progress! Almost there!';
    if (score >= 40) return 'Moderate Activity. Try more challenges!';
    return 'Low Engagement. Start earning VP today!';
  }

  String _getScoreIcon(int score) {
    if (score >= 80) return 'emoji_events';
    if (score >= 60) return 'trending_up';
    if (score >= 40) return 'show_chart';
    return 'trending_down';
  }
}
