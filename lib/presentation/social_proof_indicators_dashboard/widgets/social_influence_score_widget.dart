import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class SocialInfluenceScoreWidget extends StatelessWidget {
  final double score;

  const SocialInfluenceScoreWidget({super.key, required this.score});

  @override
  Widget build(BuildContext context) {
    final color = score >= 7
        ? AppTheme.accentLight
        : score >= 4
        ? AppTheme.secondaryLight
        : AppTheme.textSecondaryLight;

    return Container(
      padding: EdgeInsets.all(2.w),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        shape: BoxShape.circle,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            score.toStringAsFixed(1),
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          Text(
            'Score',
            style: TextStyle(fontSize: 8.sp, color: color),
          ),
        ],
      ),
    );
  }
}
