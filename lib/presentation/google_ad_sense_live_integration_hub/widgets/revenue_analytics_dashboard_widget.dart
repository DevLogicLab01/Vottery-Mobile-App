import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:fl_chart/fl_chart.dart';

class RevenueAnalyticsDashboardWidget extends StatelessWidget {
  final Map<String, dynamic> revenueData;
  final VoidCallback onRefresh;

  const RevenueAnalyticsDashboardWidget({
    super.key,
    required this.revenueData,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: SingleChildScrollView(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Revenue Analytics Dashboard',
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 1.h),
            Text(
              'Real-time earnings per screen, ad unit, and impression with CPM/CTR metrics',
              style: TextStyle(fontSize: 12.sp, color: Colors.grey),
            ),
            SizedBox(height: 3.h),
            _buildRevenueOverview(),
            SizedBox(height: 2.h),
            _buildEarningsChart(),
            SizedBox(height: 2.h),
            _buildPerformanceMetrics(),
            SizedBox(height: 2.h),
            _buildGeographicBreakdown(),
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueOverview() {
    final totalRevenue = revenueData['total_revenue'] ?? 0.0;
    final dailyRevenue = revenueData['daily_revenue'] ?? 0.0;
    final weeklyRevenue = revenueData['weekly_revenue'] ?? 0.0;
    final monthlyRevenue = revenueData['monthly_revenue'] ?? 0.0;

    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Revenue Overview',
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 2.h),
            Row(
              children: [
                Expanded(
                  child: _buildRevenueMetric(
                    'Total',
                    '\$${totalRevenue.toStringAsFixed(2)}',
                    Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildRevenueMetric(
                    'Today',
                    '\$${dailyRevenue.toStringAsFixed(2)}',
                    Colors.blue,
                  ),
                ),
              ],
            ),
            SizedBox(height: 2.h),
            Row(
              children: [
                Expanded(
                  child: _buildRevenueMetric(
                    'This Week',
                    '\$${weeklyRevenue.toStringAsFixed(2)}',
                    Colors.orange,
                  ),
                ),
                Expanded(
                  child: _buildRevenueMetric(
                    'This Month',
                    '\$${monthlyRevenue.toStringAsFixed(2)}',
                    Colors.purple,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueMetric(String label, String value, Color color) {
    return Container(
      padding: EdgeInsets.all(2.w),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(height: 0.5.h),
          Text(
            label,
            style: TextStyle(fontSize: 11.sp, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildEarningsChart() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Earnings Trend (Last 7 Days)',
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 2.h),
            SizedBox(
              height: 25.h,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: true),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                      ),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: [
                        const FlSpot(0, 15),
                        const FlSpot(1, 18),
                        const FlSpot(2, 22),
                        const FlSpot(3, 19),
                        const FlSpot(4, 25),
                        const FlSpot(5, 23),
                        const FlSpot(6, 28),
                      ],
                      isCurved: true,
                      color: Colors.green,
                      barWidth: 3,
                      dotData: FlDotData(show: true),
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

  Widget _buildPerformanceMetrics() {
    final totalImpressions = revenueData['total_impressions'] ?? 0;
    final totalClicks = revenueData['total_clicks'] ?? 0;
    final ctr = revenueData['ctr'] ?? 0.0;
    final ecpm = revenueData['ecpm'] ?? 0.0;

    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Performance Metrics',
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 2.h),
            _buildMetricRow('Total Impressions', totalImpressions.toString()),
            Divider(height: 2.h),
            _buildMetricRow('Total Clicks', totalClicks.toString()),
            Divider(height: 2.h),
            _buildMetricRow('CTR', '${ctr.toStringAsFixed(2)}%'),
            Divider(height: 2.h),
            _buildMetricRow('eCPM', '\$${ecpm.toStringAsFixed(2)}'),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 12.sp, color: Colors.grey[700]),
        ),
        Text(
          value,
          style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildGeographicBreakdown() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Geographic Performance',
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 2.h),
            _buildGeoRow('United States', '\$125.45', '45%'),
            Divider(height: 2.h),
            _buildGeoRow('United Kingdom', '\$78.32', '28%'),
            Divider(height: 2.h),
            _buildGeoRow('Canada', '\$45.78', '16%'),
            Divider(height: 2.h),
            _buildGeoRow('Other', '\$30.45', '11%'),
          ],
        ),
      ),
    );
  }

  Widget _buildGeoRow(String country, String revenue, String percentage) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(
            country,
            style: TextStyle(fontSize: 12.sp, color: Colors.grey[700]),
          ),
        ),
        Expanded(
          child: Text(
            revenue,
            style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold),
            textAlign: TextAlign.right,
          ),
        ),
        SizedBox(width: 2.w),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
          decoration: BoxDecoration(
            color: Colors.green.withAlpha(26),
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: Text(
            percentage,
            style: TextStyle(fontSize: 10.sp, color: Colors.green),
          ),
        ),
      ],
    );
  }
}
