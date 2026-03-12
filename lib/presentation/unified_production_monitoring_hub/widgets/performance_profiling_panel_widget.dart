import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

class PerformanceProfilingPanelWidget extends StatelessWidget {
  final List<Map<String, dynamic>> screenMetrics;

  const PerformanceProfilingPanelWidget({
    super.key,
    required this.screenMetrics,
  });

  Color _loadTimeColor(double loadTimeMs) {
    if (loadTimeMs < 2000) return const Color(0xFF22C55E);
    if (loadTimeMs < 4000) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Screen Load Times',
          style: GoogleFonts.inter(
            fontSize: 13.sp,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1F2937),
          ),
        ),
        SizedBox(height: 0.5.h),
        Row(
          children: [
            _LegendItem(color: const Color(0xFF22C55E), label: '< 2s Good'),
            SizedBox(width: 3.w),
            _LegendItem(color: const Color(0xFFF59E0B), label: '2-4s Warn'),
            SizedBox(width: 3.w),
            _LegendItem(color: const Color(0xFFEF4444), label: '> 4s Critical'),
          ],
        ),
        SizedBox(height: 1.h),
        if (screenMetrics.isEmpty)
          Container(
            height: 20.h,
            alignment: Alignment.center,
            child: Text(
              'No profiling data available',
              style: GoogleFonts.inter(
                fontSize: 11.sp,
                color: const Color(0xFF9CA3AF),
              ),
            ),
          )
        else
          SizedBox(
            height: 22.h,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY:
                    screenMetrics
                        .map((m) => (m['avg_load'] as num?)?.toDouble() ?? 0)
                        .reduce((a, b) => a > b ? a : b) *
                    1.2,
                barGroups: screenMetrics.asMap().entries.map((e) {
                  final loadTime =
                      (e.value['avg_load'] as num?)?.toDouble() ?? 0;
                  return BarChartGroupData(
                    x: e.key,
                    barRods: [
                      BarChartRodData(
                        toY: loadTime,
                        color: _loadTimeColor(loadTime),
                        width: 3.w,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(4),
                        ),
                      ),
                    ],
                  );
                }).toList(),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx >= screenMetrics.length) {
                          return const SizedBox.shrink();
                        }
                        final name =
                            screenMetrics[idx]['screen_name'] as String? ?? '';
                        return Padding(
                          padding: EdgeInsets.only(top: 0.5.h),
                          child: Text(
                            name.length > 6
                                ? '${name.substring(0, 6)}..'
                                : name,
                            style: GoogleFonts.inter(
                              fontSize: 7.sp,
                              color: const Color(0xFF6B7280),
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
                      getTitlesWidget: (value, meta) => Text(
                        '${(value / 1000).toStringAsFixed(1)}s',
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
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) =>
                      FlLine(color: Colors.grey.shade200, strokeWidth: 1),
                ),
                borderData: FlBorderData(show: false),
              ),
            ),
          ),
        SizedBox(height: 2.h),
        Text(
          'Screen Performance Details',
          style: GoogleFonts.inter(
            fontSize: 12.sp,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF374151),
          ),
        ),
        SizedBox(height: 1.h),
        ...screenMetrics.take(5).map((m) => _ScreenMetricRow(metric: m)),
      ],
    );
  }
}

class _ScreenMetricRow extends StatelessWidget {
  final Map<String, dynamic> metric;

  const _ScreenMetricRow({required this.metric});

  @override
  Widget build(BuildContext context) {
    final loadTime = (metric['avg_load'] as num?)?.toDouble() ?? 0;
    final memory = (metric['avg_memory'] as num?)?.toDouble() ?? 0;
    final fps = (metric['min_fps'] as num?)?.toDouble() ?? 60;
    final screenName = metric['screen_name'] as String? ?? 'Unknown';

    Color loadColor;
    if (loadTime < 2000) {
      loadColor = const Color(0xFF22C55E);
    } else if (loadTime < 4000) {
      loadColor = const Color(0xFFF59E0B);
    } else {
      loadColor = const Color(0xFFEF4444);
    }

    return Container(
      margin: EdgeInsets.only(bottom: 1.h),
      padding: EdgeInsets.all(2.5.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              screenName,
              style: GoogleFonts.inter(
                fontSize: 10.sp,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF374151),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            child: Text(
              '${(loadTime / 1000).toStringAsFixed(1)}s',
              style: GoogleFonts.inter(
                fontSize: 10.sp,
                color: loadColor,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: Text(
              '${memory.toStringAsFixed(0)}MB',
              style: GoogleFonts.inter(
                fontSize: 10.sp,
                color: memory > 50
                    ? const Color(0xFFEF4444)
                    : const Color(0xFF6B7280),
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: Text(
              '${fps.toStringAsFixed(0)} FPS',
              style: GoogleFonts.inter(
                fontSize: 10.sp,
                color: fps < 45
                    ? const Color(0xFFEF4444)
                    : const Color(0xFF22C55E),
              ),
              textAlign: TextAlign.center,
            ),
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
        Container(
          width: 3.w,
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
