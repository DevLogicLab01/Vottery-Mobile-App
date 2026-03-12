import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class UsageAnalyticsWidget extends StatelessWidget {
  final Map<String, dynamic> analytics;
  final List<Map<String, dynamic>> familyMembers;

  const UsageAnalyticsWidget({
    super.key,
    required this.analytics,
    required this.familyMembers,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Usage Analytics',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          SizedBox(height: 2.h),
          _buildOverviewCards(),
          SizedBox(height: 3.h),
          _buildDailyActivityChart(),
          SizedBox(height: 3.h),
          _buildPerMemberBreakdown(),
        ],
      ),
    );
  }

  Widget _buildOverviewCards() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'Total API Calls',
                '${analytics['total_api_calls'] ?? 0}',
                Icons.api,
                Colors.blue,
              ),
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: _buildMetricCard(
                'Storage Used',
                '${(analytics['total_storage_mb'] ?? 0).toStringAsFixed(1)} MB',
                Icons.storage,
                Colors.orange,
              ),
            ),
          ],
        ),
        SizedBox(height: 2.h),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'Active Features',
                '${analytics['active_features_count'] ?? 0}',
                Icons.star,
                Colors.purple,
              ),
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: _buildMetricCard(
                'Usage Time',
                '${((analytics['total_usage_time_minutes'] ?? 0) / 60).toStringAsFixed(1)} hrs',
                Icons.access_time,
                Colors.green,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: color.withAlpha(100)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 6.w, color: color),
          SizedBox(height: 1.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.sp,
              color: AppTheme.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyActivityChart() {
    final detailedAnalytics =
        analytics['detailed_analytics'] as List<Map<String, dynamic>>? ?? [];

    if (detailedAnalytics.isEmpty) {
      return Container(
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Center(
          child: Text(
            'No activity data available',
            style: TextStyle(
              fontSize: 12.sp,
              color: AppTheme.textSecondaryLight,
            ),
          ),
        ),
      );
    }

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Daily Activity (Last 7 Days)',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          SizedBox(height: 2.h),
          SizedBox(
            height: 30.h,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 1,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(color: Colors.grey[300]!, strokeWidth: 1);
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          'Day ${value.toInt()}',
                          style: TextStyle(
                            fontSize: 10.sp,
                            color: AppTheme.textSecondaryLight,
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: TextStyle(
                            fontSize: 10.sp,
                            color: AppTheme.textSecondaryLight,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: 6,
                minY: 0,
                maxY: _getMaxUsageValue(detailedAnalytics),
                lineBarsData: [
                  LineChartBarData(
                    spots: _generateChartSpots(detailedAnalytics),
                    isCurved: true,
                    color: AppTheme.primaryLight,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppTheme.primaryLight.withAlpha(50),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerMemberBreakdown() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Per-Member Breakdown',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          SizedBox(height: 2.h),
          ...familyMembers.map((member) {
            return _buildMemberUsageRow(member);
          }),
        ],
      ),
    );
  }

  Widget _buildMemberUsageRow(Map<String, dynamic> member) {
    final email = member['email'] as String? ?? '';
    final status = member['status'] as String? ?? 'pending';

    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8.w,
                height: 8.w,
                decoration: BoxDecoration(
                  color: AppTheme.primaryLight,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    email.isNotEmpty ? email[0].toUpperCase() : '?',
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: Text(
                  email,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimaryLight,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          if (status == 'active') ...[
            _buildUsageBar('API Calls', 45, Colors.blue),
            _buildUsageBar('Storage', 25, Colors.orange),
            _buildUsageBar('Usage Time', 15, Colors.green),
          ] else
            Text(
              'No usage data ($status)',
              style: TextStyle(
                fontSize: 11.sp,
                color: AppTheme.textSecondaryLight,
                fontStyle: FontStyle.italic,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildUsageBar(String label, int percentage, Color color) {
    return Padding(
      padding: EdgeInsets.only(bottom: 0.5.h),
      child: Row(
        children: [
          SizedBox(
            width: 20.w,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 10.sp,
                color: AppTheme.textSecondaryLight,
              ),
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                Container(
                  height: 1.h,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(4.0),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: percentage / 100,
                  child: Container(
                    height: 1.h,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(4.0),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 2.w),
          Text(
            '$percentage%',
            style: TextStyle(
              fontSize: 10.sp,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryLight,
            ),
          ),
        ],
      ),
    );
  }

  List<FlSpot> _generateChartSpots(List<Map<String, dynamic>> analytics) {
    final spots = <FlSpot>[];
    final last7Days = analytics.take(7).toList();

    for (int i = 0; i < last7Days.length; i++) {
      final usageTime = (last7Days[i]['usage_time_minutes'] as int?) ?? 0;
      spots.add(FlSpot(i.toDouble(), usageTime.toDouble()));
    }

    return spots;
  }

  double _getMaxUsageValue(List<Map<String, dynamic>> analytics) {
    if (analytics.isEmpty) return 100;

    final maxValue = analytics
        .take(7)
        .map((a) => (a['usage_time_minutes'] as int?) ?? 0)
        .reduce((a, b) => a > b ? a : b);

    return (maxValue * 1.2).toDouble();
  }
}
