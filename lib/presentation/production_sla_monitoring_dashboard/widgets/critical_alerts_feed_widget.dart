import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class CriticalAlertsFeedWidget extends StatelessWidget {
  final List<Map<String, dynamic>> alerts;

  const CriticalAlertsFeedWidget({super.key, required this.alerts});

  @override
  Widget build(BuildContext context) {
    if (alerts.isEmpty) {
      return Card(
        color: Colors.green[50],
        child: Padding(
          padding: EdgeInsets.all(4.w),
          child: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 24.sp),
              SizedBox(width: 3.w),
              Expanded(
                child: Text(
                  'No critical alerts in the last 24 hours',
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: Colors.green[700],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        _buildFilterControls(context),
        SizedBox(height: 2.h),
        ...alerts.take(10).map((alert) => _buildAlertCard(context, alert)),
        if (alerts.length > 10)
          TextButton(
            onPressed: () => _showAllAlerts(context),
            child: Text('View All ${alerts.length} Alerts'),
          ),
      ],
    );
  }

  Widget _buildFilterControls(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search alerts...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: EdgeInsets.symmetric(vertical: 1.h),
            ),
            style: TextStyle(fontSize: 12.sp),
          ),
        ),
        SizedBox(width: 2.w),
        PopupMenuButton<String>(
          icon: Icon(Icons.filter_list),
          onSelected: (value) {},
          itemBuilder: (context) => [
            PopupMenuItem(value: 'all', child: Text('All Alerts')),
            PopupMenuItem(
              value: 'unacknowledged',
              child: Text('Unacknowledged'),
            ),
            PopupMenuItem(value: 'critical', child: Text('Critical Only')),
          ],
        ),
      ],
    );
  }

  Widget _buildAlertCard(BuildContext context, Map<String, dynamic> alert) {
    final severity = alert['severity'] ?? 'P3';
    final type = alert['type'] ?? 'unknown';
    final acknowledged = alert['acknowledged'] ?? false;

    Color severityColor;
    switch (severity) {
      case 'P0':
        severityColor = Colors.red;
        break;
      case 'P1':
        severityColor = Colors.orange;
        break;
      case 'P2':
        severityColor = Colors.yellow[700]!;
        break;
      default:
        severityColor = Colors.blue;
    }

    IconData typeIcon;
    switch (type) {
      case 'security_incident':
        typeIcon = Icons.security;
        break;
      case 'system_error':
        typeIcon = Icons.error;
        break;
      case 'performance_degradation':
        typeIcon = Icons.speed;
        break;
      default:
        typeIcon = Icons.warning;
    }

    return Card(
      margin: EdgeInsets.only(bottom: 2.h),
      elevation: acknowledged ? 1 : 3,
      child: ListTile(
        leading: Container(
          padding: EdgeInsets.all(2.w),
          decoration: BoxDecoration(
            color: severityColor.withAlpha(51),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(typeIcon, color: severityColor, size: 20.sp),
        ),
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
              decoration: BoxDecoration(
                color: severityColor,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                severity,
                style: TextStyle(
                  fontSize: 10.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            SizedBox(width: 2.w),
            Expanded(
              child: Text(
                alert['title'] ?? 'Unknown Alert',
                style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 0.5.h),
            Text(
              alert['description'] ?? '',
              style: TextStyle(fontSize: 11.sp),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 0.5.h),
            Row(
              children: [
                Icon(Icons.source, size: 12.sp, color: Colors.grey[600]),
                SizedBox(width: 1.w),
                Text(
                  alert['source'] ?? 'Unknown',
                  style: TextStyle(fontSize: 10.sp, color: Colors.grey[600]),
                ),
                SizedBox(width: 3.w),
                Icon(Icons.access_time, size: 12.sp, color: Colors.grey[600]),
                SizedBox(width: 1.w),
                Text(
                  _formatTimestamp(alert['detected_at']),
                  style: TextStyle(fontSize: 10.sp, color: Colors.grey[600]),
                ),
              ],
            ),
          ],
        ),
        trailing: acknowledged
            ? Icon(Icons.check, color: Colors.green)
            : ElevatedButton(
                onPressed: () => _acknowledgeAlert(context, alert),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                ),
                child: Text('Acknowledge', style: TextStyle(fontSize: 10.sp)),
              ),
        onTap: () => _showAlertDetails(context, alert),
      ),
    );
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'Unknown';

    try {
      final date = DateTime.parse(timestamp.toString());
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inMinutes < 1) {
        return 'Just now';
      } else if (difference.inMinutes < 60) {
        return '${difference.inMinutes}m ago';
      } else if (difference.inHours < 24) {
        return '${difference.inHours}h ago';
      } else {
        return '${difference.inDays}d ago';
      }
    } catch (e) {
      return 'Unknown';
    }
  }

  void _acknowledgeAlert(BuildContext context, Map<String, dynamic> alert) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Alert acknowledged')));
  }

  void _showAlertDetails(BuildContext context, Map<String, dynamic> alert) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Alert Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Title', alert['title'] ?? 'N/A'),
              _buildDetailRow('Severity', alert['severity'] ?? 'N/A'),
              _buildDetailRow('Type', alert['type'] ?? 'N/A'),
              _buildDetailRow('Description', alert['description'] ?? 'N/A'),
              _buildDetailRow('Source', alert['source'] ?? 'N/A'),
              _buildDetailRow('Detected At', alert['detected_at'] ?? 'N/A'),
              if (alert['affected_systems'] != null)
                _buildDetailRow(
                  'Affected Systems',
                  (alert['affected_systems'] as List).join(', '),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _acknowledgeAlert(context, alert);
            },
            child: Text('Acknowledge'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 1.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 0.5.h),
          Text(value, style: TextStyle(fontSize: 12.sp)),
        ],
      ),
    );
  }

  void _showAllAlerts(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        builder: (context, scrollController) => Container(
          padding: EdgeInsets.all(4.w),
          child: Column(
            children: [
              Text(
                'All Alerts (${alerts.length})',
                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 2.h),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: alerts.length,
                  itemBuilder: (context, index) =>
                      _buildAlertCard(context, alerts[index]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
