import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class PerformanceTimelineWidget extends StatelessWidget {
  const PerformanceTimelineWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Card(
        elevation: 2,
        child: Padding(
          padding: EdgeInsets.all(8.w),
          child: Column(
            children: [
              Icon(Icons.timeline, size: 20.w, color: Colors.grey),
              SizedBox(height: 2.h),
              Text(
                'Performance Timeline',
                style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 1.h),
              Text(
                'Annotated timeline with screen loads, API calls, and user interactions',
                style: TextStyle(fontSize: 10.sp, color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 2.h),
              Text(
                'Coming soon',
                style: TextStyle(fontSize: 11.sp, color: AppTheme.accentLight),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
