import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class TutorialProgressTrackerWidget extends StatelessWidget {
  final int completionPercentage;
  final Map<String, bool> moduleCompletion;

  const TutorialProgressTrackerWidget({
    super.key,
    required this.completionPercentage,
    required this.moduleCompletion,
  });

  @override
  Widget build(BuildContext context) {
    final completedModules = moduleCompletion.values.where((v) => v).length;
    final totalModules = moduleCompletion.length;

    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Tutorial Progress',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '$completionPercentage%',
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    color: completionPercentage == 100
                        ? Colors.green
                        : Colors.blue,
                  ),
                ),
              ],
            ),
            SizedBox(height: 2.h),
            LinearProgressIndicator(
              value: completionPercentage / 100,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(
                completionPercentage == 100 ? Colors.green : Colors.blue,
              ),
              minHeight: 1.h,
            ),
            SizedBox(height: 1.h),
            Text(
              '$completedModules of $totalModules modules completed',
              style: TextStyle(fontSize: 11.sp, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
