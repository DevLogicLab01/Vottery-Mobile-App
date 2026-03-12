import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class ActiveAlertCardWidget extends StatelessWidget {
  final Map<String, dynamic> alert;
  final VoidCallback onAcknowledge;
  final VoidCallback onResolve;

  const ActiveAlertCardWidget({
    super.key,
    required this.alert,
    required this.onAcknowledge,
    required this.onResolve,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final severity = alert['severity'] ?? 'medium';
    final isAcknowledged = alert['is_acknowledged'] ?? false;

    return Card(
      margin: EdgeInsets.only(bottom: 2.h),
      color: _getSeverityColor(severity).withAlpha(26),
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.warning,
                  color: _getSeverityColor(severity),
                  size: 20.sp,
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: Text(
                    alert['message'] ?? 'Alert triggered',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 1.h),
            Text(
              'Metric: ${alert['metric_type'] ?? 'N/A'}',
              style: theme.textTheme.bodyMedium,
            ),
            Text(
              'Current: ${alert['current_value'] ?? 0} | Threshold: ${alert['threshold_value'] ?? 0}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              'Triggered: ${_formatTimestamp(alert['triggered_at'])}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (isAcknowledged) ...[
              SizedBox(height: 1.h),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                decoration: BoxDecoration(
                  color: Colors.blue.withAlpha(51),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Acknowledged',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
            SizedBox(height: 2.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (!isAcknowledged)
                  TextButton.icon(
                    onPressed: onAcknowledge,
                    icon: Icon(Icons.check, size: 16.sp),
                    label: Text('Acknowledge'),
                  ),
                SizedBox(width: 2.w),
                ElevatedButton.icon(
                  onPressed: onResolve,
                  icon: Icon(Icons.done_all, size: 16.sp),
                  label: Text('Resolve'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
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
      final now = DateTime.now();
      final diff = now.difference(dt);

      if (diff.inMinutes < 60) {
        return '${diff.inMinutes}m ago';
      } else if (diff.inHours < 24) {
        return '${diff.inHours}h ago';
      } else {
        return '${diff.inDays}d ago';
      }
    } catch (e) {
      return 'Unknown';
    }
  }
}
