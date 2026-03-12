import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../theme/app_theme.dart';
import '../../../widgets/custom_icon_widget.dart';

/// Revenue Tracking Header Widget - Displays partnership tier status and earnings
class RevenueTrackingHeaderWidget extends StatelessWidget {
  final double totalEarnings;
  final double thisMonthEarnings;
  final int activeCampaigns;

  const RevenueTrackingHeaderWidget({
    super.key,
    required this.totalEarnings,
    required this.thisMonthEarnings,
    required this.activeCampaigns,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryLight, AppTheme.secondaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Partnership Revenue',
            style: GoogleFonts.inter(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  icon: 'attach_money',
                  label: 'Total Earnings',
                  value: '\$${totalEarnings.toStringAsFixed(2)}',
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: _buildStatCard(
                  icon: 'trending_up',
                  label: 'This Month',
                  value: '\$${thisMonthEarnings.toStringAsFixed(2)}',
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: _buildStatCard(
                  icon: 'campaign',
                  label: 'Active',
                  value: activeCampaigns.toString(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(51),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomIconWidget(iconName: icon, size: 5.w, color: Colors.white),
          SizedBox(height: 1.h),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 9.sp,
              color: Colors.white.withAlpha(230),
            ),
          ),
        ],
      ),
    );
  }
}
