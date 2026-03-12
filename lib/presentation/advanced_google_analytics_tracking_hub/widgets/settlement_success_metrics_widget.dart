import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../../theme/app_theme.dart';

class SettlementSuccessMetricsWidget extends StatelessWidget {
  const SettlementSuccessMetricsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.all(4.w),
      children: [
        Text(
          'Settlement Success Metrics',
          style: GoogleFonts.inter(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimaryLight,
          ),
        ),
        SizedBox(height: 2.h),
        _buildMetricCard('settlement_requested', 456, Colors.blue),
        _buildMetricCard('settlement_pending', 398, Colors.orange),
        _buildMetricCard('settlement_completed', 367, Colors.green),
        _buildMetricCard('settlement_failed', 31, Colors.red),
      ],
    );
  }

  Widget _buildMetricCard(String event, int count, Color color) {
    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: color.withAlpha(77)),
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
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
