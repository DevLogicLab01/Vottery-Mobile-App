import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class MarketplaceRevenueWidget extends StatelessWidget {
  final Map<String, dynamic> marketplaceAnalytics;

  const MarketplaceRevenueWidget({
    super.key,
    required this.marketplaceAnalytics,
  });

  @override
  Widget build(BuildContext context) {
    final totalRevenue = marketplaceAnalytics['total_revenue'] ?? 0.0;
    final totalTransactions = marketplaceAnalytics['total_transactions'] ?? 0;
    final avgOrderValue = marketplaceAnalytics['average_order_value'] ?? 0.0;

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Marketplace Revenue',
                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
              ),
              Icon(Icons.store, color: AppTheme.primaryLight, size: 6.w),
            ],
          ),
          SizedBox(height: 2.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMetric(
                'Total Revenue',
                '\$${totalRevenue.toStringAsFixed(2)}',
              ),
              _buildMetric('Transactions', totalTransactions.toString()),
              _buildMetric(
                'Avg Order',
                '\$${avgOrderValue.toStringAsFixed(2)}',
              ),
            ],
          ),
          SizedBox(height: 2.h),
          _buildServiceBreakdown(),
        ],
      ),
    );
  }

  Widget _buildMetric(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w700,
            color: AppTheme.primaryLight,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 11.sp, color: AppTheme.textSecondaryLight),
        ),
      ],
    );
  }

  Widget _buildServiceBreakdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'By Service Type',
          style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600),
        ),
        SizedBox(height: 1.h),
        _buildServiceItem('Consultation', 450.0, 0.45),
        SizedBox(height: 0.5.h),
        _buildServiceItem('Sponsored Content', 350.0, 0.35),
        SizedBox(height: 0.5.h),
        _buildServiceItem('Exclusive Access', 200.0, 0.20),
      ],
    );
  }

  Widget _buildServiceItem(String name, double amount, double percentage) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Text(name, style: TextStyle(fontSize: 12.sp)),
        ),
        Expanded(
          flex: 2,
          child: LinearProgressIndicator(
            value: percentage,
            backgroundColor: Colors.grey.withAlpha(51),
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryLight),
          ),
        ),
        SizedBox(width: 2.w),
        Text(
          '\$${amount.toStringAsFixed(0)}',
          style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
