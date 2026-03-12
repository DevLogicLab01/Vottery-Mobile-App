import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class DailyQuestCardWidget extends StatelessWidget {
  final String questTitle;
  final String questDescription;
  final int currentProgress;
  final int targetCount;
  final int vpReward;
  final bool isCompleted;
  final Function(int)? onQuestCompleted;

  const DailyQuestCardWidget({
    super.key,
    required this.questTitle,
    required this.questDescription,
    required this.currentProgress,
    required this.targetCount,
    required this.vpReward,
    required this.isCompleted,
    this.onQuestCompleted,
  });

  @override
  Widget build(BuildContext context) {
    final progressPercentage = targetCount > 0
        ? (currentProgress / targetCount).clamp(0.0, 1.0)
        : 0.0;

    return Card(
      margin: EdgeInsets.only(bottom: 2.h),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Container(
        padding: EdgeInsets.all(3.w),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12.0),
          gradient: isCompleted
              ? LinearGradient(
                  colors: [Colors.green.shade50, Colors.green.shade100],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        questTitle,
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                          color: isCompleted
                              ? Colors.green.shade800
                              : Colors.black87,
                        ),
                      ),
                      SizedBox(height: 0.5.h),
                      Text(
                        questDescription,
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade100,
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.stars,
                        color: Colors.amber.shade700,
                        size: 16.sp,
                      ),
                      SizedBox(width: 1.w),
                      Text(
                        '$vpReward VP',
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.amber.shade900,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 2.h),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Progress',
                            style: TextStyle(
                              fontSize: 11.sp,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          Text(
                            '$currentProgress / $targetCount',
                            style: TextStyle(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.bold,
                              color: isCompleted
                                  ? Colors.green.shade700
                                  : Colors.blue.shade700,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 0.5.h),
                      LinearProgressIndicator(
                        value: progressPercentage,
                        backgroundColor: Colors.grey.shade300,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isCompleted ? Colors.green : Colors.blue,
                        ),
                        minHeight: 1.h,
                      ),
                    ],
                  ),
                ),
                if (isCompleted)
                  Padding(
                    padding: EdgeInsets.only(left: 3.w),
                    child: Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 24.sp,
                    ),
                  ),
              ],
            ),
            if (isCompleted)
              Padding(
                padding: EdgeInsets.only(top: 1.h),
                child: Text(
                  '✓ Quest Completed!',
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: Colors.green.shade700,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
