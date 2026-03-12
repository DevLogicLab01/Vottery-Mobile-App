import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../services/creator_earnings_service.dart';
import '../../../theme/app_theme.dart';

class DailyEarningsChartWidget extends StatelessWidget {
  final CreatorEarningsService _earningsService =
      CreatorEarningsService.instance;

  DailyEarningsChartWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _earningsService.getDailyEarnings(days: 7),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        final dailyData = snapshot.data ?? [];

        if (dailyData.isEmpty) {
          return Center(
            child: Text(
              'No earnings data available',
              style: TextStyle(
                fontSize: 14.sp,
                color: AppTheme.textSecondaryLight,
              ),
            ),
          );
        }

        return Padding(
          padding: EdgeInsets.all(4.w),
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: 1,
                getDrawingHorizontalLine: (value) {
                  return FlLine(color: AppTheme.borderLight, strokeWidth: 1);
                },
              ),
              titlesData: FlTitlesData(
                show: true,
                rightTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    interval: 1,
                    getTitlesWidget: (value, meta) {
                      if (value.toInt() >= 0 &&
                          value.toInt() < dailyData.length) {
                        final date = DateTime.parse(
                          dailyData[value.toInt()]['date'],
                        );
                        return Padding(
                          padding: EdgeInsets.only(top: 1.h),
                          child: Text(
                            _formatDate(date),
                            style: TextStyle(
                              fontSize: 10.sp,
                              color: AppTheme.textSecondaryLight,
                            ),
                          ),
                        );
                      }
                      return Text('');
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        '\$${value.toInt()}',
                        style: TextStyle(
                          fontSize: 10.sp,
                          color: AppTheme.textSecondaryLight,
                        ),
                      );
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(
                show: true,
                border: Border.all(color: AppTheme.borderLight, width: 1),
              ),
              minX: 0,
              maxX: (dailyData.length - 1).toDouble(),
              minY: 0,
              maxY: _getMaxY(dailyData),
              lineBarsData: [
                LineChartBarData(
                  spots: dailyData.asMap().entries.map((entry) {
                    return FlSpot(
                      entry.key.toDouble(),
                      (entry.value['usd_earned'] ?? 0.0).toDouble(),
                    );
                  }).toList(),
                  isCurved: true,
                  gradient: LinearGradient(
                    colors: [AppTheme.primaryLight, AppTheme.secondaryLight],
                  ),
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, barData, index) {
                      return FlDotCirclePainter(
                        radius: 4,
                        color: AppTheme.primaryLight,
                        strokeWidth: 2,
                        strokeColor: Colors.white,
                      );
                    },
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primaryLight.withAlpha(77),
                        AppTheme.secondaryLight.withAlpha(26),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return weekdays[date.weekday - 1];
  }

  double _getMaxY(List<Map<String, dynamic>> data) {
    if (data.isEmpty) return 10.0;
    final maxValue = data
        .map((d) => (d['usd_earned'] ?? 0.0).toDouble())
        .reduce((a, b) => a > b ? a : b);
    return (maxValue * 1.2).ceilToDouble();
  }
}
