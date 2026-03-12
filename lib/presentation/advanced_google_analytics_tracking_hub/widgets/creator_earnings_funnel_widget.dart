import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../../theme/app_theme.dart';

class CreatorEarningsFunnelWidget extends StatelessWidget {
  const CreatorEarningsFunnelWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.all(4.w),
      children: [
        Text(
          'Creator Earnings Funnel',
          style: GoogleFonts.inter(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimaryLight,
          ),
        ),
        SizedBox(height: 2.h),
        _buildEventCard('earnings_widget_opened', 1247),
        _buildEventCard('withdrawal_initiated', 856),
        _buildEventCard('withdrawal_completed', 743),
        _buildEventCard('withdrawal_failed', 113),
      ],
    );
  }

  Widget _buildEventCard(String event, int count) {
    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(event, style: GoogleFonts.inter(fontSize: 12.sp)),
          Text(
            count.toString(),
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryLight,
            ),
          ),
        ],
      ),
    );
  }
}
