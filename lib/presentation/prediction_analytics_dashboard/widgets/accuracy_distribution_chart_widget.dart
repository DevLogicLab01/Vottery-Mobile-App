import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

class AccuracyDistributionChartWidget extends StatelessWidget {
  final Map<String, int> distributionData;

  const AccuracyDistributionChartWidget({
    super.key,
    required this.distributionData,
  });

  @override
  Widget build(BuildContext context) {
    final buckets = ['0-0.2', '0.2-0.4', '0.4-0.6', '0.6-0.8', '0.8-1.0'];
    final values = buckets
        .map((b) => (distributionData[b] ?? 0).toDouble())
        .toList();
    final maxVal = values.reduce((a, b) => a > b ? a : b);
    final colors = [
      const Color(0xFFFF6B6B),
      const Color(0xFFFFB347),
      const Color(0xFFFFD700),
      const Color(0xFF8BC34A),
      const Color(0xFF4CAF50),
    ];

    return Card(
      color: const Color(0xFF1E1E2E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.bar_chart, color: Color(0xFF6C63FF), size: 20),
                SizedBox(width: 2.w),
                Text(
                  'Accuracy Distribution (Brier Score)',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            SizedBox(height: 2.h),
            SizedBox(
              height: 18.h,
              child: maxVal == 0
                  ? Center(
                      child: Text(
                        'No prediction data',
                        style: GoogleFonts.inter(
                          color: Colors.white38,
                          fontSize: 12.sp,
                        ),
                      ),
                    )
                  : BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: maxVal + 5,
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          getDrawingHorizontalLine: (v) =>
                              FlLine(color: Colors.white12, strokeWidth: 1),
                        ),
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 8.w,
                              getTitlesWidget: (v, m) => Text(
                                v.toInt().toString(),
                                style: GoogleFonts.inter(
                                  color: Colors.white38,
                                  fontSize: 9.sp,
                                ),
                              ),
                            ),
                          ),
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (v, m) {
                                final idx = v.toInt();
                                if (idx < 0 || idx >= buckets.length) {
                                  return const SizedBox.shrink();
                                }
                                return Text(
                                  buckets[idx],
                                  style: GoogleFonts.inter(
                                    color: Colors.white54,
                                    fontSize: 9.sp,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        barGroups: List.generate(
                          5,
                          (i) => BarChartGroupData(
                            x: i,
                            barRods: [
                              BarChartRodData(
                                toY: values[i],
                                color: colors[i],
                                width: 8.w,
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(4),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
            ),
            SizedBox(height: 1.h),
            Text(
              'Lower Brier score = better accuracy (0=perfect, 1=worst)',
              style: GoogleFonts.inter(color: Colors.white38, fontSize: 10.sp),
            ),
          ],
        ),
      ),
    );
  }
}
