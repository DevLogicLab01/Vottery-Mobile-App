import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

class ConnectionPoolPanelWidget extends StatelessWidget {
  const ConnectionPoolPanelWidget({super.key});

  @override
  Widget build(BuildContext context) {
    const active = 42;
    const idle = 28;
    const maxConn = 100;
    const utilization = 0.42;

    final activeData = [
      35.0,
      38.0,
      42.0,
      55.0,
      48.0,
      42.0,
      39.0,
      44.0,
      52.0,
      46.0,
      43.0,
      42.0,
    ];
    final idleData = [
      45.0,
      42.0,
      38.0,
      25.0,
      32.0,
      38.0,
      41.0,
      36.0,
      28.0,
      34.0,
      37.0,
      38.0,
    ];

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      padding: EdgeInsets.all(3.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.hub, color: Color(0xFF3B82F6), size: 20),
              SizedBox(width: 2.w),
              Text(
                'Connection Pool',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                decoration: BoxDecoration(
                  color: const Color(0xFF22C55E).withAlpha(38),
                  borderRadius: BorderRadius.circular(6.0),
                ),
                child: Text(
                  '${(utilization * 100).toInt()}% Used',
                  style: GoogleFonts.inter(
                    color: const Color(0xFF22C55E),
                    fontSize: 10.sp,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _statCard('Active', active.toString(), const Color(0xFF3B82F6)),
              _statCard('Idle', idle.toString(), const Color(0xFF22C55E)),
              _statCard('Max', maxConn.toString(), const Color(0xFF94A3B8)),
              _statCard(
                'Util',
                '${(utilization * 100).toInt()}%',
                utilization > 0.8
                    ? const Color(0xFFEF4444)
                    : const Color(0xFF22C55E),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(4.0),
            child: LinearProgressIndicator(
              value: utilization,
              backgroundColor: const Color(0xFF334155),
              valueColor: AlwaysStoppedAnimation<Color>(
                utilization > 0.8
                    ? const Color(0xFFEF4444)
                    : const Color(0xFF3B82F6),
              ),
              minHeight: 8,
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            'Connection Timeline (last 1h)',
            style: GoogleFonts.inter(
              color: const Color(0xFF94A3B8),
              fontSize: 11.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 1.h),
          SizedBox(
            height: 14.h,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawHorizontalLine: true,
                  getDrawingHorizontalLine: (v) =>
                      FlLine(color: const Color(0xFF334155), strokeWidth: 0.5),
                  drawVerticalLine: false,
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (v, _) => Text(
                        '${v.toInt()}',
                        style: GoogleFonts.inter(
                          color: const Color(0xFF94A3B8),
                          fontSize: 9.sp,
                        ),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, _) => Text(
                        '${v.toInt()}m',
                        style: GoogleFonts.inter(
                          color: const Color(0xFF94A3B8),
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
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: activeData
                        .asMap()
                        .entries
                        .map((e) => FlSpot(e.key.toDouble(), e.value))
                        .toList(),
                    isCurved: true,
                    color: const Color(0xFF3B82F6),
                    barWidth: 2,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: const Color(0xFF3B82F6).withAlpha(26),
                    ),
                  ),
                  LineChartBarData(
                    spots: idleData
                        .asMap()
                        .entries
                        .map((e) => FlSpot(e.key.toDouble(), e.value))
                        .toList(),
                    isCurved: true,
                    color: const Color(0xFF22C55E),
                    barWidth: 2,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: const Color(0xFF22C55E).withAlpha(26),
                    ),
                  ),
                ],
                minY: 0,
                maxY: 70,
              ),
            ),
          ),
          if (utilization > 0.8)
            Container(
              margin: EdgeInsets.only(top: 1.h),
              padding: EdgeInsets.all(2.w),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withAlpha(26),
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(
                  color: const Color(0xFFEF4444).withAlpha(77),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.warning_amber,
                    color: Color(0xFFEF4444),
                    size: 16,
                  ),
                  SizedBox(width: 2.w),
                  Text(
                    'Pool utilization above 80% — consider scaling',
                    style: GoogleFonts.inter(
                      color: const Color(0xFFEF4444),
                      fontSize: 10.sp,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.inter(
            color: color,
            fontSize: 16.sp,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.inter(
            color: const Color(0xFF94A3B8),
            fontSize: 9.sp,
          ),
        ),
      ],
    );
  }
}
