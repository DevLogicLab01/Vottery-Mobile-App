import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class RevenueAnalyticsWidget extends StatelessWidget {
  final Map<String, dynamic> revenueBreakdown;
  final Map<String, dynamic> earningsSummary;

  const RevenueAnalyticsWidget({
    super.key,
    required this.revenueBreakdown,
    required this.earningsSummary,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(2.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Revenue by Source',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          SizedBox(height: 2.h),
          _buildRevenueChart(),
          SizedBox(height: 3.h),
          Text(
            'Time Period Analysis',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          SizedBox(height: 2.h),
          _buildTimePeriodCards(),
        ],
      ),
    );
  }

  Widget _buildRevenueChart() {
    final electionRevenue =
        (revenueBreakdown['election_revenue'] ?? 0.0) as num;
    final marketplaceRevenue =
        (revenueBreakdown['marketplace_revenue'] ?? 0.0) as num;
    final adsRevenue = (revenueBreakdown['ads_revenue'] ?? 0.0) as num;
    final tipsRevenue = (revenueBreakdown['tips_revenue'] ?? 0.0) as num;
    final subscriptionRevenue =
        (revenueBreakdown['subscription_revenue'] ?? 0.0) as num;

    final total =
        electionRevenue +
        marketplaceRevenue +
        adsRevenue +
        tipsRevenue +
        subscriptionRevenue;

    if (total == 0) {
      return Container(
        height: 30.h,
        alignment: Alignment.center,
        child: Text(
          'No revenue data available',
          style: TextStyle(fontSize: 11.sp, color: AppTheme.textSecondaryLight),
        ),
      );
    }

    return Container(
      height: 30.h,
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: PieChart(
        PieChartData(
          sections: [
            PieChartSectionData(
              value: electionRevenue.toDouble(),
              title: '${((electionRevenue / total) * 100).toInt()}%',
              color: Colors.blue,
              radius: 50,
            ),
            PieChartSectionData(
              value: marketplaceRevenue.toDouble(),
              title: '${((marketplaceRevenue / total) * 100).toInt()}%',
              color: Colors.purple,
              radius: 50,
            ),
            PieChartSectionData(
              value: adsRevenue.toDouble(),
              title: '${((adsRevenue / total) * 100).toInt()}%',
              color: Colors.orange,
              radius: 50,
            ),
            PieChartSectionData(
              value: tipsRevenue.toDouble(),
              title: '${((tipsRevenue / total) * 100).toInt()}%',
              color: Colors.green,
              radius: 50,
            ),
            PieChartSectionData(
              value: subscriptionRevenue.toDouble(),
              title: '${((subscriptionRevenue / total) * 100).toInt()}%',
              color: Colors.red,
              radius: 50,
            ),
          ],
          sectionsSpace: 2,
          centerSpaceRadius: 40,
        ),
      ),
    );
  }

  Widget _buildTimePeriodCards() {
    final currencyFormat = NumberFormat.currency(
      symbol: r'$',
      decimalDigits: 2,
    );

    return Column(
      children: [
        _buildPeriodCard('30 Days', 4250.50, 12.5, currencyFormat),
        SizedBox(height: 1.h),
        _buildPeriodCard('60 Days', 8100.30, 8.3, currencyFormat),
        SizedBox(height: 1.h),
        _buildPeriodCard('90 Days', 11500.00, 15.7, currencyFormat),
      ],
    );
  }

  Widget _buildPeriodCard(
    String period,
    double amount,
    double growth,
    NumberFormat format,
  ) {
    final isPositive = growth >= 0;

    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  period,
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: AppTheme.textSecondaryLight,
                  ),
                ),
                SizedBox(height: 0.5.h),
                Text(
                  format.format(amount),
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryLight,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 1.h),
            decoration: BoxDecoration(
              color: isPositive ? Colors.green.shade100 : Colors.red.shade100,
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Row(
              children: [
                Icon(
                  isPositive ? Icons.trending_up : Icons.trending_down,
                  color: isPositive ? Colors.green : Colors.red,
                  size: 4.w,
                ),
                SizedBox(width: 1.w),
                Text(
                  '${growth.abs().toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: isPositive
                        ? Colors.green.shade700
                        : Colors.red.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
