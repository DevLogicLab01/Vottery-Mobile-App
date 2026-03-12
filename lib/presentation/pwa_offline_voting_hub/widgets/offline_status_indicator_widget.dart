import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class OfflineStatusIndicatorWidget extends StatelessWidget {
  final bool isOnline;
  final int cachedVotesCount;
  final int pendingVotesCount;
  final DateTime? lastSyncTime;

  const OfflineStatusIndicatorWidget({
    super.key,
    required this.isOnline,
    required this.cachedVotesCount,
    required this.pendingVotesCount,
    this.lastSyncTime,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(4.w),
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
              Container(
                width: 3.w,
                height: 3.w,
                decoration: BoxDecoration(
                  color: isOnline ? Colors.green : Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: 2.w),
              Text(
                isOnline ? 'Online' : 'Offline',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: isOnline ? Colors.green : Colors.red,
                ),
              ),
              const Spacer(),
              if (lastSyncTime != null)
                Text(
                  'Last sync: ${timeago.format(lastSyncTime!)}',
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: AppTheme.textSecondaryLight,
                  ),
                ),
            ],
          ),
          SizedBox(height: 3.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                icon: Icons.cloud_download,
                label: 'Cached Elections',
                value: cachedVotesCount.toString(),
                color: Colors.blue,
              ),
              _buildStatItem(
                icon: Icons.sync,
                label: 'Pending Sync',
                value: pendingVotesCount.toString(),
                color: Colors.orange,
              ),
              _buildStatItem(
                icon: Icons.check_circle,
                label: 'Status',
                value: isOnline ? 'Ready' : 'Offline',
                color: isOnline ? Colors.green : Colors.grey,
              ),
            ],
          ),
        ],
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
        Icon(icon, size: 8.w, color: color),
        SizedBox(height: 1.h),
        Text(
          value,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 0.5.h),
        Text(
          label,
          style: TextStyle(fontSize: 9.sp, color: AppTheme.textSecondaryLight),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
