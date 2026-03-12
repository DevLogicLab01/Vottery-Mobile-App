import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class BackgroundSyncMonitorWidget extends StatelessWidget {
  final bool isOnline;
  final DateTime? lastSyncTime;
  final double syncProgress;

  const BackgroundSyncMonitorWidget({
    super.key,
    required this.isOnline,
    this.lastSyncTime,
    required this.syncProgress,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 8.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.cloud_sync, size: 6.w, color: AppTheme.primaryLight),
              SizedBox(width: 2.w),
              Text(
                'Background Sync Monitor',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          _buildSyncStatusRow(
            label: 'Service Worker Status',
            value: isOnline ? 'Active' : 'Offline Mode',
            color: isOnline ? Colors.green : Colors.orange,
          ),
          SizedBox(height: 1.h),
          _buildSyncStatusRow(
            label: 'Sync Progress',
            value: '${(syncProgress * 100).toStringAsFixed(0)}%',
            color: syncProgress == 1.0 ? Colors.green : Colors.blue,
          ),
          SizedBox(height: 1.h),
          if (lastSyncTime != null)
            _buildSyncStatusRow(
              label: 'Last Sync',
              value: timeago.format(lastSyncTime!),
              color: Colors.grey,
            ),
          SizedBox(height: 2.h),
          LinearProgressIndicator(
            value: syncProgress,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(
              syncProgress == 1.0 ? Colors.green : AppTheme.primaryLight,
            ),
          ),
          SizedBox(height: 2.h),
          Container(
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: Colors.blue.withAlpha(13),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 5.w, color: Colors.blue),
                SizedBox(width: 2.w),
                Expanded(
                  child: Text(
                    'Background sync uses WorkManager for automatic synchronization when connectivity is restored.',
                    style: TextStyle(
                      fontSize: 10.sp,
                      color: AppTheme.textSecondaryLight,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSyncStatusRow({
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 11.sp, color: AppTheme.textSecondaryLight),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 11.sp,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}
