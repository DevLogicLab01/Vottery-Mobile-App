import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:intl/intl.dart';

class EventProcessingFeedWidget extends StatelessWidget {
  final List<Map<String, dynamic>> events;

  const EventProcessingFeedWidget({super.key, required this.events});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (events.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_note, size: 48.sp, color: Colors.grey[400]),
            SizedBox(height: 2.h),
            Text(
              'No webhook events received yet',
              style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: EdgeInsets.all(4.w),
      itemCount: events.length,
      separatorBuilder: (context, index) => SizedBox(height: 2.h),
      itemBuilder: (context, index) {
        final event = events[index];
        return _buildEventCard(context, theme, event);
      },
    );
  }

  Widget _buildEventCard(
    BuildContext context,
    ThemeData theme,
    Map<String, dynamic> event,
  ) {
    final provider = event['provider'] as String? ?? 'unknown';
    final eventType = event['event_type'] as String? ?? 'unknown';
    final processed = event['processed'] as bool? ?? false;
    final receivedAt = event['received_at'] as String?;

    final providerColor = provider == 'telnyx' ? Colors.blue : Colors.purple;
    final statusColor = processed ? Colors.green : Colors.orange;

    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: providerColor.withAlpha(51)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                decoration: BoxDecoration(
                  color: providerColor.withAlpha(26),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  provider.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.bold,
                    color: providerColor,
                  ),
                ),
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: Text(
                  eventType,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                decoration: BoxDecoration(
                  color: statusColor.withAlpha(26),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      processed ? Icons.check_circle : Icons.pending,
                      color: statusColor,
                      size: 12.sp,
                    ),
                    SizedBox(width: 1.w),
                    Text(
                      processed ? 'Processed' : 'Pending',
                      style: TextStyle(
                        fontSize: 10.sp,
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (receivedAt != null) ...[
            SizedBox(height: 1.h),
            Row(
              children: [
                Icon(Icons.access_time, size: 12.sp, color: Colors.grey[600]),
                SizedBox(width: 1.w),
                Text(
                  _formatTimestamp(receivedAt),
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _formatTimestamp(String timestamp) {
    try {
      final dateTime = DateTime.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inMinutes < 1) {
        return 'Just now';
      } else if (difference.inHours < 1) {
        return '${difference.inMinutes}m ago';
      } else if (difference.inDays < 1) {
        return '${difference.inHours}h ago';
      } else {
        return DateFormat('MMM d, HH:mm').format(dateTime);
      }
    } catch (e) {
      return timestamp;
    }
  }
}