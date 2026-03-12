import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import '../../../theme/app_theme.dart';

class WebhookEventCardWidget extends StatelessWidget {
  final String eventType;
  final String status;
  final String? payoutId;
  final String? amount;
  final String? failureReason;
  final String timestamp;

  const WebhookEventCardWidget({
    super.key,
    required this.eventType,
    required this.status,
    this.payoutId,
    this.amount,
    this.failureReason,
    required this.timestamp,
  });

  Color get _statusColor {
    switch (status) {
      case 'processed':
        return Colors.green;
      case 'failed':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData get _eventIcon {
    switch (eventType) {
      case 'account.updated':
        return Icons.account_circle;
      case 'payout.created':
        return Icons.add_circle;
      case 'payout.paid':
        return Icons.check_circle;
      case 'payout.failed':
        return Icons.error;
      default:
        return Icons.webhook;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 1.h),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(color: _statusColor.withAlpha(60)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(2.w),
            decoration: BoxDecoration(
              color: _statusColor.withAlpha(20),
              shape: BoxShape.circle,
            ),
            child: Icon(_eventIcon, color: _statusColor, size: 5.w),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  eventType,
                  style: GoogleFonts.inter(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimaryLight,
                  ),
                ),
                if (payoutId != null)
                  Text(
                    'Payout: ${payoutId!.substring(0, 12)}...',
                    style: GoogleFonts.inter(
                      fontSize: 10.sp,
                      color: AppTheme.textSecondaryLight,
                    ),
                  ),
                if (amount != null)
                  Text(
                    'Amount: \$$amount',
                    style: GoogleFonts.inter(
                      fontSize: 10.sp,
                      color: Colors.green,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                if (failureReason != null)
                  Text(
                    'Reason: $failureReason',
                    style: GoogleFonts.inter(
                      fontSize: 10.sp,
                      color: Colors.red,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                Text(
                  timestamp,
                  style: GoogleFonts.inter(
                    fontSize: 9.sp,
                    color: AppTheme.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
            decoration: BoxDecoration(
              color: _statusColor,
              borderRadius: BorderRadius.circular(6.0),
            ),
            child: Text(
              status.toUpperCase(),
              style: GoogleFonts.inter(
                fontSize: 8.sp,
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
