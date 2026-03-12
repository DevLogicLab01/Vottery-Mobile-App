import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:sizer/sizer.dart';

class ScreenLoadTimesPanelWidget extends StatelessWidget {
  const ScreenLoadTimesPanelWidget({super.key});

  static const List<Map<String, dynamic>> _screenData = [
    {'screen': 'Vote Dashboard', 'avg': 1240, 'p95': 2100, 'status': 'good'},
    {'screen': 'Social Feed', 'avg': 1850, 'p95': 3200, 'status': 'warning'},
    {
      'screen': 'Creator Analytics',
      'avg': 2400,
      'p95': 4100,
      'status': 'critical',
    },
    {'screen': 'Election Studio', 'avg': 980, 'p95': 1600, 'status': 'good'},
    {'screen': 'Wallet Dashboard', 'avg': 1100, 'p95': 1900, 'status': 'good'},
    {
      'screen': 'Admin Dashboard',
      'avg': 2800,
      'p95': 4800,
      'status': 'critical',
    },
    {'screen': 'Vote Casting', 'avg': 750, 'p95': 1200, 'status': 'good'},
    {
      'screen': 'Gamification Hub',
      'avg': 1650,
      'p95': 2900,
      'status': 'warning',
    },
  ];

  Color _statusColor(String status) {
    switch (status) {
      case 'good':
        return const Color(0xFF22C55E);
      case 'warning':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFFEF4444);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(3.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Screen Load Times',
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            'Target: < 2000ms | P95 threshold for optimization priority',
            style: GoogleFonts.inter(fontSize: 10.sp, color: Colors.white54),
          ),
          SizedBox(height: 2.h),
          _buildDistributionHistogram(),
          SizedBox(height: 2.h),
          _buildDataTable(),
          SizedBox(height: 2.h),
          _buildSlowestScreens(),
        ],
      ),
    );
  }

  Widget _buildDistributionHistogram() {
    return Container(
      height: 18.h,
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
            'Load Time Distribution',
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
                maxY: 5,
                barGroups: [
                  BarChartGroupData(
                    x: 0,
                    barRods: [
                      BarChartRodData(
                        toY: 3,
                        color: const Color(0xFF22C55E),
                        width: 3.w,
                      ),
                    ],
                  ),
                  BarChartGroupData(
                    x: 1,
                    barRods: [
                      BarChartRodData(
                        toY: 2,
                        color: const Color(0xFF22C55E),
                        width: 3.w,
                      ),
                    ],
                  ),
                  BarChartGroupData(
                    x: 2,
                    barRods: [
                      BarChartRodData(
                        toY: 2,
                        color: const Color(0xFFF59E0B),
                        width: 3.w,
                      ),
                    ],
                  ),
                  BarChartGroupData(
                    x: 3,
                    barRods: [
                      BarChartRodData(
                        toY: 1,
                        color: const Color(0xFFEF4444),
                        width: 3.w,
                      ),
                    ],
                  ),
                  BarChartGroupData(
                    x: 4,
                    barRods: [
                      BarChartRodData(
                        toY: 0,
                        color: const Color(0xFFEF4444),
                        width: 3.w,
                      ),
                    ],
                  ),
                ],
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (val, meta) {
                        const labels = [
                          '0-500',
                          '500-1k',
                          '1k-2k',
                          '2k-5k',
                          '>5k',
                        ];
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
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: FlGridData(show: false),
                borderData: FlBorderData(show: false),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataTable() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.5.h),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.white12)),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    'Screen',
                    style: GoogleFonts.inter(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.white70,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Avg (ms)',
                    style: GoogleFonts.inter(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.white70,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'P95 (ms)',
                    style: GoogleFonts.inter(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.white70,
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    'Status',
                    style: GoogleFonts.inter(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.white70,
                    ),
                  ),
                ),
              ],
            ),
          ),
          ..._screenData.map(
            (row) => Container(
              padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.08))),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(
                      row['screen'],
                      style: GoogleFonts.inter(
                        fontSize: 10.sp,
                        color: Colors.white,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      '${row['avg']}',
                      style: GoogleFonts.inter(
                        fontSize: 10.sp,
                        color: _statusColor(row['status']),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      '${row['p95']}',
                      style: GoogleFonts.inter(
                        fontSize: 10.sp,
                        color: row['p95'] > 2000
                            ? const Color(0xFFEF4444)
                            : Colors.white70,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Container(
                      width: 8.0,
                      height: 8.0,
                      decoration: BoxDecoration(
                        color: _statusColor(row['status']),
                        shape: BoxShape.circle,
                      ),
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

  Widget _buildSlowestScreens() {
    final slowest = [..._screenData]
      ..sort((a, b) => (b['p95'] as int).compareTo(a['p95'] as int));
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
                Icons.warning_amber_rounded,
                color: Color(0xFFEF4444),
                size: 16,
              ),
              SizedBox(width: 1.w),
              Text(
                'Slowest Screens — Optimization Priority',
                style: GoogleFonts.inter(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFEF4444),
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          ...slowest
              .take(3)
              .toList()
              .asMap()
              .entries
              .map(
                (e) => Padding(
                  padding: EdgeInsets.symmetric(vertical: 0.5.h),
                  child: Row(
                    children: [
                      Container(
                        width: 5.w,
                        height: 5.w,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444).withAlpha(51),
                          borderRadius: BorderRadius.circular(4.0),
                        ),
                        child: Center(
                          child: Text(
                            '${e.key + 1}',
                            style: GoogleFonts.inter(
                              fontSize: 9.sp,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFFEF4444),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 2.w),
                      Expanded(
                        child: Text(
                          e.value['screen'],
                          style: GoogleFonts.inter(
                            fontSize: 10.sp,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      Text(
                        'P95: ${e.value['p95']}ms',
                        style: GoogleFonts.inter(
                          fontSize: 10.sp,
                          color: const Color(0xFFEF4444),
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