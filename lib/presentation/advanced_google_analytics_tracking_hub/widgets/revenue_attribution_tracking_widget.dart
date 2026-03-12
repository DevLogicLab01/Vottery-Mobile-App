import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../../theme/app_theme.dart';

class RevenueAttributionTrackingWidget extends StatelessWidget {
  const RevenueAttributionTrackingWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.all(4.w),
      children: [
        Text(
          'Revenue Attribution Tracking',
          style: GoogleFonts.inter(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimaryLight,
          ),
        ),
        SizedBox(height: 2.h),
        _buildSourceCard('election_fees', 45230.50, Colors.blue),
        _buildSourceCard('subscriptions', 32450.00, Colors.purple),
        _buildSourceCard('partnerships', 28750.25, Colors.green),
        _buildSourceCard('ads', 19000.00, Colors.orange),
      ],
    );
  }

  Widget _buildSourceCard(String source, double revenue, Color color) {
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
          Text(
            source.replaceAll('_', ' ').toUpperCase(),
            style: GoogleFonts.inter(fontSize: 12.sp),
          ),
          Text(
            '\$${revenue.toStringAsFixed(2)}',
            style: GoogleFonts.inter(
              fontSize: 13.sp,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
