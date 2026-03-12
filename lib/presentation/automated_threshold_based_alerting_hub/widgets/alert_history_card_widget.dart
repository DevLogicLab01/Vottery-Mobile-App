import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class AlertHistoryCardWidget extends StatelessWidget {
  final Map<String, dynamic> alert;

  const AlertHistoryCardWidget({super.key, required this.alert});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final severity = alert['severity'] ?? 'medium';

    return Card(
      margin: EdgeInsets.only(bottom: 2.h),
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(1.w),
                  decoration: BoxDecoration(
                    color: _getSeverityColor(severity).withAlpha(51),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Icon(
                    Icons.history,
                    color: _getSeverityColor(severity),
                    size: 16.sp,
                  ),
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        alert['metric_type'] ?? 'N/A',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Value: ${alert['metric_value'] ?? 0}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Chip(
                  label: Text(
                    severity.toUpperCase(),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white,
                      fontSize: 10.sp,
                    ),
                  ),
                  backgroundColor: _getSeverityColor(severity),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
            SizedBox(height: 1.h),
            Text(
              'Triggered: ${_formatTimestamp(alert['triggered_at'])}',
              style: theme.textTheme.bodySmall,
            ),
            if (alert['resolved_at'] != null)
              Text(
                'Resolved: ${_formatTimestamp(alert['resolved_at'])}',
                style: theme.textTheme.bodySmall?.copyWith(color: Colors.green),
              ),
          ],
        ),
      ),
    );
  }

  Color _getSeverityColor(String severity) {
    switch (severity) {
      case 'critical':
        return Colors.red;
      case 'high':
        return Colors.orange;
      case 'medium':
        return Colors.yellow.shade700;
      default:
        return Colors.blue;
    }
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'Unknown';
    try {
      final dt = DateTime.parse(timestamp.toString());
      return '${dt.month}/${dt.day}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'Unknown';
    }
  }
}
