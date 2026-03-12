import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class RateLimitingDashboardWidget extends StatelessWidget {
  const RateLimitingDashboardWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.all(3.w),
      children: [
        Text(
          'Rate Limiting Configuration',
          style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 2.h),
        Card(
          elevation: 2.0,
          child: Padding(
            padding: EdgeInsets.all(3.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Global Rate Limits',
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 1.h),
                _buildRateLimitRow('Requests per minute', '100'),
                _buildRateLimitRow('Requests per hour', '5,000'),
                _buildRateLimitRow('Requests per day', '100,000'),
                SizedBox(height: 2.h),
                Text(
                  'Per-Client Quotas',
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 1.h),
                _buildRateLimitRow('Free Tier', '1,000/day'),
                _buildRateLimitRow('Pro Tier', '50,000/day'),
                _buildRateLimitRow('Enterprise', 'Unlimited'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRateLimitRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 0.5.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 11.sp)),
          Text(
            value,
            style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
