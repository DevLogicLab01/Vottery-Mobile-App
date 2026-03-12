import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../theme/app_theme.dart';
import '../../../widgets/enhanced_empty_state_widget.dart';

class OfflineQueueMonitorWidget extends StatelessWidget {
  final List<Map<String, dynamic>> queueItems;
  final Future<void> Function(String itemId) onRetry;
  final Future<void> Function() onClear;
  final Future<void> Function() onRefresh;

  const OfflineQueueMonitorWidget({
    super.key,
    required this.queueItems,
    required this.onRetry,
    required this.onClear,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (queueItems.isEmpty) {
      return EnhancedEmptyStateWidget(
        title: 'Queue is Empty',
        description: 'All operations have been synchronized',
      );
    }

    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(3.w),
          color: Colors.white,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${queueItems.length} items in queue',
                style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimaryLight,
                ),
              ),
              TextButton.icon(
                onPressed: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Clear Queue'),
                      content: const Text(
                        'Are you sure you want to clear all pending items? This action cannot be undone.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.red,
                          ),
                          child: const Text('Clear All'),
                        ),
                      ],
                    ),
                  );

                  if (confirmed == true) {
                    await onClear();
                  }
                },
                icon: const Icon(Icons.clear_all, size: 18),
                label: const Text('Clear All'),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
              ),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: onRefresh,
            child: ListView.builder(
              padding: EdgeInsets.all(3.w),
              itemCount: queueItems.length,
              itemBuilder: (context, index) {
                final item = queueItems[index];
                return _buildQueueItemCard(context, item);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQueueItemCard(BuildContext context, Map<String, dynamic> item) {
    final itemId = item['id'] ?? '';
    final operationType = item['operation_type'] ?? 'unknown';
    final contentType = item['content_type'] ?? 'unknown';
    final status = item['status'] ?? 'pending';
    final retryCount = item['retry_count'] ?? 0;
    final queuedAt = item['queued_at'] as DateTime?;
    final priority = item['priority'] ?? 'normal';

    Color statusColor;
    IconData statusIcon;

    switch (status) {
      case 'syncing':
        statusColor = Colors.blue;
        statusIcon = Icons.sync;
        break;
      case 'failed':
        statusColor = Colors.red;
        statusIcon = Icons.error;
        break;
      case 'pending':
      default:
        statusColor = Colors.orange;
        statusIcon = Icons.pending;
    }

    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: statusColor.withAlpha(77), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 10.0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(2.w),
                decoration: BoxDecoration(
                  color: statusColor.withAlpha(26),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Icon(statusIcon, color: statusColor, size: 18.sp),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${operationType.toUpperCase()} - ${contentType.toUpperCase()}',
                      style: GoogleFonts.inter(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimaryLight,
                      ),
                    ),
                    if (queuedAt != null)
                      Text(
                        'Queued ${_formatTimestamp(queuedAt)}',
                        style: GoogleFonts.inter(
                          fontSize: 11.sp,
                          color: Colors.grey,
                        ),
                      ),
                  ],
                ),
              ),
              if (priority == 'high')
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 2.w,
                    vertical: 0.5.h,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red.withAlpha(26),
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: Text(
                    'HIGH PRIORITY',
                    style: GoogleFonts.inter(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.red,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 1.5.h),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Status',
                      style: GoogleFonts.inter(
                        fontSize: 11.sp,
                        color: Colors.grey,
                      ),
                    ),
                    Text(
                      status.toUpperCase(),
                      style: GoogleFonts.inter(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Retry Count',
                      style: GoogleFonts.inter(
                        fontSize: 11.sp,
                        color: Colors.grey,
                      ),
                    ),
                    Text(
                      retryCount.toString(),
                      style: GoogleFonts.inter(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimaryLight,
                      ),
                    ),
                  ],
                ),
              ),
              if (status == 'failed')
                ElevatedButton.icon(
                  onPressed: () => onRetry(itemId),
                  icon: Icon(Icons.refresh, size: 16.sp),
                  label: Text(
                    'Retry',
                    style: GoogleFonts.inter(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryLight,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                      horizontal: 3.w,
                      vertical: 1.h,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}
