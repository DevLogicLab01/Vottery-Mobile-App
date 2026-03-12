import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:sizer/sizer.dart';

class MemoryUsagePanelWidget extends StatelessWidget {
  const MemoryUsagePanelWidget({super.key});

  static const List<Map<String, dynamic>> _memoryData = [
    {
      'screen': 'Vote Dashboard',
      'baseline': 28.0,
      'current': 32.5,
      'delta': 4.5,
    },
    {'screen': 'Social Feed', 'baseline': 35.0, 'current': 48.2, 'delta': 13.2},
    {
      'screen': 'Creator Analytics',
      'baseline': 42.0,
      'current': 67.8,
      'delta': 25.8,
    },
    {
      'screen': 'Election Studio',
      'baseline': 22.0,
      'current': 25.1,
      'delta': 3.1,
    },
    {'screen': 'Wallet', 'baseline': 18.0, 'current': 21.3, 'delta': 3.3},
    {
      'screen': 'Admin Dashboard',
      'baseline': 55.0,
      'current': 78.4,
      'delta': 23.4,
    },
  ];

  Color _memoryColor(double mb) {
    if (mb < 50) return const Color(0xFF22C55E);
    if (mb < 75) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(3.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Memory Usage Per Screen',
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 0.5.h),
          Text(
            'Target: < 50MB per screen | Red = threshold exceeded',
            style: GoogleFonts.inter(fontSize: 10.sp, color: Colors.white54),
          ),
          SizedBox(height: 2.h),
          _buildMemoryBarChart(),
          SizedBox(height: 2.h),
          _buildMemoryTable(),
          SizedBox(height: 2.h),
          _buildLeakDetector(),
        ],
      ),
    );
  }

  Widget _buildMemoryBarChart() {
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
            'Memory Usage Comparison (MB)',
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
                maxY: 90,
                barGroups: _memoryData
                    .asMap()
                    .entries
                    .map(
                      (e) => BarChartGroupData(
                        x: e.key,
                        barRods: [
                          BarChartRodData(
                            toY: e.value['baseline'],
                            color: Colors.white24,
                            width: 2.w,
                          ),
                          BarChartRodData(
                            toY: e.value['current'],
                            color: _memoryColor(e.value['current']),
                            width: 2.w,
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
                        final labels = [
                          'Vote',
                          'Feed',
                          'Creator',
                          'Election',
                          'Wallet',
                          'Admin',
                        ];
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
                      reservedSize: 28,
                      getTitlesWidget: (val, meta) => Text(
                        '${val.toInt()}',
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
                      y: 50,
                      color: const Color(0xFFEF4444).withAlpha(128),
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

  Widget _buildMemoryTable() {
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
                    'Baseline',
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
                    'Current',
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
                    'Delta',
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
          ..._memoryData.map(
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
                      '${row['baseline']}MB',
                      style: GoogleFonts.inter(
                        fontSize: 10.sp,
                        color: Colors.white54,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      '${row['current']}MB',
                      style: GoogleFonts.inter(
                        fontSize: 10.sp,
                        color: _memoryColor(row['current']),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      '+${row['delta']}MB',
                      style: GoogleFonts.inter(
                        fontSize: 10.sp,
                        color: row['delta'] > 10
                            ? const Color(0xFFEF4444)
                            : Colors.white54,
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

  Widget _buildLeakDetector() {
    final leaking = _memoryData.where((d) => d['delta'] > 10).toList();
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: const Color(0xFFF59E0B).withAlpha(102)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.memory, color: Color(0xFFF59E0B), size: 16),
              SizedBox(width: 1.w),
              Text(
                'Memory Leak Detector',
                style: GoogleFonts.inter(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFF59E0B),
                ),
              ),
              const Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.3.h),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withAlpha(51),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Text(
                  '${leaking.length} screens',
                  style: GoogleFonts.inter(
                    fontSize: 9.sp,
                    color: const Color(0xFFF59E0B),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          ...leaking.map(
            (d) => Padding(
              padding: EdgeInsets.symmetric(vertical: 0.5.h),
              child: Row(
                children: [
                  const Icon(
                    Icons.arrow_upward,
                    color: Color(0xFFEF4444),
                    size: 14,
                  ),
                  SizedBox(width: 1.w),
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
                    'Growing +${d['delta']}MB',
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