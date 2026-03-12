import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class QuestsCompletedCardWidget extends StatelessWidget {
  final int count;
  final double completionRate;

  const QuestsCompletedCardWidget({
    super.key,
    required this.count,
    required this.completionRate,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(Icons.task_alt, color: Colors.green, size: 16.sp),
            Text(
              count.toString(),
              style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quests Completed (1h)',
                  style: TextStyle(fontSize: 11.sp, color: Colors.grey),
                ),
                Text(
                  '${completionRate.toStringAsFixed(1)}% rate',
                  style: TextStyle(
                    fontSize: 9.sp,
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
