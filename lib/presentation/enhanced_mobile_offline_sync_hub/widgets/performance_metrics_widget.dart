import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

/// Performance Metrics Widget
/// Displays sync duration tracking, data volume reduction, and performance monitoring
class PerformanceMetricsWidget extends StatelessWidget {
  final List<Map<String, dynamic>> metrics;

  const PerformanceMetricsWidget({super.key, required this.metrics});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (metrics.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.analytics_outlined,
              size: 15.w,
              color: Colors.grey.withAlpha(77),
            ),
            SizedBox(height: 2.h),
            Text(
              'No Performance Data',
              style: TextStyle(fontSize: 14.sp, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    final avgDuration = _calculateAverage(
      metrics
          .map((m) => (m['sync_duration_ms'] as num?)?.toDouble() ?? 0.0)
          .toList(),
    );
    final avgDataVolume = _calculateAverage(
      metrics
          .map((m) => (m['data_volume_bytes'] as num?)?.toDouble() ?? 0.0)
          .toList(),
    );
    final totalSynced = metrics.fold<int>(
      0,
      (sum, m) => sum + ((m['records_synced'] as num?)?.toInt() ?? 0),
    );
    final totalConflicts = metrics.fold<int>(
      0,
      (sum, m) => sum + ((m['conflicts_detected'] as num?)?.toInt() ?? 0),
    );

    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sync Performance Overview',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'Avg Duration',
                  '${avgDuration.toStringAsFixed(0)}ms',
                  Icons.timer,
                  Colors.blue,
                  theme,
                ),
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: _buildMetricCard(
                  'Avg Data',
                  _formatBytes(avgDataVolume),
                  Icons.data_usage,
                  Colors.green,
                  theme,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'Total Synced',
                  totalSynced.toString(),
                  Icons.sync_alt,
                  Colors.purple,
                  theme,
                ),
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: _buildMetricCard(
                  'Conflicts',
                  totalConflicts.toString(),
                  Icons.warning_amber,
                  Colors.orange,
                  theme,
                ),
              ),
            ],
          ),
          SizedBox(height: 3.h),
          Text(
            'Recent Sync History',
            style: TextStyle(
              fontSize: 15.sp,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 1.h),
          ...metrics.take(10).map((metric) => _buildHistoryItem(metric, theme)),
        ],
      ),
    );
  }

  Widget _buildMetricCard(
    String label,
    String value,
    IconData icon,
    Color color,
    ThemeData theme,
  ) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: color.withAlpha(77)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 8.w, color: color),
          SizedBox(height: 1.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 0.5.h),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.sp,
              color: theme.colorScheme.onSurface.withAlpha(153),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(Map<String, dynamic> metric, ThemeData theme) {
    final duration = metric['sync_duration_ms'] ?? 0;
    final recordsSynced = metric['records_synced'] ?? 0;
    final networkQuality = metric['network_quality'] ?? 'unknown';
    final recordedAt = metric['recorded_at'] != null
        ? DateTime.parse(metric['recorded_at'])
        : DateTime.now();

    return Container(
      margin: EdgeInsets.only(bottom: 1.h),
      padding: EdgeInsets.all(2.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: theme.colorScheme.outline.withAlpha(51)),
      ),
      child: Row(
        children: [
          Icon(
            _getNetworkIcon(networkQuality),
            size: 5.w,
            color: theme.colorScheme.primary,
          ),
          SizedBox(width: 2.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$recordsSynced records in ${duration}ms',
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                Text(
                  _formatTimeAgo(recordedAt),
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: theme.colorScheme.onSurface.withAlpha(153),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  double _calculateAverage(List<double> values) {
    if (values.isEmpty) return 0.0;
    return values.reduce((a, b) => a + b) / values.length;
  }

  String _formatBytes(double bytes) {
    if (bytes < 1024) return '${bytes.toStringAsFixed(0)}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
  }

  IconData _getNetworkIcon(String quality) {
    switch (quality) {
      case 'wifi':
        return Icons.wifi;
      case '4g':
        return Icons.signal_cellular_4_bar;
      case '3g':
        return Icons.signal_cellular_alt;
      default:
        return Icons.signal_cellular_off;
    }
  }

  String _formatTimeAgo(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) return 'just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    return '${difference.inDays}d ago';
  }
}
