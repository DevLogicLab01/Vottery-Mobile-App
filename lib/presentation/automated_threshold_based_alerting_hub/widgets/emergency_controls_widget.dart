import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class EmergencyControlsWidget extends StatelessWidget {
  final VoidCallback onSuspendAll;
  final VoidCallback onMuteAll;

  const EmergencyControlsWidget({
    super.key,
    required this.onSuspendAll,
    required this.onMuteAll,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      color: Colors.red.shade50,
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.emergency, color: Colors.red, size: 20.sp),
                SizedBox(width: 2.w),
                Text(
                  'Emergency Controls',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
            SizedBox(height: 2.h),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showConfirmDialog(
                      context,
                      'Suspend All Rules',
                      'This will pause all active alert rules. Continue?',
                      onSuspendAll,
                    ),
                    icon: Icon(Icons.pause_circle, size: 16.sp),
                    label: Text('Suspend All'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showConfirmDialog(
                      context,
                      'Mute All Alerts',
                      'This will mute all notifications for 1 hour. Continue?',
                      onMuteAll,
                    ),
                    icon: Icon(Icons.volume_off, size: 16.sp),
                    label: Text('Mute All'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
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

  void _showConfirmDialog(
    BuildContext context,
    String title,
    String message,
    VoidCallback onConfirm,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onConfirm();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text('Confirm'),
          ),
        ],
      ),
    );
  }
}
