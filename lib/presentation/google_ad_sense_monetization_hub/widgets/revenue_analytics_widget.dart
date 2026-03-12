import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class RevenueAnalyticsWidget extends StatelessWidget {
  final Map<String, dynamic> revenueData;
  final VoidCallback onRefresh;

  const RevenueAnalyticsWidget({
    super.key,
    required this.revenueData,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: SingleChildScrollView(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildRevenueBreakdown(),
            SizedBox(height: 2.h),
            _buildRevenueChart(),
            SizedBox(height: 2.h),
            _buildAdTypeRevenue(),
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueBreakdown() {
    final dailyRevenue = revenueData['daily_revenue'] ?? 0.0;
    final weeklyRevenue = revenueData['weekly_revenue'] ?? 0.0;
    final monthlyRevenue = revenueData['monthly_revenue'] ?? 0.0;

    return Card(
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Revenue Breakdown',
              style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 2.h),
            _buildRevenueRow('Daily', dailyRevenue, Colors.blue),
            SizedBox(height: 1.h),
            _buildRevenueRow('Weekly', weeklyRevenue, Colors.green),
            SizedBox(height: 1.h),
            _buildRevenueRow('Monthly', monthlyRevenue, Colors.orange),
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueRow(String label, double amount, Color color) {
    return Row(
      children: [
        Container(
          width: 4.w,
          height: 4.w,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        SizedBox(width: 2.w),
        Expanded(
          child: Text(label, style: TextStyle(fontSize: 13.sp)),
        ),
        Text(
          '\$${amount.toStringAsFixed(2)}',
          style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildRevenueChart() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Revenue Trend (Last 7 Days)',
              style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 2.h),
            SizedBox(
              height: 25.h,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: true),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '\$${value.toInt()}',
                            style: TextStyle(fontSize: 10.sp),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            'Day ${value.toInt()}',
                            style: TextStyle(fontSize: 10.sp),
                          );
                        },
                      ),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: _generateMockData(),
                      isCurved: true,
                      color: Colors.green,
                      barWidth: 3,
                      dotData: const FlDotData(show: true),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdTypeRevenue() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Revenue by Ad Type',
              style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 2.h),
            _buildAdTypeRow('Banner Ads', 45.50, Colors.blue),
            SizedBox(height: 1.h),
            _buildAdTypeRow('Interstitial Ads', 32.75, Colors.orange),
            SizedBox(height: 1.h),
            _buildAdTypeRow('Rewarded Ads', 28.90, Colors.purple),
            SizedBox(height: 1.h),
            _buildAdTypeRow('Native Ads', 18.25, Colors.green),
          ],
        ),
      ),
    );
  }

  Widget _buildAdTypeRow(String label, double amount, Color color) {
    return Row(
      children: [
        Icon(Icons.circle, color: color, size: 12.sp),
        SizedBox(width: 2.w),
        Expanded(
          child: Text(label, style: TextStyle(fontSize: 13.sp)),
        ),
        Text(
          '\$${amount.toStringAsFixed(2)}',
          style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  List<FlSpot> _generateMockData() {
    return [
      const FlSpot(1, 15),
      const FlSpot(2, 22),
      const FlSpot(3, 18),
      const FlSpot(4, 28),
      const FlSpot(5, 25),
      const FlSpot(6, 32),
      const FlSpot(7, 35),
    ];
  }
}
