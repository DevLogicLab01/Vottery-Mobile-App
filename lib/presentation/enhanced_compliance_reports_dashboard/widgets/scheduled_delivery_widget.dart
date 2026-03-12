import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:timeago/timeago.dart' as timeago;

class ScheduledDeliveryWidget extends StatelessWidget {
  final List<Map<String, dynamic>> scheduledDeliveries;
  final VoidCallback onRefresh;

  const ScheduledDeliveryWidget({
    super.key,
    required this.scheduledDeliveries,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Scheduled Compliance Deliveries',
          style: GoogleFonts.inter(
            fontSize: 14.sp,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        SizedBox(height: 1.h),
        Text(
          'Automated monthly/quarterly compliance reports sent to regulatory bodies via encrypted email',
          style: GoogleFonts.inter(
            fontSize: 11.sp,
            color: theme.colorScheme.onSurface.withAlpha(153),
          ),
        ),
        SizedBox(height: 2.h),
        if (scheduledDeliveries.isEmpty)
          Center(
            child: Column(
              children: [
                SizedBox(height: 5.h),
                Icon(
                  Icons.schedule_send,
                  size: 64,
                  color: theme.colorScheme.onSurface.withAlpha(77),
                ),
                SizedBox(height: 2.h),
                Text(
                  'No scheduled deliveries',
                  style: GoogleFonts.inter(
                    fontSize: 13.sp,
                    color: theme.colorScheme.onSurface.withAlpha(153),
                  ),
                ),
              ],
            ),
          )
        else
          ...scheduledDeliveries.map(
            (delivery) => _buildDeliveryCard(context, delivery),
          ),
      ],
    );
  }

  Widget _buildDeliveryCard(
    BuildContext context,
    Map<String, dynamic> delivery,
  ) {
    final theme = Theme.of(context);
    final jurisdiction = delivery['jurisdiction'] as String? ?? 'Unknown';
    final reportType = delivery['report_type'] as String? ?? 'Unknown';
    final frequency = delivery['schedule_frequency'] as String? ?? 'Unknown';
    final recipientEmail = delivery['recipient_email'] as String? ?? 'Unknown';
    final nextScheduledAt = delivery['next_scheduled_at'] as String?;
    final lastSentAt = delivery['last_sent_at'] as String?;
    final isActive = delivery['is_active'] as bool? ?? false;

    return Card(
      margin: EdgeInsets.only(bottom: 2.h),
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$jurisdiction - ${reportType.replaceAll('_', ' ').toUpperCase()}',
                        style: GoogleFonts.inter(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      SizedBox(height: 0.5.h),
                      Text(
                        frequency.toUpperCase(),
                        style: GoogleFonts.inter(
                          fontSize: 11.sp,
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 2.w,
                    vertical: 0.5.h,
                  ),
                  decoration: BoxDecoration(
                    color: isActive
                        ? Colors.green.withAlpha(26)
                        : Colors.grey.withAlpha(26),
                    borderRadius: BorderRadius.circular(4.0),
                  ),
                  child: Text(
                    isActive ? 'ACTIVE' : 'INACTIVE',
                    style: GoogleFonts.inter(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w600,
                      color: isActive ? Colors.green : Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 2.h),
            Row(
              children: [
                Icon(
                  Icons.email,
                  size: 16,
                  color: theme.colorScheme.onSurface.withAlpha(153),
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: Text(
                    recipientEmail,
                    style: GoogleFonts.inter(
                      fontSize: 11.sp,
                      color: theme.colorScheme.onSurface.withAlpha(179),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 1.h),
            Row(
              children: [
                Icon(
                  Icons.schedule,
                  size: 16,
                  color: theme.colorScheme.onSurface.withAlpha(153),
                ),
                SizedBox(width: 2.w),
                Text(
                  'Next: ${nextScheduledAt != null ? timeago.format(DateTime.parse(nextScheduledAt)) : 'Not scheduled'}',
                  style: GoogleFonts.inter(
                    fontSize: 11.sp,
                    color: theme.colorScheme.onSurface.withAlpha(179),
                  ),
                ),
              ],
            ),
            if (lastSentAt != null) ...[
              SizedBox(height: 1.h),
              Row(
                children: [
                  Icon(Icons.check_circle, size: 16, color: Colors.green),
                  SizedBox(width: 2.w),
                  Text(
                    'Last sent: ${timeago.format(DateTime.parse(lastSentAt))}',
                    style: GoogleFonts.inter(
                      fontSize: 11.sp,
                      color: theme.colorScheme.onSurface.withAlpha(179),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
