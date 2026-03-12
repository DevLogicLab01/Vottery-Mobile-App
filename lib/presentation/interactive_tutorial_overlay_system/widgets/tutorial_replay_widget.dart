import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class TutorialReplayWidget extends StatelessWidget {
  final VoidCallback onReplay;

  const TutorialReplayWidget({super.key, required this.onReplay});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Row(
          children: [
            Icon(Icons.replay, size: 24.sp, color: Colors.blue),
            SizedBox(width: 3.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Replay Tutorial',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 0.5.h),
                  Text(
                    'Review any module anytime from settings',
                    style: TextStyle(fontSize: 11.sp, color: Colors.grey),
                  ),
                ],
              ),
            ),
            OutlinedButton(
              onPressed: onReplay,
              child: Text('Replay', style: TextStyle(fontSize: 11.sp)),
            ),
          ],
        ),
      ),
    );
  }
}
