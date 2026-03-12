import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class ActiveAlertsWidget extends StatelessWidget {
  final List<Map<String, dynamic>> alerts;
  final Function(String) onAcknowledge;
  final Function(String, String?) onResolve;

  const ActiveAlertsWidget({
    super.key,
    required this.alerts,
    required this.onAcknowledge,
    required this.onResolve,
  });

  @override
  Widget build(BuildContext context) {
    if (alerts.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(8.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.check_circle_outline,
                size: 20.w,
                color: AppTheme.accentLight,
              ),
              SizedBox(height: 2.h),
              Text(
                'No Active Alerts',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimaryLight,
                ),
              ),
              SizedBox(height: 1.h),
              Text(
                'All systems are operating normally',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12.sp,
                  color: AppTheme.textSecondaryLight,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(4.w),
      itemCount: alerts.length,
      itemBuilder: (context, index) {
        final alert = alerts[index];
        return _buildAlertCard(context, alert);
      },
    );
  }

  Widget _buildAlertCard(BuildContext context, Map<String, dynamic> alert) {
    final severity = alert['severity'] ?? 'info';
    final status = alert['status'] ?? 'active';
    final title = alert['title'] ?? 'Unknown Alert';
    final description = alert['description'] ?? '';
    final createdAt = alert['created_at'];
    final affectedComponent = alert['affected_component'];

    Color severityColor;
    IconData severityIcon;

    switch (severity) {
      case 'emergency':
        severityColor = AppTheme.errorLight;
        severityIcon = Icons.emergency;
        break;
      case 'critical':
        severityColor = Colors.deepOrange;
        severityIcon = Icons.error;
        break;
      case 'warning':
        severityColor = AppTheme.warningLight;
        severityIcon = Icons.warning;
        break;
      default:
        severityColor = Colors.blue;
        severityIcon = Icons.info;
    }

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
                  padding: EdgeInsets.all(2.w),
                  decoration: BoxDecoration(
                    color: severityColor.withAlpha(26),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(severityIcon, color: severityColor, size: 6.w),
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimaryLight,
                        ),
                      ),
                      if (affectedComponent != null) ...[
                        SizedBox(height: 0.5.h),
                        Text(
                          affectedComponent,
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: AppTheme.textSecondaryLight,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 2.w,
                    vertical: 0.5.h,
                  ),
                  decoration: BoxDecoration(
                    color: severityColor.withAlpha(26),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    severity.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.bold,
                      color: severityColor,
                    ),
                  ),
                ),
              ],
            ),
            if (description.isNotEmpty) ...[
              SizedBox(height: 2.h),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12.sp,
                  color: AppTheme.textSecondaryLight,
                ),
              ),
            ],
            SizedBox(height: 2.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatTimestamp(createdAt),
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: AppTheme.textSecondaryLight,
                  ),
                ),
                if (status == 'active')
                  Row(
                    children: [
                      TextButton(
                        onPressed: () => onAcknowledge(alert['id']),
                        child: Text(
                          'Acknowledge',
                          style: TextStyle(fontSize: 11.sp),
                        ),
                      ),
                      SizedBox(width: 2.w),
                      ElevatedButton(
                        onPressed: () =>
                            _showResolveDialog(context, alert['id']),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.accentLight,
                          padding: EdgeInsets.symmetric(
                            horizontal: 3.w,
                            vertical: 1.h,
                          ),
                        ),
                        child: Text(
                          'Resolve',
                          style: TextStyle(fontSize: 11.sp),
                        ),
                      ),
                    ],
                  ),
                if (status == 'acknowledged')
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 2.w,
                      vertical: 0.5.h,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.withAlpha(26),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'ACKNOWLEDGED',
                      style: TextStyle(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showResolveDialog(BuildContext context, String alertId) {
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Resolve Alert'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Add resolution notes (optional):',
              style: TextStyle(fontSize: 12.sp),
            ),
            SizedBox(height: 2.h),
            TextField(
              controller: notesController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Describe how the issue was resolved...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onResolve(
                alertId,
                notesController.text.isEmpty ? null : notesController.text,
              );
            },
            child: Text('Resolve'),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'Unknown';
    try {
      final dt = DateTime.parse(timestamp.toString());
      final now = DateTime.now();
      final diff = now.difference(dt);

      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      return '${diff.inDays}d ago';
    } catch (e) {
      return 'Unknown';
    }
  }
}
