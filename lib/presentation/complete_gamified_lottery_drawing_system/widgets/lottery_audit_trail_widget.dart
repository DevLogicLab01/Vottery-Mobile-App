import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import 'package:intl/intl.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class LotteryAuditTrailWidget extends StatelessWidget {
  final List<Map<String, dynamic>> auditTrail;

  const LotteryAuditTrailWidget({super.key, required this.auditTrail});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (auditTrail.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              size: 20.w,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            SizedBox(height: 2.h),
            Text(
              'No audit trail available',
              style: GoogleFonts.inter(
                fontSize: 13.sp,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(4.w),
      itemCount: auditTrail.length,
      itemBuilder: (context, index) {
        final event = auditTrail[index];
        return _buildAuditCard(theme, event, index == auditTrail.length - 1);
      },
    );
  }

  Widget _buildAuditCard(
    ThemeData theme,
    Map<String, dynamic> event,
    bool isLast,
  ) {
    final eventType = event['event_type'] ?? 'unknown';
    final timestamp = event['timestamp'] != null
        ? DateTime.parse(event['timestamp'])
        : DateTime.now();
    final details = event['details'] ?? 'No details';

    IconData eventIcon;
    Color eventColor;

    switch (eventType) {
      case 'lottery_created':
        eventIcon = Icons.add_circle;
        eventColor = Colors.blue;
        break;
      case 'vote_cast':
        eventIcon = Icons.how_to_vote;
        eventColor = Colors.green;
        break;
      case 'winner_selected':
        eventIcon = Icons.emoji_events;
        eventColor = AppTheme.accentLight;
        break;
      case 'prize_distributed':
        eventIcon = Icons.payments;
        eventColor = Colors.purple;
        break;
      default:
        eventIcon = Icons.info;
        eventColor = Colors.grey;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 10.w,
              height: 10.w,
              decoration: BoxDecoration(
                color: eventColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Icon(eventIcon, color: eventColor, size: 5.w),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 8.h,
                color: theme.colorScheme.outline.withValues(alpha: 0.3),
              ),
          ],
        ),
        SizedBox(width: 3.w),
        Expanded(
          child: Container(
            margin: EdgeInsets.only(bottom: 2.h),
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12.0),
              border: Border.all(
                color: theme.colorScheme.outline.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  eventType.replaceAll('_', ' ').toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                    color: eventColor,
                  ),
                ),
                SizedBox(height: 0.5.h),
                Text(
                  details,
                  style: GoogleFonts.inter(
                    fontSize: 11.sp,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                SizedBox(height: 0.5.h),
                Text(
                  DateFormat('MMM dd, yyyy HH:mm:ss').format(timestamp),
                  style: GoogleFonts.inter(
                    fontSize: 10.sp,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
