import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class AIServiceHealthCardWidget extends StatelessWidget {
  final String serviceName;
  final Map<String, dynamic> health;

  const AIServiceHealthCardWidget({
    super.key,
    required this.serviceName,
    required this.health,
  });

  @override
  Widget build(BuildContext context) {
    final status = health['status'] as String? ?? 'unknown';
    final latency = health['latency'] as int? ?? 0;
    final lastCheck = health['last_check'] as String?;

    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (status) {
      case 'healthy':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        statusText = 'Healthy';
        break;
      case 'unhealthy':
        statusColor = Colors.red;
        statusIcon = Icons.error;
        statusText = 'Unhealthy';
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help;
        statusText = 'Unknown';
    }

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(statusIcon, color: statusColor, size: 6.w),
              SizedBox(width: 3.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      serviceName,
                      style: GoogleFonts.inter(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimaryLight,
                      ),
                    ),
                    Text(
                      statusText,
                      style: GoogleFonts.inter(
                        fontSize: 12.sp,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
              if (status == 'healthy')
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 2.w,
                    vertical: 0.5.h,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withAlpha(26),
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: Text(
                    '${latency}ms',
                    style: GoogleFonts.inter(
                      fontSize: 11.sp,
                      color: Colors.green,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          if (status == 'unhealthy' && health['error'] != null) ...[
            SizedBox(height: 2.h),
            Container(
              padding: EdgeInsets.all(2.w),
              decoration: BoxDecoration(
                color: Colors.red.withAlpha(13),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Text(
                health['error'] as String,
                style: GoogleFonts.inter(fontSize: 11.sp, color: Colors.red),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
          if (lastCheck != null) ...[
            SizedBox(height: 1.h),
            Text(
              'Last checked: ${_formatTime(lastCheck)}',
              style: GoogleFonts.inter(
                fontSize: 10.sp,
                color: AppTheme.textSecondaryLight,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatTime(String isoString) {
    try {
      final dateTime = DateTime.parse(isoString);
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inSeconds < 60) {
        return '${difference.inSeconds}s ago';
      } else if (difference.inMinutes < 60) {
        return '${difference.inMinutes}m ago';
      } else {
        return '${difference.inHours}h ago';
      }
    } catch (e) {
      return 'Unknown';
    }
  }
}
