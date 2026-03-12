import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class IncrementalSyncQueueWidget extends StatelessWidget {
  final List<Map<String, dynamic>> syncQueue;
  final VoidCallback onSync;
  final bool isSyncing;

  const IncrementalSyncQueueWidget({
    super.key,
    required this.syncQueue,
    required this.onSync,
    required this.isSyncing,
  });

  @override
  Widget build(BuildContext context) {
    final batches = (syncQueue.length / 50).ceil();

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
                  'Incremental Sync Queue',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: isSyncing ? null : onSync,
                  icon: Icon(
                    isSyncing ? Icons.sync : Icons.cloud_upload,
                    size: 18.sp,
                  ),
                  label: Text(isSyncing ? 'Syncing...' : 'Sync Now'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                  ),
                ),
              ],
            ),
            SizedBox(height: 1.h),
            Text(
              'Processing batches of 50 records',
              style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
            ),
            SizedBox(height: 2.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildQueueMetric(
                  'Total Items',
                  syncQueue.length.toString(),
                  Icons.list,
                  Colors.blue,
                ),
                _buildQueueMetric(
                  'Batches',
                  batches.toString(),
                  Icons.layers,
                  Colors.purple,
                ),
                _buildQueueMetric(
                  'Next Batch',
                  batches > 0 ? '50' : '0',
                  Icons.fast_forward,
                  Colors.orange,
                ),
              ],
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
