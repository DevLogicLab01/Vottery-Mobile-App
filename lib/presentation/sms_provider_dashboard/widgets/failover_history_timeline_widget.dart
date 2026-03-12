import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:timeago/timeago.dart' as timeago;

class FailoverHistoryTimelineWidget extends StatelessWidget {
  final List<Map<String, dynamic>> history;

  const FailoverHistoryTimelineWidget({super.key, required this.history});

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 48.sp, color: Colors.grey),
            SizedBox(height: 2.h),
            Text(
              'No failover events',
              style: TextStyle(fontSize: 14.sp, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Failover History',
          style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
        ),
        SizedBox(height: 2.h),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: history.length,
          itemBuilder: (context, index) {
            final event = history[index];
            return _buildTimelineItem(event, index == history.length - 1);
          },
        ),
      ],
    );
  }

  Widget _buildTimelineItem(Map<String, dynamic> event, bool isLast) {
    final fromProvider = event['from_provider'] ?? 'unknown';
    final toProvider = event['to_provider'] ?? 'unknown';
    final reason = event['failover_reason'] ?? 'No reason provided';
    final triggeredBy = event['triggered_by'] ?? 'automatic';
    final failedAt = event['failed_at'] != null
        ? DateTime.parse(event['failed_at'])
        : DateTime.now();
    final restoredAt = event['restored_at'] != null
        ? DateTime.parse(event['restored_at'])
        : null;
    final duration = event['duration_seconds'];

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline indicator
          Column(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: triggeredBy == 'automatic'
                      ? Colors.orange
                      : Colors.blue,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(width: 2, color: Colors.grey.shade300),
                ),
            ],
          ),
          SizedBox(width: 3.w),

          // Event card
          Expanded(
            child: Container(
              margin: EdgeInsets.only(bottom: 2.h),
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12.0),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '$fromProvider → $toProvider',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 2.w,
                          vertical: 0.5.h,
                        ),
                        decoration: BoxDecoration(
                          color: triggeredBy == 'automatic'
                              ? Colors.orange.withAlpha(26)
                              : Colors.blue.withAlpha(26),
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        child: Text(
                          triggeredBy.toUpperCase(),
                          style: TextStyle(
                            fontSize: 9.sp,
                            color: triggeredBy == 'automatic'
                                ? Colors.orange
                                : Colors.blue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 1.h),
                  Text(
                    reason,
                    style: TextStyle(fontSize: 11.sp, color: Colors.grey[700]),
                  ),
                  SizedBox(height: 1.h),
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 12.sp, color: Colors.grey),
                      SizedBox(width: 1.w),
                      Text(
                        timeago.format(failedAt),
                        style: TextStyle(fontSize: 10.sp, color: Colors.grey),
                      ),
                      if (duration != null) ...[
                        SizedBox(width: 3.w),
                        Icon(Icons.timer, size: 12.sp, color: Colors.grey),
                        SizedBox(width: 1.w),
                        Text(
                          '${duration}s',
                          style: TextStyle(fontSize: 10.sp, color: Colors.grey),
                        ),
                      ],
                      if (restoredAt != null) ...[
                        SizedBox(width: 3.w),
                        Icon(
                          Icons.check_circle,
                          size: 12.sp,
                          color: Colors.green,
                        ),
                        SizedBox(width: 1.w),
                        Text(
                          'Restored',
                          style: TextStyle(
                            fontSize: 10.sp,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
