import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class ViewerCountWidget extends StatelessWidget {
  final int count;

  const ViewerCountWidget({super.key, required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
      decoration: BoxDecoration(
        color: AppTheme.errorLight.withAlpha(26),
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(color: AppTheme.errorLight),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.remove_red_eye, size: 4.w, color: AppTheme.errorLight),
          SizedBox(width: 2.w),
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w700,
              color: AppTheme.errorLight,
            ),
          ),
        ],
      ),
    );
  }
}
