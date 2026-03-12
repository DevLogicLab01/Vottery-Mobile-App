import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:timeago/timeago.dart' as timeago;

class ConnectionStatusWidget extends StatelessWidget {
  final Map<String, dynamic> connectionStatus;
  final VoidCallback onRefresh;

  const ConnectionStatusWidget({
    super.key,
    required this.connectionStatus,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final isConnected = connectionStatus['connected'] ?? false;
    final lastUpdated = connectionStatus['last_updated'];
    final activeChannels = connectionStatus['active_channels'] ?? 0;
    final totalViewers = connectionStatus['total_viewers'] ?? 0;

    return Card(
      elevation: 2.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isConnected ? Colors.green : Colors.red,
                      ),
                    ),
                    SizedBox(width: 2.w),
                    Text(
                      isConnected ? 'Live' : 'Disconnected',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: isConnected ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: Icon(Icons.refresh),
                  onPressed: onRefresh,
                  tooltip: 'Refresh Status',
                ),
              ],
            ),
            SizedBox(height: 1.h),
            if (lastUpdated != null)
              Text(
                'Last updated: ${timeago.format(DateTime.parse(lastUpdated))}',
                style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
              ),
            SizedBox(height: 2.h),
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    'Active Channels',
                    activeChannels.toString(),
                    Icons.stream,
                    Colors.blue,
                  ),
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: _buildMetricCard(
                    'Total Viewers',
                    totalViewers.toString(),
                    Icons.people,
                    Colors.purple,
                  ),
                ),
              ],
            ),
            SizedBox(height: 1.h),
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    'Bandwidth',
                    'Optimized',
                    Icons.speed,
                    Colors.green,
                  ),
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: _buildMetricCard(
                    'Compression',
                    '85%',
                    Icons.compress,
                    Colors.orange,
                  ),
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
    return Container(
      padding: EdgeInsets.all(2.w),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          SizedBox(height: 0.5.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 10.sp, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
