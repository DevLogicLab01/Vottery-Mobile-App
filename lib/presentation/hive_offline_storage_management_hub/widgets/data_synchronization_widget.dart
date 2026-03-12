import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class DataSynchronizationWidget extends StatelessWidget {
  final List<Map<String, dynamic>> syncQueue;
  final bool isOnline;
  final bool isSyncing;
  final VoidCallback onSyncPressed;

  const DataSynchronizationWidget({
    super.key,
    required this.syncQueue,
    required this.isOnline,
    required this.isSyncing,
    required this.onSyncPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Data Synchronization',
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 2.h),
            Text(
              'Automatic conflict resolution with three-way merge strategies, sync priority queues, and bandwidth optimization',
              style: TextStyle(fontSize: 12.sp, color: Colors.grey),
            ),
            SizedBox(height: 2.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${syncQueue.length} items in queue',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: isOnline && !isSyncing ? onSyncPressed : null,
                  icon: Icon(
                    isSyncing ? Icons.sync : Icons.cloud_upload,
                    size: 18,
                  ),
                  label: Text(
                    isSyncing ? 'Syncing...' : 'Sync Now',
                    style: TextStyle(fontSize: 12.sp),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(
                      horizontal: 4.w,
                      vertical: 1.h,
                    ),
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
