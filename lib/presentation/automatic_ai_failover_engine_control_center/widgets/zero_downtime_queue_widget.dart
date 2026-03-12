import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class ZeroDowntimeQueueWidget extends StatelessWidget {
  final int queuedRequests;
  final int processingTime;

  const ZeroDowntimeQueueWidget({
    super.key,
    required this.queuedRequests,
    required this.processingTime,
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
              'Zero-Downtime Request Queue',
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 1.h),
            Text(
              'Request queuing during failover transitions',
              style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
            ),
            SizedBox(height: 2.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildQueueMetric(
                  'Queued Requests',
                  queuedRequests.toString(),
                  Icons.queue,
                  Colors.blue,
                ),
                _buildQueueMetric(
                  'Avg Processing',
                  '${processingTime}ms',
                  Icons.timer,
                  Colors.green,
                ),
              ],
            ),
            SizedBox(height: 2.h),
            if (queuedRequests > 0)
              Container(
                padding: EdgeInsets.all(2.w),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info, color: Colors.orange, size: 20.sp),
                    SizedBox(width: 2.w),
                    Expanded(
                      child: Text(
                        'Requests are being queued during failover. Zero downtime maintained.',
                        style: TextStyle(fontSize: 12.sp),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildQueueMetric(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28.sp),
        SizedBox(height: 0.5.h),
        Text(
          value,
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        SizedBox(height: 0.5.h),
        Text(
          label,
          style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
