import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:fl_chart/fl_chart.dart';

class GrowthTrajectoryChartWidget extends StatelessWidget {
  final List<Map<String, dynamic>> predictions;
  const GrowthTrajectoryChartWidget({super.key, required this.predictions});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Growth Trajectory',
            style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w700),
          ),
          Text(
            'Predicted earnings over 90 days',
            style: TextStyle(fontSize: 10.sp, color: Colors.grey.shade600),
          ),
          SizedBox(height: 2.h),
          SizedBox(
            height: 25.h,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (v) =>
                      FlLine(color: Colors.grey.shade100, strokeWidth: 1),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (v, m) => Text(
                        '\$${v.round()}',
                        style: TextStyle(
                          fontSize: 9.sp,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, m) {
                        final labels = ['Now', '30d', '60d', '90d'];
                        final idx = v.round();
                        return idx >= 0 && idx < labels.length
                            ? Text(
                                labels[idx],
                                style: TextStyle(
                                  fontSize: 9.sp,
                                  color: Colors.grey.shade600,
                                ),
                              )
                            : const Text('');
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
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: const [
                      FlSpot(0, 500),
                      FlSpot(1, 750),
                      FlSpot(2, 900),
                      FlSpot(3, 1100),
                    ],
                    isCurved: true,
                    color: const Color(0xFF3B82F6),
                    barWidth: 2.5,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: const Color(0xFF3B82F6).withAlpha(26),
                    ),
                  ),
                  LineChartBarData(
                    spots: const [
                      FlSpot(0, 600),
                      FlSpot(1, 900),
                      FlSpot(2, 1100),
                      FlSpot(3, 1400),
                    ],
                    isCurved: true,
                    color: const Color(0xFF3B82F6).withAlpha(51),
                    barWidth: 1,
                    dotData: const FlDotData(show: false),
                    dashArray: [5, 5],
                  ),
                  LineChartBarData(
                    spots: const [
                      FlSpot(0, 400),
                      FlSpot(1, 600),
                      FlSpot(2, 700),
                      FlSpot(3, 800),
                    ],
                    isCurved: true,
                    color: const Color(0xFF3B82F6).withAlpha(51),
                    barWidth: 1,
                    dotData: const FlDotData(show: false),
                    dashArray: [5, 5],
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 1.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _LegendItem(
                color: const Color(0xFF3B82F6),
                label: 'Predicted Earnings',
              ),
              SizedBox(width: 4.w),
              _LegendItem(
                color: const Color(0xFF3B82F6).withAlpha(128),
                label: 'Confidence Band',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendItem({required this.color, required this.label});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 16, height: 2, color: color),
        SizedBox(width: 1.w),
        Text(
          label,
          style: TextStyle(fontSize: 9.sp, color: Colors.grey.shade600),
        ),
      ],
    );
  }
}
