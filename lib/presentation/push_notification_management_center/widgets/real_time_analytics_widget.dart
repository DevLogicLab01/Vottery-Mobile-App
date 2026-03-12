import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class RealTimeAnalyticsWidget extends StatelessWidget {
  final Map<String, dynamic> stats;

  const RealTimeAnalyticsWidget({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final deliverySuccessRate = (stats['delivery_rate'] ?? 0.85) * 100;
    final engagementRate = (stats['engagement_rate'] ?? 0.42) * 100;

    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Real-time Analytics',
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 2.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMetric(
                  label: 'Delivery Success',
                  value: '${deliverySuccessRate.toStringAsFixed(1)}%',
                  color: Colors.green,
                ),
                _buildMetric(
                  label: 'Engagement Rate',
                  value: '${engagementRate.toStringAsFixed(1)}%',
                  color: Colors.blue,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetric({
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12.sp, color: Colors.grey),
        ),
      ],
    );
  }
}
