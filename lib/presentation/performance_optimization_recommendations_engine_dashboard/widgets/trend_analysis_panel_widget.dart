import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

class TrendAnalysisPanelWidget extends StatelessWidget {
  final String screenName;
  final List<Map<String, dynamic>> trendData;

  const TrendAnalysisPanelWidget({
    super.key,
    required this.screenName,
    required this.trendData,
  });

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
            'Performance Trend: $screenName',
            style: GoogleFonts.inter(
              fontSize: 12.sp,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1F2937),
            ),
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            'Last 30 days',
            style: GoogleFonts.inter(
              fontSize: 9.sp,
              color: const Color(0xFF9CA3AF),
            ),
          ),
          SizedBox(height: 2.h),
          SizedBox(
            height: 18.h,
            child: trendData.isEmpty
                ? Center(
                    child: Text(
                      'No trend data',
                      style: GoogleFonts.inter(
                        fontSize: 11.sp,
                        color: const Color(0xFF9CA3AF),
                      ),
                    ),
                  )
                : LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (value) =>
                            FlLine(color: Colors.grey.shade200, strokeWidth: 1),
                      ),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            getTitlesWidget: (value, meta) => Text(
                              '${(value / 1000).toStringAsFixed(1)}s',
                              style: GoogleFonts.inter(
                                fontSize: 7.sp,
                                color: const Color(0xFF9CA3AF),
                              ),
                            ),
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) => Text(
                              'D${value.toInt() + 1}',
                              style: GoogleFonts.inter(
                                fontSize: 7.sp,
                                color: const Color(0xFF9CA3AF),
                              ),
                            ),
                          ),
                        ),
                        topTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: trendData.asMap().entries.map((e) {
                            final loadTime =
                                (e.value['load_time_ms'] as num?)?.toDouble() ??
                                0;
                            return FlSpot(e.key.toDouble(), loadTime);
                          }).toList(),
                          isCurved: true,
                          color: const Color(0xFF7C3AED),
                          barWidth: 2,
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (spot, percent, bar, index) {
                              final isOptimized =
                                  trendData[index]['optimization_applied']
                                      as bool? ??
                                  false;
                              return FlDotCirclePainter(
                                radius: isOptimized ? 4 : 2,
                                color: isOptimized
                                    ? const Color(0xFF22C55E)
                                    : const Color(0xFF7C3AED),
                                strokeWidth: 0,
                                strokeColor: Colors.transparent,
                              );
                            },
                          ),
                          belowBarData: BarAreaData(
                            show: true,
                            color: const Color(0xFF7C3AED).withAlpha(26),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
          SizedBox(height: 1.h),
          Row(
            children: [
              _LegendItem(color: const Color(0xFF7C3AED), label: 'Load Time'),
              SizedBox(width: 3.w),
              _LegendItem(
                color: const Color(0xFF22C55E),
                label: 'Optimization Applied',
                isDot: true,
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
  final bool isDot;

  const _LegendItem({
    required this.color,
    required this.label,
    this.isDot = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        isDot
            ? Container(
                width: 2.5.w,
                height: 2.5.w,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              )
            : Container(
                width: 4.w,
                height: 1.5.h,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2.0),
                ),
              ),
        SizedBox(width: 1.w),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 9.sp,
            color: const Color(0xFF6B7280),
          ),
        ),
      ],
    );
  }
}
