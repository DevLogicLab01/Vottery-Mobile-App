import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import 'package:fl_chart/fl_chart.dart';

class ZoneRevenueAnalysisWidget extends StatelessWidget {
  final List<Map<String, dynamic>> zones;

  const ZoneRevenueAnalysisWidget({super.key, required this.zones});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2E),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: const Color(0xFF313244)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Zone-Specific Revenue Insights',
            style: GoogleFonts.inter(
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 0.5.h),
          Text(
            '8 Purchasing Power Zones',
            style: GoogleFonts.inter(fontSize: 9.sp, color: Colors.white38),
          ),
          SizedBox(height: 2.h),
          SizedBox(
            height: 18.h,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: zones.isNotEmpty
                    ? (zones
                              .map((z) => z['revenue'] as double? ?? 0)
                              .reduce((a, b) => a > b ? a : b) *
                          1.2)
                    : 100,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final zone = zones[groupIndex];
                      return BarTooltipItem(
                        '${zone['name']}\n\$${(rod.toY / 1000).toStringAsFixed(1)}K',
                        GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      );
                    },
                  ),
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
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx >= 0 && idx < zones.length) {
                          return Text(
                            'Z${idx + 1}',
                            style: GoogleFonts.inter(
                              fontSize: 8.sp,
                              color: Colors.white38,
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 35,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '\$${(value / 1000).toStringAsFixed(0)}K',
                          style: GoogleFonts.inter(
                            fontSize: 7.sp,
                            color: Colors.white38,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) =>
                      FlLine(color: const Color(0xFF313244), strokeWidth: 1),
                ),
                barGroups: List.generate(zones.length, (i) {
                  final zone = zones[i];
                  final revenue = zone['revenue'] as double? ?? 0;
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: revenue,
                        color: const Color(0xFF89B4FA),
                        width: 14,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(4),
                          topRight: Radius.circular(4),
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
          SizedBox(height: 1.5.h),
          ...zones.take(4).map((zone) => _buildZoneRow(zone)),
        ],
      ),
    );
  }

  Widget _buildZoneRow(Map<String, dynamic> zone) {
    final growth = zone['growth_rate'] as double? ?? 0;
    final isPositive = growth >= 0;

    return Padding(
      padding: EdgeInsets.only(bottom: 0.8.h),
      child: Row(
        children: [
          Container(
            width: 6.w,
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFF313244),
              borderRadius: BorderRadius.circular(4.0),
            ),
            child: Text(
              'Z${zone['zone_number']}',
              style: GoogleFonts.inter(
                fontSize: 8.sp,
                color: Colors.white54,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(width: 2.w),
          Expanded(
            child: Text(
              zone['name'] as String? ?? '',
              style: GoogleFonts.inter(fontSize: 10.sp, color: Colors.white70),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            '\$${((zone['arpu'] as double? ?? 0)).toStringAsFixed(2)} ARPU',
            style: GoogleFonts.inter(fontSize: 9.sp, color: Colors.white38),
          ),
          SizedBox(width: 2.w),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                size: 10,
                color: isPositive
                    ? const Color(0xFFA6E3A1)
                    : const Color(0xFFF38BA8),
              ),
              Text(
                '${growth.abs().toStringAsFixed(1)}%',
                style: GoogleFonts.inter(
                  fontSize: 9.sp,
                  color: isPositive
                      ? const Color(0xFFA6E3A1)
                      : const Color(0xFFF38BA8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
