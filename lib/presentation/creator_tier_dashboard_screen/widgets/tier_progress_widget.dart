import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../../theme/app_theme.dart';

class TierProgressWidget extends StatelessWidget {
  final Map<String, dynamic> progress;

  const TierProgressWidget({required this.progress, super.key});

  @override
  Widget build(BuildContext context) {
    final nextTierName = progress['next_tier_name'] as String? ?? 'Next Tier';
    final earningsProgress =
        (progress['earnings_progress'] as num?)?.toDouble() ?? 0.0;
    final vpProgress = (progress['vp_progress'] as num?)?.toDouble() ?? 0.0;
    final earningsCurrent =
        (progress['earnings_current'] as num?)?.toDouble() ?? 0.0;
    final earningsRequired =
        (progress['earnings_required'] as num?)?.toDouble() ?? 1000.0;
    final vpCurrent = progress['vp_current'] as int? ?? 0;
    final vpRequired = progress['vp_required'] as int? ?? 5000;

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
            'Progress to $nextTierName',
            style: GoogleFonts.inter(
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          SizedBox(height: 2.h),

          // Earnings Progress
          Text(
            'Earnings',
            style: GoogleFonts.inter(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondaryLight,
            ),
          ),
          SizedBox(height: 0.5.h),
          LinearProgressIndicator(
            value: earningsProgress.clamp(0.0, 1.0),
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation(AppTheme.primaryLight),
            minHeight: 1.h,
          ),
          SizedBox(height: 0.5.h),
          Text(
            '\$${earningsCurrent.toStringAsFixed(0)} / \$${earningsRequired.toStringAsFixed(0)} (${(earningsProgress * 100).toStringAsFixed(0)}%)',
            style: GoogleFonts.inter(
              fontSize: 11.sp,
              color: Colors.grey.shade700,
            ),
          ),
          SizedBox(height: 2.h),

          // VP Progress
          Text(
            'Victory Points',
            style: GoogleFonts.inter(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondaryLight,
            ),
          ),
          SizedBox(height: 0.5.h),
          LinearProgressIndicator(
            value: vpProgress.clamp(0.0, 1.0),
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation(AppTheme.vibrantYellow),
            minHeight: 1.h,
          ),
          SizedBox(height: 0.5.h),
          Text(
            '$vpCurrent / $vpRequired VP (${(vpProgress * 100).toStringAsFixed(0)}%)',
            style: GoogleFonts.inter(
              fontSize: 11.sp,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }
}
