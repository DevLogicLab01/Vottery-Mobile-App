import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class UserPreferencesWidget extends StatelessWidget {
  final VoidCallback onPreferencesUpdated;

  const UserPreferencesWidget({super.key, required this.onPreferencesUpdated});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'User Preferences',
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 2.h),
            Text(
              'Granular per-category controls with quiet hours and priority settings',
              style: TextStyle(fontSize: 12.sp, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
