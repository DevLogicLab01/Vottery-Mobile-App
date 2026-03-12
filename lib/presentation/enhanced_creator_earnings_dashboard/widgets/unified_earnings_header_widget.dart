import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class UnifiedEarningsHeaderWidget extends StatelessWidget {
  final Map<String, dynamic> earningsSummary;
  final Map<String, dynamic> marketplaceAnalytics;

  const UnifiedEarningsHeaderWidget({
    super.key,
    required this.earningsSummary,
    required this.marketplaceAnalytics,
  });

  @override
  Widget build(BuildContext context) {
    final totalEarnings =
        (earningsSummary['total_usd_earned'] ?? 0.0) +
        (marketplaceAnalytics['total_revenue'] ?? 0.0);
    final availableBalance = earningsSummary['available_balance_usd'] ?? 0.0;
    final marketplaceRevenue = marketplaceAnalytics['total_revenue'] ?? 0.0;
    final electionRevenue = earningsSummary['total_usd_earned'] ?? 0.0;

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryLight, AppTheme.primaryLight.withAlpha(179)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Total Earnings',
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.white.withAlpha(204),
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            '\$${totalEarnings.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 28.sp,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            'Available: \$${availableBalance.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 13.sp,
              color: Colors.white.withAlpha(204),
            ),
          ),
          SizedBox(height: 3.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildRevenueSource(
                'Elections',
                electionRevenue,
                Icons.how_to_vote,
              ),
              _buildRevenueSource(
                'Marketplace',
                marketplaceRevenue,
                Icons.store,
              ),
              _buildRevenueSource('Partnerships', 0.0, Icons.handshake),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueSource(String label, double amount, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 6.w),
        SizedBox(height: 0.5.h),
        Text(
          '\$${amount.toStringAsFixed(0)}',
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 11.sp, color: Colors.white.withAlpha(204)),
        ),
      ],
    );
  }
}
