import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class AdvancedSyncManagementWidget extends StatelessWidget {
  final Map<String, dynamic> syncStats;
  final VoidCallback onClearQueue;

  const AdvancedSyncManagementWidget({
    super.key,
    required this.syncStats,
    required this.onClearQueue,
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
              'Advanced Sync Management',
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 2.h),
            _buildStatRow(
              'Total Synced',
              syncStats['total_synced']?.toString() ?? '0',
            ),
            SizedBox(height: 1.h),
            _buildStatRow('Last Sync', syncStats['last_sync'] ?? 'Never'),
            SizedBox(height: 1.h),
            _buildStatRow(
              'Queue Depth',
              syncStats['queue_depth']?.toString() ?? '0',
            ),
            SizedBox(height: 2.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onClearQueue,
                icon: Icon(Icons.clear_all, size: 18.sp),
                label: const Text('Clear Sync Queue'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: EdgeInsets.symmetric(vertical: 1.5.h),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 13.sp, color: Colors.grey[700]),
        ),
        Text(
          value,
          style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
