import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class CostTrackingChartWidget extends StatelessWidget {
  final List<Map<String, dynamic>> dailyBreakdown;

  const CostTrackingChartWidget({super.key, required this.dailyBreakdown});

  @override
  Widget build(BuildContext context) {
    if (dailyBreakdown.isEmpty) {
      return Center(
        child: Text(
          'No usage data available',
          style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
        ),
      );
    }

    final spots = <FlSpot>[];
    for (var i = 0; i < dailyBreakdown.length && i < 7; i++) {
      final cost = (dailyBreakdown[i]['cost'] as num).toDouble();
      spots.add(FlSpot(i.toDouble(), cost));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Cost Tracking (Last 7 Days)',
          style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w700),
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
                    getTitlesWidget: (value, meta) {
                      return Text(
                        '\$${value.toInt()}',
                        style: TextStyle(fontSize: 9.sp),
                      );
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      if (value.toInt() < dailyBreakdown.length) {
                        return Text(
                          'Day ${value.toInt() + 1}',
                          style: TextStyle(fontSize: 9.sp),
                        );
                      }
                      return const Text('');
                    },
                  ),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              borderData: FlBorderData(show: true),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  color: Colors.blue,
                  barWidth: 3,
                  dotData: const FlDotData(show: true),
                  belowBarData: BarAreaData(
                    show: true,
                    color: Colors.blue.withAlpha(51),
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
