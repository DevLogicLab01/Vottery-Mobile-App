import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class VoteCountBadgeWidget extends StatelessWidget {
  final int count;

  const VoteCountBadgeWidget({super.key, required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
      decoration: BoxDecoration(
        color: AppTheme.accentLight.withAlpha(26),
        borderRadius: BorderRadius.circular(6.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.how_to_vote, size: 3.w, color: AppTheme.accentLight),
          SizedBox(width: 1.w),
          Text(
            '$count ${count == 1 ? 'friend' : 'friends'} voted',
            style: TextStyle(
              fontSize: 10.sp,
              fontWeight: FontWeight.w600,
              color: AppTheme.accentLight,
            ),
          ),
        ],
      ),
    );
  }
}
