import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class ExponentialBackoffMonitorWidget extends StatelessWidget {
  final List<dynamic> failoverHistory;

  const ExponentialBackoffMonitorWidget({
    super.key,
    required this.failoverHistory,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Exponential Backoff Monitor',
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 1.h),
            Text(
              'Retry intervals: 1s, 2s, 4s, 8s, 16s (max 5 attempts)',
              style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
            ),
            SizedBox(height: 2.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildRetryMetric('Attempt 1', '1s', Colors.green),
                _buildRetryMetric('Attempt 2', '2s', Colors.lightGreen),
                _buildRetryMetric('Attempt 3', '4s', Colors.orange),
              ],
            ),
            SizedBox(height: 1.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildRetryMetric('Attempt 4', '8s', Colors.deepOrange),
                _buildRetryMetric('Attempt 5', '16s', Colors.red),
                _buildRetryMetric('Max', '5', Colors.purple),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRetryMetric(String label, String value, Color color) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(2.w),
          decoration: BoxDecoration(
            color: color.withAlpha(51),
            shape: BoxShape.circle,
          ),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
        SizedBox(height: 0.5.h),
        Text(
          label,
          style: TextStyle(fontSize: 11.sp, color: Colors.grey[600]),
        ),
      ],
    );
  }
}
