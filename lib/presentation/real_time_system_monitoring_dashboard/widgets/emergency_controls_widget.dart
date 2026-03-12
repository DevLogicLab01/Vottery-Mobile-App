import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class EmergencyControlsWidget extends StatefulWidget {
  final Function({
    required String actionType,
    required String actionName,
    required String reason,
  })
  onTriggerAction;

  const EmergencyControlsWidget({super.key, required this.onTriggerAction});

  @override
  State<EmergencyControlsWidget> createState() =>
      _EmergencyControlsWidgetState();
}

class _EmergencyControlsWidgetState extends State<EmergencyControlsWidget> {
  final List<Map<String, dynamic>> _emergencyActions = [
    {
      'type': 'service_isolation',
      'name': 'Isolate Service',
      'description': 'Isolate a specific service to prevent cascading failures',
      'icon': Icons.block,
      'color': Colors.orange,
      'severity': 'high',
    },
    {
      'type': 'traffic_throttling',
      'name': 'Throttle Traffic',
      'description': 'Reduce incoming traffic to prevent system overload',
      'icon': Icons.speed,
      'color': Colors.amber,
      'severity': 'medium',
    },
    {
      'type': 'maintenance_mode',
      'name': 'Maintenance Mode',
      'description': 'Enable maintenance mode for system-wide updates',
      'icon': Icons.build,
      'color': Colors.blue,
      'severity': 'low',
    },
    {
      'type': 'emergency_shutdown',
      'name': 'Emergency Shutdown',
      'description':
          'Immediately shut down non-critical services to preserve core functionality',
      'icon': Icons.power_settings_new,
      'color': AppTheme.errorLight,
      'severity': 'critical',
    },
    {
      'type': 'failover_activation',
      'name': 'Activate Failover',
      'description': 'Switch to backup systems and redundant infrastructure',
      'icon': Icons.swap_horiz,
      'color': Colors.deepPurple,
      'severity': 'high',
    },
    {
      'type': 'cache_purge',
      'name': 'Purge Cache',
      'description': 'Clear all caches to resolve data inconsistency issues',
      'icon': Icons.delete_sweep,
      'color': Colors.teal,
      'severity': 'low',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: AppTheme.errorLight.withAlpha(26),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.errorLight, width: 2),
            ),
            child: Row(
              children: [
                Icon(Icons.warning, color: AppTheme.errorLight, size: 8.w),
                SizedBox(width: 3.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Emergency Controls',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.errorLight,
                        ),
                      ),
                      SizedBox(height: 0.5.h),
                      Text(
                        'Use these controls only in critical situations. All actions are logged and require admin authorization.',
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: AppTheme.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 3.h),
          Text(
            'Available Emergency Actions',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          SizedBox(height: 2.h),
          ..._emergencyActions.map((action) => _buildActionCard(action)),
        ],
      ),
    );
  }

  Widget _buildActionCard(Map<String, dynamic> action) {
    return Card(
      margin: EdgeInsets.only(bottom: 2.h),
      child: InkWell(
        onTap: () => _showConfirmationDialog(action),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: EdgeInsets.all(4.w),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(3.w),
                decoration: BoxDecoration(
                  color: (action['color'] as Color).withAlpha(26),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  action['icon'] as IconData,
                  color: action['color'] as Color,
                  size: 7.w,
                ),
              ),
              SizedBox(width: 4.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            action['name'],
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimaryLight,
                            ),
                          ),
                        ),
                        _buildSeverityBadge(action['severity']),
                      ],
                    ),
                    SizedBox(height: 1.h),
                    Text(
                      action['description'],
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: AppTheme.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: AppTheme.textSecondaryLight),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSeverityBadge(String severity) {
    Color color;
    switch (severity) {
      case 'critical':
        color = AppTheme.errorLight;
        break;
      case 'high':
        color = Colors.deepOrange;
        break;
      case 'medium':
        color = AppTheme.warningLight;
        break;
      default:
        color = Colors.blue;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        severity.toUpperCase(),
        style: TextStyle(
          fontSize: 9.sp,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  void _showConfirmationDialog(Map<String, dynamic> action) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: AppTheme.errorLight, size: 6.w),
            SizedBox(width: 2.w),
            Expanded(
              child: Text(
                'Confirm Emergency Action',
                style: TextStyle(fontSize: 14.sp),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You are about to trigger:',
              style: TextStyle(
                fontSize: 12.sp,
                color: AppTheme.textSecondaryLight,
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              action['name'],
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryLight,
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              action['description'],
              style: TextStyle(
                fontSize: 11.sp,
                color: AppTheme.textSecondaryLight,
              ),
            ),
            SizedBox(height: 3.h),
            Text(
              'Reason (required):',
              style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 1.h),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Explain why this action is necessary...',
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
              if (reasonController.text.trim().isEmpty) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('Reason is required')));
                return;
              }

              Navigator.pop(context);
              widget.onTriggerAction(
                actionType: action['type'],
                actionName: action['name'],
                reason: reasonController.text.trim(),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorLight,
            ),
            child: Text('Confirm & Execute'),
          ),
        ],
      ),
    );
  }
}
