import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../../theme/app_theme.dart';

class SuspensionListWidget extends StatelessWidget {
  final List<Map<String, dynamic>> suspensions;
  final Function(String) onLift;

  const SuspensionListWidget({
    required this.suspensions,
    required this.onLift,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: EdgeInsets.all(4.w),
      itemCount: suspensions.length,
      itemBuilder: (context, index) {
        final suspension = suspensions[index];
        final userEmail = suspension['user_profiles']?['email'] ?? 'Unknown';
        final reason =
            suspension['suspension_reason'] as String? ?? 'No reason';
        final status = suspension['status'] as String? ?? 'active';
        final expiresAt = suspension['expires_at'] != null
            ? DateTime.parse(suspension['expires_at'])
            : null;

        return Container(
          margin: EdgeInsets.only(bottom: 2.h),
          padding: EdgeInsets.all(4.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12.0),
            border: Border.all(color: Colors.red.shade300),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.block, color: Colors.red, size: 16.sp),
                  SizedBox(width: 2.w),
                  Expanded(
                    child: Text(
                      userEmail,
                      style: GoogleFonts.inter(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimaryLight,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 2.w,
                      vertical: 0.5.h,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(status),
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                    child: Text(
                      status.toUpperCase(),
                      style: GoogleFonts.inter(
                        fontSize: 9.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 1.h),
              Text(
                'Reason: $reason',
                style: GoogleFonts.inter(
                  fontSize: 11.sp,
                  color: AppTheme.textSecondaryLight,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (expiresAt != null) ...[
                SizedBox(height: 0.5.h),
                Text(
                  'Expires: ${expiresAt.toString().substring(0, 10)}',
                  style: GoogleFonts.inter(fontSize: 10.sp, color: Colors.grey),
                ),
              ],
              SizedBox(height: 1.h),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => onLift(suspension['suspension_id']),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryLight,
                    padding: EdgeInsets.symmetric(vertical: 1.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  child: Text(
                    'Lift Suspension',
                    style: GoogleFonts.inter(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'active':
        return Colors.red;
      case 'appealed':
        return Colors.orange;
      case 'lifted':
        return Colors.green;
      case 'permanent':
        return Colors.black;
      default:
        return Colors.grey;
    }
  }
}
