import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class RealTimeMetricsPanelWidget extends StatelessWidget {
  final Map<String, dynamic> metrics;
  final int secondsUntilRefresh;

  const RealTimeMetricsPanelWidget({
    super.key,
    required this.metrics,
    required this.secondsUntilRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final requestRate = metrics['request_rate'] ?? 0.0;
    final errorRate = metrics['error_rate'] ?? 0.0;
    final avgLatency = metrics['average_latency_ms'] ?? 0.0;
    final activeUsers = metrics['active_users'] ?? 0;
    final queueDepth = metrics['queue_depth'] ?? 0;

    return Card(
      elevation: 3,
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Real-time System Metrics',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withAlpha(26),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.refresh,
                        size: 14.sp,
                        color: Theme.of(context).primaryColor,
                      ),
                      SizedBox(width: 1.w),
                      Text(
                        '${secondsUntilRefresh}s',
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 3.h),
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    context,
                    'Request Rate',
                    '${requestRate.toStringAsFixed(1)}/s',
                    Icons.trending_up,
                    Colors.blue,
                  ),
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: _buildMetricCard(
                    context,
                    'Error Rate',
                    '${errorRate.toStringAsFixed(2)}%',
                    Icons.error_outline,
                    errorRate > 5 ? Colors.red : Colors.green,
                  ),
                ),
              ],
            ),
            SizedBox(height: 2.h),
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    context,
                    'Avg Latency',
                    '${avgLatency.toStringAsFixed(0)}ms',
                    Icons.speed,
                    avgLatency > 1000 ? Colors.orange : Colors.green,
                  ),
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: _buildMetricCard(
                    context,
                    'Active Users',
                    activeUsers.toString(),
                    Icons.people,
                    Colors.purple,
                  ),
                ),
              ],
            ),
            SizedBox(height: 2.h),
            _buildMetricCard(
              context,
              'Queue Depth',
              queueDepth.toString(),
              Icons.queue,
              queueDepth > 100 ? Colors.red : Colors.green,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(77)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18.sp, color: color),
              SizedBox(width: 2.w),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
