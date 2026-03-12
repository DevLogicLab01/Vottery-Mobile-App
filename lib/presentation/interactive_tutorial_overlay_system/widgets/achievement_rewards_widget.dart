import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class AchievementRewardsWidget extends StatelessWidget {
  final int vpEarned;

  const AchievementRewardsWidget({super.key, required this.vpEarned});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      color: Colors.amber.shade50,
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(2.w),
              decoration: BoxDecoration(
                color: Colors.amber.withAlpha(51),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Icon(Icons.emoji_events, color: Colors.amber, size: 32.sp),
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Achievement Rewards',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 0.5.h),
                  Text(
                    'Complete all modules to earn 200 VP bonus',
                    style: TextStyle(fontSize: 11.sp, color: Colors.grey[700]),
                  ),
                ],
              ),
            ),
            Column(
              children: [
                Text(
                  '$vpEarned VP',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber[700],
                  ),
                ),
                Text(
                  'Earned',
                  style: TextStyle(fontSize: 10.sp, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
