import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../theme/app_theme.dart';

/// Widget displaying abstention trends over time
class AbstentionTrendsChartWidget extends StatelessWidget {
  final List<Map<String, dynamic>> trends;

  const AbstentionTrendsChartWidget({super.key, required this.trends});

  @override
  Widget build(BuildContext context) {
    if (trends.isEmpty) {
      return Container(
        height: 30.h,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Center(
          child: Text(
            'No trend data available',
            style: GoogleFonts.inter(fontSize: 13.sp, color: Colors.grey),
          ),
        ),
      );
    }

    return Container(
      height: 30.h,
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 8.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 5,
            getDrawingHorizontalLine: (value) {
              return FlLine(color: Colors.grey.shade200, strokeWidth: 1);
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
                interval: 1,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() >= 0 && value.toInt() < trends.length) {
                    final date = DateTime.parse(trends[value.toInt()]['date']);
                    return Padding(
                      padding: EdgeInsets.only(top: 1.h),
                      child: Text(
                        '${date.day}/${date.month}',
                        style: GoogleFonts.inter(
                          fontSize: 10.sp,
                          color: Colors.grey,
                        ),
                      ),
                    );
                  }
                  return const SizedBox();
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 5,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  return Text(
                    '${value.toInt()}%',
                    style: GoogleFonts.inter(
                      fontSize: 10.sp,
                      color: Colors.grey,
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border.all(color: Colors.grey.shade200),
          ),
          minX: 0,
          maxX: (trends.length - 1).toDouble(),
          minY: 0,
          maxY: 30,
          lineBarsData: [
            LineChartBarData(
              spots: trends.asMap().entries.map((entry) {
                final rate =
                    (entry.value['average_abstention_rate'] as num?)
                        ?.toDouble() ??
                    0.0;
                return FlSpot(entry.key.toDouble(), rate);
              }).toList(),
              isCurved: true,
              color: AppTheme.primaryLight,
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
                color: AppTheme.primaryLight.withAlpha(26),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
