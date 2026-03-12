import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

class QueryLatencyPanelWidget extends StatelessWidget {
  const QueryLatencyPanelWidget({super.key});

  Color _latencyColor(double ms) {
    if (ms < 50) return const Color(0xFF22C55E);
    if (ms <= 100) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  @override
  Widget build(BuildContext context) {
    final queryBreakdown = [
      {'query': 'elections_feed', 'avg': 42.0, 'p95': 78.0, 'calls': 1240},
      {'query': 'creator_analytics', 'avg': 88.0, 'p95': 134.0, 'calls': 560},
      {'query': 'leaderboard', 'avg': 31.0, 'p95': 55.0, 'calls': 890},
      {'query': 'user_profile', 'avg': 19.0, 'p95': 38.0, 'calls': 2100},
      {'query': 'vote_counts', 'avg': 65.0, 'p95': 112.0, 'calls': 430},
    ];

    final p50Data = [
      35.0,
      42.0,
      38.0,
      55.0,
      48.0,
      41.0,
      39.0,
      44.0,
      52.0,
      46.0,
      43.0,
      40.0,
    ];
    final p95Data = [
      72.0,
      85.0,
      78.0,
      98.0,
      91.0,
      82.0,
      76.0,
      88.0,
      95.0,
      87.0,
      83.0,
      79.0,
    ];
    final p99Data = [
      110.0,
      125.0,
      118.0,
      142.0,
      135.0,
      122.0,
      115.0,
      128.0,
      138.0,
      130.0,
      124.0,
      119.0,
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
              const Icon(Icons.speed, color: Color(0xFF6366F1), size: 20),
              SizedBox(width: 2.w),
              Text(
                'Query Latency Panel',
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
                  'P95: 87ms',
                  style: GoogleFonts.inter(
                    color: const Color(0xFF22C55E),
                    fontSize: 11.sp,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          SizedBox(
            height: 18.h,
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
                      reservedSize: 35,
                      getTitlesWidget: (v, _) => Text(
                        '${v.toInt()}ms',
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
                extraLinesData: ExtraLinesData(
                  horizontalLines: [
                    HorizontalLine(
                      y: 100,
                      color: const Color(0xFFEF4444),
                      strokeWidth: 1.5,
                      dashArray: [5, 5],
                      label: HorizontalLineLabel(
                        show: true,
                        labelResolver: (_) => '100ms SLA',
                        style: GoogleFonts.inter(
                          color: const Color(0xFFEF4444),
                          fontSize: 9.sp,
                        ),
                      ),
                    ),
                  ],
                ),
                lineBarsData: [
                  _buildLine(p50Data, const Color(0xFF22C55E)),
                  _buildLine(p95Data, const Color(0xFFF59E0B)),
                  _buildLine(p99Data, const Color(0xFFEF4444)),
                ],
                minY: 0,
                maxY: 160,
              ),
            ),
          ),
          SizedBox(height: 1.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _legend('P50', const Color(0xFF22C55E)),
              SizedBox(width: 3.w),
              _legend('P95', const Color(0xFFF59E0B)),
              SizedBox(width: 3.w),
              _legend('P99', const Color(0xFFEF4444)),
              SizedBox(width: 3.w),
              _legend('100ms SLA', const Color(0xFFEF4444), dashed: true),
            ],
          ),
          SizedBox(height: 2.h),
          Text(
            'Per-Query Breakdown',
            style: GoogleFonts.inter(
              color: const Color(0xFF94A3B8),
              fontSize: 11.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 1.h),
          ...queryBreakdown.map((q) => _queryRow(q)),
        ],
      ),
    );
  }

  LineChartBarData _buildLine(List<double> data, Color color) {
    return LineChartBarData(
      spots: data
          .asMap()
          .entries
          .map((e) => FlSpot(e.key.toDouble(), e.value))
          .toList(),
      isCurved: true,
      color: color,
      barWidth: 2,
      dotData: const FlDotData(show: false),
      belowBarData: BarAreaData(show: false),
    );
  }

  Widget _legend(String label, Color color, {bool dashed = false}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 2,
          color: dashed ? Colors.transparent : color,
          child: dashed
              ? Row(
                  children: [
                    Container(width: 5, height: 2, color: color),
                    SizedBox(width: 2),
                    Container(width: 5, height: 2, color: color),
                  ],
                )
              : null,
        ),
        SizedBox(width: 4),
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

  Widget _queryRow(Map<String, dynamic> q) {
    final avg = q['avg'] as double;
    final p95 = q['p95'] as double;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 0.4.h),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              q['query'] as String,
              style: GoogleFonts.inter(color: Colors.white, fontSize: 10.sp),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 1.w, vertical: 0.3.h),
              decoration: BoxDecoration(
                color: _latencyColor(avg).withAlpha(38),
                borderRadius: BorderRadius.circular(4.0),
              ),
              child: Text(
                '${avg.toInt()}ms',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: _latencyColor(avg),
                  fontSize: 9.sp,
                ),
              ),
            ),
          ),
          SizedBox(width: 1.w),
          Expanded(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 1.w, vertical: 0.3.h),
              decoration: BoxDecoration(
                color: _latencyColor(p95).withAlpha(38),
                borderRadius: BorderRadius.circular(4.0),
              ),
              child: Text(
                '${p95.toInt()}ms',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: _latencyColor(p95),
                  fontSize: 9.sp,
                ),
              ),
            ),
          ),
          SizedBox(width: 1.w),
          Expanded(
            child: Text(
              '${q['calls']}',
              textAlign: TextAlign.right,
              style: GoogleFonts.inter(
                color: const Color(0xFF94A3B8),
                fontSize: 9.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
