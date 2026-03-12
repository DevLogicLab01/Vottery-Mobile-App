import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

class DatadogApmPanelWidget extends StatelessWidget {
  final List<Map<String, dynamic>> latencyData;
  final double errorRate;
  final int activeRequests;

  const DatadogApmPanelWidget({
    super.key,
    required this.latencyData,
    required this.errorRate,
    required this.activeRequests,
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
          Row(
            children: [
              Icon(
                Icons.monitor_heart,
                color: const Color(0xFF7C3AED),
                size: 5.w,
              ),
              SizedBox(width: 2.w),
              Text(
                'Datadog APM',
                style: GoogleFonts.inter(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1F2937),
                ),
              ),
              const Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.3.h),
                decoration: BoxDecoration(
                  color: errorRate < 0.5
                      ? const Color(0xFF22C55E).withAlpha(26)
                      : const Color(0xFFEF4444).withAlpha(26),
                  borderRadius: BorderRadius.circular(6.0),
                ),
                child: Text(
                  'Error: ${errorRate.toStringAsFixed(2)}%',
                  style: GoogleFonts.inter(
                    fontSize: 9.sp,
                    color: errorRate < 0.5
                        ? const Color(0xFF22C55E)
                        : const Color(0xFFEF4444),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Row(
            children: [
              _StatChip(
                label: 'Active Requests',
                value: '$activeRequests',
                color: const Color(0xFF3B82F6),
              ),
              SizedBox(width: 2.w),
              _StatChip(
                label: 'Error Rate',
                value: '${errorRate.toStringAsFixed(2)}%',
                color: errorRate < 0.5
                    ? const Color(0xFF22C55E)
                    : const Color(0xFFEF4444),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Text(
            'Query Latency (last 1h)',
            style: GoogleFonts.inter(
              fontSize: 11.sp,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF374151),
            ),
          ),
          SizedBox(height: 1.h),
          SizedBox(
            height: 18.h,
            child: latencyData.isEmpty
                ? Center(
                    child: Text(
                      'No data available',
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
                            reservedSize: 35,
                            getTitlesWidget: (value, meta) => Text(
                              '${value.toInt()}ms',
                              style: GoogleFonts.inter(
                                fontSize: 7.sp,
                                color: const Color(0xFF9CA3AF),
                              ),
                            ),
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
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
                        _buildLine(latencyData, 'p50', const Color(0xFF22C55E)),
                        _buildLine(latencyData, 'p95', const Color(0xFFF59E0B)),
                        _buildLine(latencyData, 'p99', const Color(0xFFEF4444)),
                      ],
                    ),
                  ),
          ),
          SizedBox(height: 1.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _LegendDot(color: const Color(0xFF22C55E), label: 'p50'),
              SizedBox(width: 3.w),
              _LegendDot(color: const Color(0xFFF59E0B), label: 'p95'),
              SizedBox(width: 3.w),
              _LegendDot(color: const Color(0xFFEF4444), label: 'p99'),
            ],
          ),
        ],
      ),
    );
  }

  LineChartBarData _buildLine(
    List<Map<String, dynamic>> data,
    String key,
    Color color,
  ) {
    return LineChartBarData(
      spots: data.asMap().entries.map((e) {
        final val = (e.value[key] as num?)?.toDouble() ?? 0;
        return FlSpot(e.key.toDouble(), val);
      }).toList(),
      isCurved: true,
      color: color,
      barWidth: 2,
      dotData: const FlDotData(show: false),
      belowBarData: BarAreaData(show: true, color: color.withAlpha(26)),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(6.0),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 11.sp,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 8.sp,
              color: const Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 2.5.w,
          height: 2.5.w,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
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
