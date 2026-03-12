import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../../theme/app_theme.dart';

class TierBenefitsWidget extends StatelessWidget {
  final Map<String, dynamic> tierInfo;

  const TierBenefitsWidget({required this.tierInfo, super.key});

  @override
  Widget build(BuildContext context) {
    final features = tierInfo['features'] as List? ?? [];
    final payoutSchedule = tierInfo['payout_schedule'] as String? ?? 'weekly';
    final minThreshold =
        (tierInfo['minimum_threshold'] as num?)?.toDouble() ?? 50.0;

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
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
          Text(
            'Your Benefits',
            style: GoogleFonts.inter(
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          SizedBox(height: 2.h),
          _buildBenefitRow(
            Icons.schedule,
            'Payout Schedule',
            _formatSchedule(payoutSchedule),
          ),
          _buildBenefitRow(
            Icons.attach_money,
            'Minimum Threshold',
            '\${minThreshold.toStringAsFixed(0)}',
          ),
          if (features.isNotEmpty) ...[
            SizedBox(height: 1.h),
            Divider(),
            SizedBox(height: 1.h),
            Text(
              'Exclusive Features',
              style: GoogleFonts.inter(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondaryLight,
              ),
            ),
            SizedBox(height: 1.h),
            ...features.map(
              (f) => Padding(
                padding: EdgeInsets.only(bottom: 0.5.h),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 14.sp),
                    SizedBox(width: 2.w),
                    Expanded(
                      child: Text(
                        _formatFeature(f.toString()),
                        style: GoogleFonts.inter(fontSize: 11.sp),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBenefitRow(IconData icon, String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 1.h),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primaryLight, size: 16.sp),
          SizedBox(width: 3.w),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12.sp,
                color: AppTheme.textSecondaryLight,
              ),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryLight,
            ),
          ),
        ],
      ),
    );
  }

  String _formatSchedule(String schedule) {
    final schedules = {
      'daily': 'Daily',
      'weekly': 'Weekly',
      'biweekly': 'Bi-weekly',
      'monthly': 'Monthly',
    };
    return schedules[schedule] ?? schedule;
  }

  String _formatFeature(String feature) {
    return feature
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }
}
