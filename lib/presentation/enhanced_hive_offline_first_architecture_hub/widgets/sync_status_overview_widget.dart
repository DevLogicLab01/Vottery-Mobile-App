import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class SyncStatusOverviewWidget extends StatelessWidget {
  final int queueDepth;
  final double dataReduction;
  final double conflictSuccessRate;
  final bool isOnline;
  final bool isSyncing;

  const SyncStatusOverviewWidget({
    super.key,
    required this.queueDepth,
    required this.dataReduction,
    required this.conflictSuccessRate,
    required this.isOnline,
    required this.isSyncing,
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Enhanced Sync Status',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Row(
                  children: [
                    Icon(
                      isOnline ? Icons.cloud_done : Icons.cloud_off,
                      color: isOnline ? Colors.green : Colors.red,
                      size: 20.sp,
                    ),
                    SizedBox(width: 1.w),
                    if (isSyncing)
                      SizedBox(
                        width: 16.sp,
                        height: 16.sp,
                        child: const CircularProgressIndicator(strokeWidth: 2),
                      ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 2.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMetricCard(
                  'Queue Depth',
                  queueDepth.toString(),
                  Icons.queue,
                  Colors.blue,
                ),
                _buildMetricCard(
                  'Data Reduction',
                  '${dataReduction.toStringAsFixed(1)}%',
                  Icons.compress,
                  Colors.green,
                ),
                _buildMetricCard(
                  'Conflict Success',
                  '${conflictSuccessRate.toStringAsFixed(1)}%',
                  Icons.check_circle,
                  Colors.orange,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24.sp),
        SizedBox(height: 0.5.h),
        Text(
          value,
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        SizedBox(height: 0.5.h),
        Text(
          label,
          style: TextStyle(fontSize: 11.sp, color: Colors.grey[600]),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
