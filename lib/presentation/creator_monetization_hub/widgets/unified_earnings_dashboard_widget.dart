import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class UnifiedEarningsDashboardWidget extends StatelessWidget {
  final Map<String, dynamic> earningsSummary;
  final Map<String, dynamic> revenueBreakdown;
  final Map<String, dynamic> revenueSplit;

  const UnifiedEarningsDashboardWidget({
    super.key,
    required this.earningsSummary,
    required this.revenueBreakdown,
    required this.revenueSplit,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      symbol: r'$',
      decimalDigits: 2,
    );

    return SingleChildScrollView(
      padding: EdgeInsets.all(2.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Revenue Streams',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          SizedBox(height: 2.h),
          _buildRevenueStreamCard(
            'Election Monetization',
            revenueBreakdown['election_revenue'] ?? 0.0,
            Icons.how_to_vote,
            Colors.blue,
            currencyFormat,
          ),
          SizedBox(height: 1.h),
          _buildRevenueStreamCard(
            'Creator Marketplace',
            revenueBreakdown['marketplace_revenue'] ?? 0.0,
            Icons.store,
            Colors.purple,
            currencyFormat,
          ),
          SizedBox(height: 1.h),
          _buildRevenueStreamCard(
            'Participatory Ads',
            revenueBreakdown['ads_revenue'] ?? 0.0,
            Icons.ad_units,
            Colors.orange,
            currencyFormat,
          ),
          SizedBox(height: 1.h),
          _buildRevenueStreamCard(
            'Tips & Donations',
            revenueBreakdown['tips_revenue'] ?? 0.0,
            Icons.volunteer_activism,
            Colors.green,
            currencyFormat,
          ),
          SizedBox(height: 1.h),
          _buildRevenueStreamCard(
            'Subscriptions',
            revenueBreakdown['subscription_revenue'] ?? 0.0,
            Icons.subscriptions,
            Colors.red,
            currencyFormat,
          ),
          SizedBox(height: 3.h),
          Text(
            'Revenue Split',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          SizedBox(height: 2.h),
          _buildRevenueSplitCard(),
        ],
      ),
    );
  }

  Widget _buildRevenueStreamCard(
    String title,
    dynamic amount,
    IconData icon,
    Color color,
    NumberFormat format,
  ) {
    final amountValue = (amount as num).toDouble();
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: color.withAlpha(77)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(2.w),
            decoration: BoxDecoration(
              color: color.withAlpha(26),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Icon(icon, color: color, size: 6.w),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: AppTheme.textSecondaryLight,
                  ),
                ),
                SizedBox(height: 0.5.h),
                Text(
                  format.format(amountValue),
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryLight,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.trending_up, color: Colors.green, size: 5.w),
        ],
      ),
    );
  }

  Widget _buildRevenueSplitCard() {
    final creatorPercentage =
        (revenueSplit['creator_percentage'] ?? 70.0) as num;
    final platformPercentage =
        (revenueSplit['platform_percentage'] ?? 30.0) as num;
    final isGrandfathered = revenueSplit['is_grandfathered'] ?? false;

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Current Split',
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimaryLight,
                ),
              ),
              if (isGrandfathered)
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 2.w,
                    vertical: 0.5.h,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: Text(
                    'Grandfathered',
                    style: TextStyle(
                      fontSize: 9.sp,
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              Expanded(
                flex: creatorPercentage.toInt(),
                child: Container(
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.horizontal(
                      left: Radius.circular(8.0),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'You: ${creatorPercentage.toInt()}%',
                    style: TextStyle(
                      fontSize: 10.sp,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: platformPercentage.toInt(),
                child: Container(
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.horizontal(
                      right: Radius.circular(8.0),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'Platform: ${platformPercentage.toInt()}%',
                    style: TextStyle(
                      fontSize: 10.sp,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
