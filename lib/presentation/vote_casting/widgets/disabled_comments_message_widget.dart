import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class DisabledCommentsMessageWidget extends StatelessWidget {
  const DisabledCommentsMessageWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(4.w),
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.comments_disabled,
              color: Colors.grey.shade400,
              size: 32,
            ),
            SizedBox(height: 1.h),
            Text(
              'Comments disabled by creator',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 13.sp,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
