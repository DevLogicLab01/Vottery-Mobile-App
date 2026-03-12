import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../services/redis_cache_service.dart';

class CacheKeyDistributionPanelWidget extends StatelessWidget {
  const CacheKeyDistributionPanelWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final distribution = RedisCacheService.instance.getKeyDistribution();
    final total = distribution.values.fold(0, (a, b) => a + b);
    final colors = {
      'leaderboard': const Color(0xFF6366F1),
      'creator': const Color(0xFF10B981),
      'election': const Color(0xFFF59E0B),
      'user': const Color(0xFF3B82F6),
      'other': const Color(0xFF8B5CF6),
    };
    final sections = distribution.entries.map((e) {
      final pct = total == 0 ? 0.0 : (e.value / total) * 100;
      return PieChartSectionData(
        value: pct == 0 ? 1 : pct,
        color: colors[e.key] ?? Colors.grey,
        title: pct > 5 ? '${pct.toStringAsFixed(0)}%' : '',
        radius: 8.w,
        titleStyle: GoogleFonts.inter(
          fontSize: 9.sp,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      );
    }).toList();

    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2E),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: const Color(0xFF2D2D3F)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Cache Key Distribution',
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            'Total keys: $total',
            style: GoogleFonts.inter(fontSize: 10.sp, color: Colors.white54),
          ),
          SizedBox(height: 2.h),
          SizedBox(
            height: 20.h,
            child: total == 0
                ? Center(
                    child: Text(
                      'No cached keys yet',
                      style: GoogleFonts.inter(
                        fontSize: 11.sp,
                        color: Colors.white38,
                      ),
                    ),
                  )
                : PieChart(
                    PieChartData(
                      sections: sections,
                      centerSpaceRadius: 6.w,
                      sectionsSpace: 2,
                    ),
                  ),
          ),
          SizedBox(height: 2.h),
          Wrap(
            spacing: 2.w,
            runSpacing: 1.h,
            children: distribution.entries.map((e) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: colors[e.key] ?? Colors.grey,
                      shape: BoxShape.circle,
                    ),
                  ),
                  SizedBox(width: 1.w),
                  Text(
                    '${e.key} (${e.value})',
                    style: GoogleFonts.inter(
                      fontSize: 10.sp,
                      color: Colors.white70,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
