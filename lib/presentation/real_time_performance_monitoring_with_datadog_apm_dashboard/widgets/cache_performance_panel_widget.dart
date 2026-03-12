import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

class CachePerformancePanelWidget extends StatelessWidget {
  const CachePerformancePanelWidget({super.key});

  @override
  Widget build(BuildContext context) {
    const hitRate = 0.87;
    const targetRate = 0.85;

    final pieData = [
      {'label': 'leaderboard', 'rate': 0.92, 'color': const Color(0xFF6366F1)},
      {'label': 'creator', 'rate': 0.85, 'color': const Color(0xFF22C55E)},
      {'label': 'election', 'rate': 0.78, 'color': const Color(0xFFF59E0B)},
    ];

    final hitsData = [820.0, 850.0, 870.0, 840.0, 890.0, 910.0, 880.0, 860.0];
    final missData = [120.0, 110.0, 105.0, 130.0, 95.0, 88.0, 102.0, 115.0];

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
              const Icon(Icons.memory, color: Color(0xFF22C55E), size: 20),
              SizedBox(width: 2.w),
              Text(
                'Cache Performance',
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
                  'Above Target',
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
            children: [
              Expanded(
                child: Column(
                  children: [
                    SizedBox(
                      height: 14.h,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          PieChart(
                            PieChartData(
                              startDegreeOffset: -90,
                              sectionsSpace: 0,
                              centerSpaceRadius: 35,
                              sections: [
                                PieChartSectionData(
                                  value: hitRate * 100,
                                  color: const Color(0xFF22C55E),
                                  radius: 18,
                                  showTitle: false,
                                ),
                                PieChartSectionData(
                                  value: (1 - hitRate) * 100,
                                  color: const Color(0xFF334155),
                                  radius: 18,
                                  showTitle: false,
                                ),
                              ],
                            ),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${(hitRate * 100).toInt()}%',
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                'Hit Rate',
                                style: GoogleFonts.inter(
                                  color: const Color(0xFF94A3B8),
                                  fontSize: 9.sp,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Text(
                      'Target: ${(targetRate * 100).toInt()}%',
                      style: GoogleFonts.inter(
                        color: const Color(0xFF94A3B8),
                        fontSize: 10.sp,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 14.h,
                  child: BarChart(
                    BarChartData(
                      gridData: FlGridData(show: false),
                      titlesData: FlTitlesData(
                        leftTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
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
                            getTitlesWidget: (v, _) => Text(
                              '${v.toInt()}h',
                              style: GoogleFonts.inter(
                                color: const Color(0xFF94A3B8),
                                fontSize: 8.sp,
                              ),
                            ),
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      barGroups: List.generate(8, (i) {
                        return BarChartGroupData(
                          x: i,
                          barRods: [
                            BarChartRodData(
                              toY: hitsData[i],
                              color: const Color(0xFF22C55E),
                              width: 6,
                              borderRadius: BorderRadius.circular(2.0),
                            ),
                            BarChartRodData(
                              toY: missData[i],
                              color: const Color(0xFFEF4444),
                              width: 6,
                              borderRadius: BorderRadius.circular(2.0),
                            ),
                          ],
                        );
                      }),
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Text(
            'Cache Key Hit Rate by Pattern',
            style: GoogleFonts.inter(
              color: const Color(0xFF94A3B8),
              fontSize: 11.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 1.h),
          ...pieData.map((d) => _patternRow(d)),
        ],
      ),
    );
  }

  Widget _patternRow(Map<String, dynamic> d) {
    final rate = d['rate'] as double;
    final color = d['color'] as Color;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 0.5.h),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          SizedBox(width: 2.w),
          Expanded(
            child: Text(
              d['label'] as String,
              style: GoogleFonts.inter(color: Colors.white, fontSize: 10.sp),
            ),
          ),
          SizedBox(
            width: 20.w,
            child: LinearProgressIndicator(
              value: rate,
              backgroundColor: const Color(0xFF334155),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 6,
              borderRadius: BorderRadius.circular(3.0),
            ),
          ),
          SizedBox(width: 2.w),
          Text(
            '${(rate * 100).toInt()}%',
            style: GoogleFonts.inter(color: color, fontSize: 10.sp),
          ),
        ],
      ),
    );
  }
}
