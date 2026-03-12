import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

/// Sync Queue Widget
/// Displays pending changes with estimated sync times and priority indicators
class SyncQueueWidget extends StatelessWidget {
  final List<Map<String, dynamic>> syncQueue;
  final VoidCallback onRefresh;

  const SyncQueueWidget({
    super.key,
    required this.syncQueue,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (syncQueue.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 15.w,
              color: Colors.green.withAlpha(77),
            ),
            SizedBox(height: 2.h),
            Text(
              'All Synced',
              style: TextStyle(fontSize: 14.sp, color: Colors.grey),
            ),
            SizedBox(height: 1.h),
            Text(
              'No pending changes',
              style: TextStyle(fontSize: 12.sp, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(4.w),
      itemCount: syncQueue.length,
      itemBuilder: (context, index) {
        return _buildQueueItem(syncQueue[index], theme);
      },
    );
  }

  Widget _buildQueueItem(Map<String, dynamic> item, ThemeData theme) {
    final priority = item['priority'] ?? 'medium';
    final priorityColor = _getPriorityColor(priority);
    final operationType = item['operation_type'] ?? 'update';
    final tableName = item['table_name'] ?? 'Unknown';
    final queuedAt = item['queued_at'] != null
        ? DateTime.parse(item['queued_at'])
        : DateTime.now();
    final retryCount = item['retry_count'] ?? 0;

    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: priorityColor.withAlpha(77), width: 2.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                decoration: BoxDecoration(
                  color: priorityColor.withAlpha(26),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Text(
                  priority.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                    color: priorityColor,
                  ),
                ),
              ),
              SizedBox(width: 2.w),
              Icon(
                _getOperationIcon(operationType),
                size: 5.w,
                color: theme.colorScheme.primary,
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: Text(
                  tableName,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
              if (retryCount > 0)
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 2.w,
                    vertical: 0.5.h,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.withAlpha(26),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Text(
                    'Retry $retryCount',
                    style: TextStyle(fontSize: 11.sp, color: Colors.orange),
                  ),
                ),
            ],
          ),
          SizedBox(height: 1.h),
          Row(
            children: [
              Icon(
                Icons.access_time,
                size: 4.w,
                color: theme.colorScheme.onSurface.withAlpha(153),
              ),
              SizedBox(width: 1.w),
              Text(
                'Queued ${_formatTimeAgo(queuedAt)}',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: theme.colorScheme.onSurface.withAlpha(153),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'critical':
        return Colors.red;
      case 'high':
        return Colors.orange;
      case 'medium':
        return Colors.blue;
      case 'low':
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }

  IconData _getOperationIcon(String operation) {
    switch (operation) {
      case 'insert':
        return Icons.add_circle_outline;
      case 'update':
        return Icons.edit_outlined;
      case 'delete':
        return Icons.delete_outline;
      default:
        return Icons.sync;
    }
  }

  String _formatTimeAgo(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return 'just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}
