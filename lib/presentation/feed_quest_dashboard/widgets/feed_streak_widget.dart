import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class FeedStreakWidget extends StatelessWidget {
  final int streakDays;
  final String? lastActivityDate;

  const FeedStreakWidget({
    super.key,
    required this.streakDays,
    this.lastActivityDate,
  });

  @override
  Widget build(BuildContext context) {
    final has7DayStreak = streakDays >= 7;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Container(
        padding: EdgeInsets.all(3.w),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: has7DayStreak
                ? [Colors.orange.shade100, Colors.red.shade100]
                : [Colors.blue.shade50, Colors.purple.shade50],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: has7DayStreak
                    ? Colors.orange.shade200
                    : Colors.blue.shade200,
                shape: BoxShape.circle,
              ),
              child: Icon(
                has7DayStreak ? Icons.local_fire_department : Icons.whatshot,
                color: has7DayStreak
                    ? Colors.orange.shade900
                    : Colors.blue.shade900,
                size: 24.sp,
              ),
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Feed Streak',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        '$streakDays Days',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: has7DayStreak
                              ? Colors.orange.shade900
                              : Colors.blue.shade900,
                        ),
                      ),
                      if (has7DayStreak) ...[
                        SizedBox(width: 2.w),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 2.w,
                            vertical: 0.5.h,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.amber,
                            borderRadius: BorderRadius.circular(6.0),
                          ),
                          child: Text(
                            '2x VP',
                            style: TextStyle(
                              fontSize: 10.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            if (has7DayStreak)
              Icon(
                Icons.emoji_events,
                color: Colors.amber.shade700,
                size: 32.sp,
              ),
          ],
        ),
      ),
    );
  }
}
