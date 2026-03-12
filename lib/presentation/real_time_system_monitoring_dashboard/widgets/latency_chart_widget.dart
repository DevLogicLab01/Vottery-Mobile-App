import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class LatencyChartWidget extends StatelessWidget {
  final Map<String, dynamic> latencyStats;

  const LatencyChartWidget({super.key, required this.latencyStats});

  @override
  Widget build(BuildContext context) {
    final avgLatency = (latencyStats['average_ms'] ?? 0).toDouble();
    final p50Latency = (latencyStats['p50_ms'] ?? 0).toDouble();
    final p95Latency = (latencyStats['p95_ms'] ?? 0).toDouble();
    final p99Latency = (latencyStats['p99_ms'] ?? 0).toDouble();

    return Card(
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Latency Distribution',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryLight,
              ),
            ),
            SizedBox(height: 3.h),
            SizedBox(
              height: 30.h,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: p99Latency * 1.2,
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        String label;
                        switch (groupIndex) {
                          case 0:
                            label = 'Average';
                            break;
                          case 1:
                            label = 'P50';
                            break;
                          case 2:
                            label = 'P95';
                            break;
                          case 3:
                            label = 'P99';
                            break;
                          default:
                            label = '';
                        }
                        return BarTooltipItem(
                          '$label\n${rod.toY.toInt()}ms',
                          TextStyle(
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
                              text = 'Avg';
                              break;
                            case 1:
                              text = 'P50';
                              break;
                            case 2:
                              text = 'P95';
                              break;
                            case 3:
                              text = 'P99';
                              break;
                            default:
                              text = '';
                          }
                          return Padding(
                            padding: EdgeInsets.only(top: 1.h),
                            child: Text(
                              text,
                              style: TextStyle(
                                fontSize: 11.sp,
                                color: AppTheme.textSecondaryLight,
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
                            '${value.toInt()}ms',
                            style: TextStyle(
                              fontSize: 10.sp,
                              color: AppTheme.textSecondaryLight,
                            ),
                          );
                        },
                      ),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: p99Latency / 5,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: AppTheme.borderLight,
                        strokeWidth: 1,
                      );
                    },
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: [
                    BarChartGroupData(
                      x: 0,
                      barRods: [
                        BarChartRodData(
                          toY: avgLatency,
                          color: AppTheme.primaryLight,
                          width: 12.w,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    ),
                    BarChartGroupData(
                      x: 1,
                      barRods: [
                        BarChartRodData(
                          toY: p50Latency,
                          color: AppTheme.accentLight,
                          width: 12.w,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    ),
                    BarChartGroupData(
                      x: 2,
                      barRods: [
                        BarChartRodData(
                          toY: p95Latency,
                          color: p95Latency > 1000
                              ? AppTheme.warningLight
                              : AppTheme.secondaryLight,
                          width: 12.w,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    ),
                    BarChartGroupData(
                      x: 3,
                      barRods: [
                        BarChartRodData(
                          toY: p99Latency,
                          color: p99Latency > 2000
                              ? AppTheme.errorLight
                              : AppTheme.secondaryLight,
                          width: 12.w,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 2.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildLegendItem('Healthy', AppTheme.accentLight),
                _buildLegendItem('Warning', AppTheme.warningLight),
                _buildLegendItem('Critical', AppTheme.errorLight),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 3.w,
          height: 3.w,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        SizedBox(width: 1.w),
        Text(
          label,
          style: TextStyle(fontSize: 11.sp, color: AppTheme.textSecondaryLight),
        ),
      ],
    );
  }
}
