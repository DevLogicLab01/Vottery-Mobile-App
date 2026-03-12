import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class ActiveUsersCardWidget extends StatelessWidget {
  final int count;
  final double trend;

  const ActiveUsersCardWidget({
    super.key,
    required this.count,
    required this.trend,
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
            Row(
              children: [
                Icon(Icons.people, color: Colors.blue, size: 16.sp),
                const Spacer(),
                _buildTrendIndicator(),
              ],
            ),
            Text(
              count.toString(),
              style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold),
            ),
            Text(
              'Active Users (5 min)',
              style: TextStyle(fontSize: 11.sp, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendIndicator() {
    final isPositive = trend >= 0;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 1.5.w, vertical: 0.3.h),
      decoration: BoxDecoration(
        color: (isPositive ? Colors.green : Colors.red).withAlpha(51),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPositive ? Icons.arrow_upward : Icons.arrow_downward,
            size: 10.sp,
            color: isPositive ? Colors.green : Colors.red,
          ),
          Text(
            '${trend.abs().toStringAsFixed(1)}%',
            style: TextStyle(
              fontSize: 9.sp,
              fontWeight: FontWeight.bold,
              color: isPositive ? Colors.green : Colors.red,
            ),
          ),
        ],
      ),
    );
  }
}
