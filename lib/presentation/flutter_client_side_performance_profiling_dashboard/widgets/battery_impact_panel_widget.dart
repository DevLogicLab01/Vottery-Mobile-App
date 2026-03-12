import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:sizer/sizer.dart';

class BatteryImpactPanelWidget extends StatelessWidget {
  const BatteryImpactPanelWidget({super.key});

  static const List<Map<String, dynamic>> _batteryData = [
    {
      'screen': 'Vote Dashboard',
      'drainRate': 1.2,
      'duration': 8.5,
      'totalDrain': 10.2,
    },
    {
      'screen': 'Social Feed',
      'drainRate': 3.8,
      'duration': 12.0,
      'totalDrain': 45.6,
    },
    {
      'screen': 'Creator Analytics',
      'drainRate': 5.4,
      'duration': 6.2,
      'totalDrain': 33.5,
    },
    {
      'screen': 'Election Studio',
      'drainRate': 0.9,
      'duration': 4.1,
      'totalDrain': 3.7,
    },
    {
      'screen': 'Wallet Dashboard',
      'drainRate': 0.7,
      'duration': 3.5,
      'totalDrain': 2.5,
    },
    {
      'screen': 'Admin Dashboard',
      'drainRate': 6.2,
      'duration': 9.8,
      'totalDrain': 60.8,
    },
    {
      'screen': 'Gamification Hub',
      'drainRate': 2.9,
      'duration': 7.3,
      'totalDrain': 21.2,
    },
  ];

  Color _drainColor(double rate) {
    if (rate < 2.0) return const Color(0xFF22C55E);
    if (rate < 5.0) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  @override
  Widget build(BuildContext context) {
    final sorted = [..._batteryData]
      ..sort(
        (a, b) =>
            (b['drainRate'] as double).compareTo(a['drainRate'] as double),
      );
    return SingleChildScrollView(
      padding: EdgeInsets.all(3.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Battery Impact Analysis',
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 0.5.h),
          Text(
            'Drain rate per screen (% per minute) | Target: < 2% per minute',
            style: GoogleFonts.inter(fontSize: 10.sp, color: Colors.white54),
          ),
          SizedBox(height: 2.h),
          _buildDrainChart(sorted),
          SizedBox(height: 2.h),
          _buildHighImpactList(sorted),
          SizedBox(height: 2.h),
          _buildOptimizationTips(),
        ],
      ),
    );
  }

  Widget _buildDrainChart(List<Map<String, dynamic>> sorted) {
    return Container(
      height: 22.h,
      padding: EdgeInsets.all(2.w),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Drain Rate by Screen (% per minute)',
            style: GoogleFonts.inter(
              fontSize: 11.sp,
              fontWeight: FontWeight.w600,
              color: Colors.white70,
            ),
          ),
          SizedBox(height: 1.h),
          Expanded(
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 8,
                barGroups: sorted
                    .asMap()
                    .entries
                    .map(
                      (e) => BarChartGroupData(
                        x: e.key,
                        barRods: [
                          BarChartRodData(
                            toY: e.value['drainRate'],
                            color: _drainColor(e.value['drainRate']),
                            width: 3.w,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(4),
                              topRight: Radius.circular(4),
                            ),
                          ),
                        ],
                      ),
                    )
                    .toList(),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (val, meta) {
                        final labels = sorted
                            .map(
                              (d) => (d['screen'] as String).split(' ').first,
                            )
                            .toList();
                        if (val.toInt() >= labels.length) {
                          return const SizedBox();
                        }
                        return Text(
                          labels[val.toInt()],
                          style: GoogleFonts.inter(
                            fontSize: 7.sp,
                            color: Colors.white54,
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 24,
                      getTitlesWidget: (val, meta) => Text(
                        '${val.toInt()}%',
                        style: GoogleFonts.inter(
                          fontSize: 7.sp,
                          color: Colors.white38,
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
                  getDrawingHorizontalLine: (_) =>
                      FlLine(color: Colors.white.withOpacity(0.08), strokeWidth: 1),
                ),
                borderData: FlBorderData(show: false),
                extraLinesData: ExtraLinesData(
                  horizontalLines: [
                    HorizontalLine(
                      y: 2,
                      color: const Color(0xFF22C55E).withAlpha(128),
                      strokeWidth: 1,
                      dashArray: [4, 4],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHighImpactList(List<Map<String, dynamic>> sorted) {
    final high = sorted.where((d) => d['drainRate'] >= 5.0).toList();
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: const Color(0xFFEF4444).withAlpha(77)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.battery_alert,
                color: Color(0xFFEF4444),
                size: 16,
              ),
              SizedBox(width: 1.w),
              Text(
                'High Battery Impact Screens',
                style: GoogleFonts.inter(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFEF4444),
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          ...high.map(
            (d) => Padding(
              padding: EdgeInsets.symmetric(vertical: 0.5.h),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      d['screen'],
                      style: GoogleFonts.inter(
                        fontSize: 10.sp,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Text(
                    '${d['drainRate']}%/min',
                    style: GoogleFonts.inter(
                      fontSize: 10.sp,
                      color: const Color(0xFFEF4444),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(width: 2.w),
                  Text(
                    'Total: ${d['totalDrain']}%',
                    style: GoogleFonts.inter(
                      fontSize: 10.sp,
                      color: Colors.white54,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptimizationTips() {
    final tips = [
      {
        'screen': 'Admin Dashboard',
        'tip': 'Reduce background tasks and polling intervals',
      },
      {
        'screen': 'Social Feed',
        'tip': 'Optimize video autoplay and reduce network calls',
      },
      {
        'screen': 'Creator Analytics',
        'tip': 'Decrease chart refresh rate from 1s to 5s',
      },
    ];
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.lightbulb_outline,
                color: Color(0xFFF59E0B),
                size: 16,
              ),
              SizedBox(width: 1.w),
              Text(
                'Battery Optimization Tips',
                style: GoogleFonts.inter(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFF59E0B),
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          ...tips.map(
            (t) => Padding(
              padding: EdgeInsets.symmetric(vertical: 0.5.h),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.arrow_right,
                    color: Colors.white38,
                    size: 14,
                  ),
                  SizedBox(width: 1.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t['screen']!,
                          style: GoogleFonts.inter(
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          t['tip']!,
                          style: GoogleFonts.inter(
                            fontSize: 9.sp,
                            color: Colors.white54,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}