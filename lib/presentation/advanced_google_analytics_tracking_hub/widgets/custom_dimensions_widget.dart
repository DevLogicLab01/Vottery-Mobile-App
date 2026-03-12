import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../../theme/app_theme.dart';

class CustomDimensionsWidget extends StatelessWidget {
  const CustomDimensionsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final dimensions = [
      {'name': 'creator_tier', 'value': 'Gold', 'users': 1247},
      {'name': 'subscription_status', 'value': 'Premium', 'users': 856},
      {'name': 'kyc_status', 'value': 'Approved', 'users': 2145},
      {'name': 'primary_zone', 'value': 'US_Canada', 'users': 3421},
      {'name': 'creator_age_days', 'value': '90+', 'users': 1876},
    ];

    return ListView(
      padding: EdgeInsets.all(4.w),
      children: [
        Text(
          'Custom Dimensions Tracking',
          style: GoogleFonts.inter(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimaryLight,
          ),
        ),
        SizedBox(height: 2.h),
        ...dimensions.map(
          (dim) => Container(
            margin: EdgeInsets.only(bottom: 2.h),
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dim['name'].toString(),
                      style: GoogleFonts.inter(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      dim['value'].toString(),
                      style: GoogleFonts.inter(
                        fontSize: 10.sp,
                        color: AppTheme.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
                Text(
                  '${dim['users']} users',
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    color: AppTheme.primaryLight,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
