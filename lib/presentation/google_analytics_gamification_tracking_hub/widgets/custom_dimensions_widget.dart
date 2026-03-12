import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

class CustomDimensionsWidget extends StatelessWidget {
  final Map<String, dynamic> trackingData;

  const CustomDimensionsWidget({super.key, required this.trackingData});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Custom Dimensions',
            style: GoogleFonts.inter(
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            'GA4 custom dimensions for gamification tracking',
            style: GoogleFonts.inter(fontSize: 12.sp, color: Colors.grey[600]),
          ),
          SizedBox(height: 2.h),
          _buildDimensionCard(
            'user_level',
            'User Level',
            'Current gamification level (1-10)',
            '7',
            Icons.trending_up,
            Colors.blue,
            theme,
          ),
          SizedBox(height: 2.h),
          _buildDimensionCard(
            'current_vp_balance',
            'Current VP Balance',
            'User\'s current Vottery Points balance',
            '2,450 VP',
            Icons.account_balance_wallet,
            Colors.green,
            theme,
          ),
          SizedBox(height: 2.h),
          _buildDimensionCard(
            'total_badges_earned',
            'Total Badges Earned',
            'Cumulative badges unlocked by user',
            '12 badges',
            Icons.stars,
            Colors.orange,
            theme,
          ),
        ],
      ),
    );
  }

  Widget _buildDimensionCard(
    String dimensionKey,
    String title,
    String description,
    String currentValue,
    IconData icon,
    Color color,
    ThemeData theme,
  ) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: color, width: 2.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 10.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(2.w),
                decoration: BoxDecoration(
                  color: color.withAlpha(51),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 24.sp),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      dimensionKey,
                      style: GoogleFonts.inter(
                        fontSize: 10.sp,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Text(
                  currentValue,
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Text(
            description,
            style: GoogleFonts.inter(fontSize: 12.sp, color: Colors.grey[700]),
          ),
        ],
      ),
    );
  }
}
