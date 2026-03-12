import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

/// Sync Status Header Widget
/// Displays queue length, last sync timestamp, and network quality indicators
class SyncStatusHeaderWidget extends StatelessWidget {
  final int queueLength;
  final DateTime? lastSyncTime;
  final bool isOnline;
  final String networkQuality;
  final String syncStrategy;

  const SyncStatusHeaderWidget({
    super.key,
    required this.queueLength,
    required this.lastSyncTime,
    required this.isOnline,
    required this.networkQuality,
    required this.syncStrategy,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = isOnline ? Colors.green : Colors.red;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [statusColor, statusColor.withAlpha(179)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isOnline ? Icons.cloud_done : Icons.cloud_off,
                color: Colors.white,
                size: 6.w,
              ),
              SizedBox(width: 2.w),
              Text(
                isOnline ? 'Online' : 'Offline',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.5.h),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(51),
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Text(
                  _formatNetworkQuality(networkQuality),
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMetric('Queue', queueLength.toString(), Icons.queue),
              _buildMetric(
                'Strategy',
                _formatSyncStrategy(syncStrategy),
                Icons.settings_suggest,
              ),
              _buildMetric(
                'Last Sync',
                _formatLastSync(lastSyncTime),
                Icons.access_time,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetric(String label, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.white70, size: 4.w),
            SizedBox(width: 1.w),
            Text(
              label,
              style: TextStyle(fontSize: 11.sp, color: Colors.white70),
            ),
          ],
        ),
        SizedBox(height: 0.5.h),
        Text(
          value,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  String _formatNetworkQuality(String quality) {
    switch (quality) {
      case 'wifi':
        return 'WiFi';
      case '4g':
        return '4G';
      case '3g':
        return '3G';
      case '2g':
        return '2G';
      default:
        return 'Offline';
    }
  }

  String _formatSyncStrategy(String strategy) {
    switch (strategy) {
      case 'realtime':
        return 'Real-time';
      case 'interval_30s':
        return '30s';
      case 'interval_5min':
        return '5min';
      default:
        return 'Manual';
    }
  }

  String _formatLastSync(DateTime? time) {
    if (time == null) return 'Never';

    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}
