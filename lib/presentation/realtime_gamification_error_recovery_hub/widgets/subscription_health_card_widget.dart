import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

class SubscriptionHealthCardWidget extends StatelessWidget {
  final String subscriptionName;
  final String status;
  final int retryCount;
  final String lastEvent;
  final VoidCallback? onRetry;

  const SubscriptionHealthCardWidget({
    super.key,
    required this.subscriptionName,
    required this.status,
    required this.retryCount,
    required this.lastEvent,
    this.onRetry,
  });

  Color get _statusColor {
    switch (status) {
      case 'connected':
        return Colors.green;
      case 'error':
        return Colors.red;
      case 'reconnecting':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData get _statusIcon {
    switch (status) {
      case 'connected':
        return Icons.check_circle;
      case 'error':
        return Icons.error;
      case 'reconnecting':
        return Icons.refresh;
      default:
        return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
        side: BorderSide(color: _statusColor.withAlpha(77), width: 1),
      ),
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _statusColor.withAlpha(26),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Icon(_statusIcon, color: _statusColor, size: 20),
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    subscriptionName,
                    style: GoogleFonts.inter(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 0.3.h),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _statusColor.withAlpha(26),
                          borderRadius: BorderRadius.circular(4.0),
                        ),
                        child: Text(
                          status.toUpperCase(),
                          style: GoogleFonts.inter(
                            fontSize: 9.sp,
                            fontWeight: FontWeight.w700,
                            color: _statusColor,
                          ),
                        ),
                      ),
                      SizedBox(width: 2.w),
                      Text(
                        'Retries: $retryCount',
                        style: GoogleFonts.inter(
                          fontSize: 10.sp,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 0.3.h),
                  Text(
                    'Last: $lastEvent',
                    style: GoogleFonts.inter(
                      fontSize: 10.sp,
                      color: Colors.grey[500],
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (status == 'error' && onRetry != null)
              IconButton(
                icon: const Icon(Icons.refresh, size: 18),
                onPressed: onRetry,
                tooltip: 'Retry',
              ),
          ],
        ),
      ),
    );
  }
}
