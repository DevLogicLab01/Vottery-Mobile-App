import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class SyncPriorityQueueWidget extends StatelessWidget {
  final int urgentCount;
  final int normalCount;
  final int lowCount;

  const SyncPriorityQueueWidget({
    super.key,
    required this.urgentCount,
    required this.normalCount,
    required this.lowCount,
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
              'Sync Priority Queue',
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 1.h),
            Text(
              'Urgent: votes within 5 min | Normal: profiles within 1 hour | Low: historical within 24 hours',
              style: TextStyle(fontSize: 11.sp, color: Colors.grey[600]),
            ),
            SizedBox(height: 2.h),
            _buildPriorityRow(
              'Urgent',
              urgentCount,
              Colors.red,
              Icons.priority_high,
            ),
            SizedBox(height: 1.h),
            _buildPriorityRow(
              'Normal',
              normalCount,
              Colors.orange,
              Icons.schedule,
            ),
            SizedBox(height: 1.h),
            _buildPriorityRow(
              'Low',
              lowCount,
              Colors.green,
              Icons.low_priority,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriorityRow(
    String label,
    int count,
    Color color,
    IconData icon,
  ) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20.sp),
        SizedBox(width: 2.w),
        Expanded(
          child: Text(
            label,
            style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w500),
          ),
        ),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.5.h),
          decoration: BoxDecoration(
            color: color.withAlpha(51),
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: Text(
            count.toString(),
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}
