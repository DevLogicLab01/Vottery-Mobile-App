import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import '../../../theme/app_theme.dart';

class ResponseActionCardWidget extends StatelessWidget {
  final String actionName;
  final String description;
  final String status;
  final String? timestamp;
  final String? details;
  final VoidCallback? onRollback;

  const ResponseActionCardWidget({
    super.key,
    required this.actionName,
    required this.description,
    required this.status,
    this.timestamp,
    this.details,
    this.onRollback,
  });

  Color get _statusColor {
    switch (status) {
      case 'success':
        return Colors.green;
      case 'executing':
        return Colors.orange;
      case 'failed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData get _statusIcon {
    switch (status) {
      case 'success':
        return Icons.check_circle;
      case 'executing':
        return Icons.sync;
      case 'failed':
        return Icons.error;
      default:
        return Icons.pending;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 1.5.h),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_statusIcon, color: _statusColor, size: 5.w),
              SizedBox(width: 2.w),
              Expanded(
                child: Text(
                  actionName,
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimaryLight,
                  ),
                ),
              ),
              if (onRollback != null)
                TextButton(
                  onPressed: onRollback,
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 2.w),
                  ),
                  child: Text(
                    'Rollback',
                    style: GoogleFonts.inter(
                      fontSize: 10.sp,
                      color: Colors.orange,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 0.5.h),
          Text(
            description,
            style: GoogleFonts.inter(
              fontSize: 11.sp,
              color: AppTheme.textSecondaryLight,
            ),
          ),
          if (details != null) ...[
            SizedBox(height: 0.5.h),
            Container(
              padding: EdgeInsets.all(2.w),
              decoration: BoxDecoration(
                color: Colors.grey.withAlpha(20),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Text(
                details!,
                style: GoogleFonts.inter(
                  fontSize: 10.sp,
                  color: AppTheme.textSecondaryLight,
                ),
              ),
            ),
          ],
          if (timestamp != null) ...[
            SizedBox(height: 0.5.h),
            Text(
              timestamp!,
              style: GoogleFonts.inter(
                fontSize: 9.sp,
                color: AppTheme.textSecondaryLight,
              ),
            ),
          ],
        ],
      ),
    );
  }
}