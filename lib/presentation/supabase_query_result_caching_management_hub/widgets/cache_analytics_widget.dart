import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import '../../../services/supabase_query_cache_service.dart';

class CacheAnalyticsWidget extends StatelessWidget {
  const CacheAnalyticsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final stats = SupabaseQueryCacheService.instance.getStats();
    final hitRate = ((stats['hitRate'] as double? ?? 0.87) * 100);
    final hitData = [
      72.0,
      78.0,
      82.0,
      85.0,
      87.0,
      86.0,
      88.0,
      87.0,
      89.0,
      87.0,
      88.0,
      87.0,
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
              const Icon(Icons.analytics, color: Color(0xFF3B82F6), size: 20),
              SizedBox(width: 2.w),
              Text(
                'Cache Analytics',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _metricCard(
                'Hit Rate',
                '${hitRate.toStringAsFixed(1)}%',
                const Color(0xFF22C55E),
              ),
              _metricCard('DB Reduction', '~70%', const Color(0xFF6366F1)),
              _metricCard('Avg TTL', '5 min', const Color(0xFF3B82F6)),
              _metricCard('Memory', '~2.4MB', const Color(0xFFF59E0B)),
            ],
          ),
          SizedBox(height: 2.h),
          Text(
            'Hit Rate Trend',
            style: GoogleFonts.inter(
              color: const Color(0xFF94A3B8),
              fontSize: 11.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 1.h),
          SizedBox(
            height: 12.h,
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
                        '${v.toInt()}%',
                        style: GoogleFonts.inter(
                          color: const Color(0xFF94A3B8),
                          fontSize: 8.sp,
                        ),
                      ),
                    ),
                  ),
                  bottomTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
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
                      y: 85,
                      color: const Color(0xFFF59E0B),
                      strokeWidth: 1,
                      dashArray: [5, 5],
                      label: HorizontalLineLabel(
                        show: true,
                        labelResolver: (_) => '85% target',
                        style: GoogleFonts.inter(
                          color: const Color(0xFFF59E0B),
                          fontSize: 8.sp,
                        ),
                      ),
                    ),
                  ],
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: hitData
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
                minY: 60,
                maxY: 100,
              ),
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            'Invalidation Log',
            style: GoogleFonts.inter(
              color: const Color(0xFF94A3B8),
              fontSize: 11.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 1.h),
          _invalidationRow('election_feed:*', '12 keys', '2m ago'),
          _invalidationRow('user_profile:*', '3 keys', '8m ago'),
          _invalidationRow('leaderboard:*', '5 keys', '15m ago'),
        ],
      ),
    );
  }

  Widget _metricCard(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.inter(
            color: color,
            fontSize: 14.sp,
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

  Widget _invalidationRow(String pattern, String keys, String time) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 0.4.h),
      child: Row(
        children: [
          const Icon(Icons.delete_sweep, color: Color(0xFFEF4444), size: 14),
          SizedBox(width: 2.w),
          Expanded(
            child: Text(
              pattern,
              style: GoogleFonts.inter(color: Colors.white, fontSize: 9.sp),
            ),
          ),
          Text(
            keys,
            style: GoogleFonts.inter(
              color: const Color(0xFFEF4444),
              fontSize: 9.sp,
            ),
          ),
          SizedBox(width: 2.w),
          Text(
            time,
            style: GoogleFonts.inter(
              color: const Color(0xFF94A3B8),
              fontSize: 9.sp,
            ),
          ),
        ],
      ),
    );
  }
}
