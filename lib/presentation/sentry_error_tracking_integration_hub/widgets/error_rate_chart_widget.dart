import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';

class ErrorRateChartWidget extends StatelessWidget {
  final Map<String, dynamic> errorStats;

  const ErrorRateChartWidget({super.key, required this.errorStats});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final criticalCount = (errorStats['critical_count'] ?? 0) as int;
    final highCount = (errorStats['high_count'] ?? 0) as int;
    final mediumCount = (errorStats['medium_count'] ?? 0) as int;
    final lowCount = (errorStats['low_count'] ?? 0) as int;

    return Card(
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Error Distribution by Severity',
              style: GoogleFonts.inter(
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            SizedBox(height: 3.h),
            SizedBox(
              height: 30.h,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY:
                      [
                        criticalCount,
                        highCount,
                        mediumCount,
                        lowCount,
                      ].reduce((a, b) => a > b ? a : b).toDouble() *
                      1.2,
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        String label;
                        switch (groupIndex) {
                          case 0:
                            label = 'Critical';
                            break;
                          case 1:
                            label = 'High';
                            break;
                          case 2:
                            label = 'Medium';
                            break;
                          case 3:
                            label = 'Low';
                            break;
                          default:
                            label = '';
                        }
                        return BarTooltipItem(
                          '$label\n${rod.toY.toInt()}',
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          String text;
                          switch (value.toInt()) {
                            case 0:
                              text = 'Critical';
                              break;
                            case 1:
                              text = 'High';
                              break;
                            case 2:
                              text = 'Medium';
                              break;
                            case 3:
                              text = 'Low';
                              break;
                            default:
                              text = '';
                          }
                          return Padding(
                            padding: EdgeInsets.only(top: 1.h),
                            child: Text(
                              text,
                              style: GoogleFonts.inter(
                                fontSize: 10.sp,
                                fontWeight: FontWeight.w600,
                              ),
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
                            style: GoogleFonts.inter(fontSize: 10.sp),
                          );
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
                  borderData: FlBorderData(show: false),
                  barGroups: [
                    BarChartGroupData(
                      x: 0,
                      barRods: [
                        BarChartRodData(
                          toY: criticalCount.toDouble(),
                          color: Colors.red,
                          width: 40,
                          borderRadius: BorderRadius.circular(4.0),
                        ),
                      ],
                    ),
                    BarChartGroupData(
                      x: 1,
                      barRods: [
                        BarChartRodData(
                          toY: highCount.toDouble(),
                          color: Colors.orange,
                          width: 40,
                          borderRadius: BorderRadius.circular(4.0),
                        ),
                      ],
                    ),
                    BarChartGroupData(
                      x: 2,
                      barRods: [
                        BarChartRodData(
                          toY: mediumCount.toDouble(),
                          color: Colors.yellow.shade700,
                          width: 40,
                          borderRadius: BorderRadius.circular(4.0),
                        ),
                      ],
                    ),
                    BarChartGroupData(
                      x: 3,
                      barRods: [
                        BarChartRodData(
                          toY: lowCount.toDouble(),
                          color: Colors.blue,
                          width: 40,
                          borderRadius: BorderRadius.circular(4.0),
                        ),
                      ],
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
}
