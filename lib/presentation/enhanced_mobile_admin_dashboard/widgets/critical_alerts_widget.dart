import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class CriticalAlertsWidget extends StatelessWidget {
  final List<Map<String, dynamic>> alerts;
  final VoidCallback onRefresh;

  const CriticalAlertsWidget({
    super.key,
    required this.alerts,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final sortedAlerts = List<Map<String, dynamic>>.from(alerts)
      ..sort((a, b) {
        final severityOrder = {'critical': 0, 'high': 1, 'medium': 2};
        return (severityOrder[a['severity']] ?? 3).compareTo(
          severityOrder[b['severity']] ?? 3,
        );
      });

    final topAlerts = sortedAlerts.take(10).toList();

    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: topAlerts.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: EdgeInsets.all(3.w),
              itemCount: topAlerts.length,
              itemBuilder: (context, index) {
                return _buildAlertCard(topAlerts[index]);
              },
            ),
    );
  }

  Widget _buildAlertCard(Map<String, dynamic> alert) {
    final severity = alert['severity'] ?? 'medium';
    final title = alert['title'] ?? 'Alert';
    final description = alert['description'] ?? '';
    final timestamp = alert['timestamp'] ?? DateTime.now().toIso8601String();

    final severityColor = _getSeverityColor(severity);
    final severityIcon = _getSeverityIcon(severity);

    return Card(
      margin: EdgeInsets.only(bottom: 2.h),
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(2.w),
                  decoration: BoxDecoration(
                    color: severityColor.withAlpha(26),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Icon(severityIcon, color: severityColor, size: 20.sp),
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        _formatTimestamp(timestamp),
                        style: TextStyle(fontSize: 11.sp, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                _buildSeverityBadge(severity, severityColor),
              ],
            ),
            if (description.isNotEmpty) SizedBox(height: 1.h),
            if (description.isNotEmpty)
              Text(
                description,
                style: TextStyle(fontSize: 12.sp, color: Colors.grey),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSeverityBadge(String severity, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Text(
        severity.toUpperCase(),
        style: TextStyle(
          fontSize: 10.sp,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle, size: 60.sp, color: Colors.green),
          SizedBox(height: 2.h),
          Text(
            'No critical alerts',
            style: TextStyle(fontSize: 14.sp, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'critical':
        return Colors.red;
      case 'high':
        return Colors.orange;
      case 'medium':
        return Colors.yellow.shade700;
      default:
        return Colors.grey;
    }
  }

  IconData _getSeverityIcon(String severity) {
    switch (severity.toLowerCase()) {
      case 'critical':
        return Icons.error;
      case 'high':
        return Icons.warning;
      case 'medium':
        return Icons.info;
      default:
        return Icons.notifications;
    }
  }

  String _formatTimestamp(String timestamp) {
    try {
      final date = DateTime.parse(timestamp);
      final now = DateTime.now();
      final diff = now.difference(date);

      if (diff.inMinutes < 60) {
        return '${diff.inMinutes}m ago';
      } else if (diff.inHours < 24) {
        return '${diff.inHours}h ago';
      } else {
        return '${diff.inDays}d ago';
      }
    } catch (e) {
      return 'Just now';
    }
  }
}
