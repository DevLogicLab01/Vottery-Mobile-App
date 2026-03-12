import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class StorageStatusOverviewWidget extends StatelessWidget {
  final Map<String, dynamic> stats;
  final bool isOnline;
  final bool isSyncing;

  const StorageStatusOverviewWidget({
    super.key,
    required this.stats,
    required this.isOnline,
    required this.isSyncing,
  });

  @override
  Widget build(BuildContext context) {
    final syncQueueCount = stats['sync_queue_count'] ?? 0;
    final totalSizeKb = stats['total_size_kb'] ?? 0;
    final cacheHitRate = (stats['cache_hit_rate'] ?? 0.0) * 100;
    final lastSync = stats['last_sync'] ?? 'Never';

    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Storage Status',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: isOnline ? Colors.green : Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: 2.w),
                    Text(
                      isOnline ? 'Online' : 'Offline',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: isOnline ? Colors.green : Colors.red,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 2.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  icon: Icons.sync,
                  label: 'Sync Queue',
                  value: syncQueueCount.toString(),
                  color: syncQueueCount > 0 ? Colors.orange : Colors.green,
                ),
                _buildStatItem(
                  icon: Icons.storage,
                  label: 'Cache Size',
                  value: '${totalSizeKb}KB',
                  color: Colors.blue,
                ),
                _buildStatItem(
                  icon: Icons.speed,
                  label: 'Hit Rate',
                  value: '${cacheHitRate.toStringAsFixed(0)}%',
                  color: Colors.purple,
                ),
              ],
            ),
            SizedBox(height: 2.h),
            if (isSyncing)
              Row(
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 2.w),
                  Text(
                    'Syncing...',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.blue,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              )
            else
              Text(
                'Last sync: $lastSync',
                style: TextStyle(fontSize: 12.sp, color: Colors.grey),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        SizedBox(height: 1.h),
        Text(
          value,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 11.sp, color: Colors.grey),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
