import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../services/database_query_optimizer.dart';

class CacheStatsPanelWidget extends StatelessWidget {
  const CacheStatsPanelWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final dbMetrics = DatabaseQueryOptimizer.instance.getPerformanceMetrics();
    final hitRate = (dbMetrics['cache_hit_rate'] as double).clamp(0.0, 100.0);
    final targetMet = hitRate >= 70.0;

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
            'Cache Performance',
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'Total Requests',
                  '${dbMetrics['total_requests']}',
                  const Color(0xFF6366F1),
                  Icons.analytics_outlined,
                ),
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: _buildMetricCard(
                  'Cache Hits',
                  '${dbMetrics['cache_hit_count']}',
                  const Color(0xFF10B981),
                  Icons.check_circle_outline,
                ),
              ),
            ],
          ),
          SizedBox(height: 1.5.h),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'Cache Misses',
                  '${dbMetrics['cache_miss_count']}',
                  const Color(0xFFEF4444),
                  Icons.cancel_outlined,
                ),
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: _buildMetricCard(
                  'DB Queries',
                  '${dbMetrics['database_query_count']}',
                  const Color(0xFFF59E0B),
                  Icons.storage_outlined,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          _buildHitRateGauge(hitRate, targetMet),
        ],
      ),
    );
  }

  Widget _buildMetricCard(
    String label,
    String value,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: EdgeInsets.all(2.w),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: color.withAlpha(77)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 16.sp),
          SizedBox(height: 0.5.h),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            label,
            style: GoogleFonts.inter(fontSize: 10.sp, color: Colors.white54),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildHitRateGauge(double hitRate, bool targetMet) {
    return Container(
      padding: EdgeInsets.all(2.w),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D3F),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 12.w,
            height: 12.w,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: hitRate / 100,
                  backgroundColor: Colors.white12,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    targetMet
                        ? const Color(0xFF10B981)
                        : const Color(0xFFF59E0B),
                  ),
                  strokeWidth: 6,
                ),
                Text(
                  '${hitRate.toStringAsFixed(0)}%',
                  style: GoogleFonts.inter(
                    fontSize: 9.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cache Hit Rate',
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                Text(
                  targetMet
                      ? '✅ Target 70% achieved!'
                      : '⚠️ Target: 70% (current: ${hitRate.toStringAsFixed(1)}%)',
                  style: GoogleFonts.inter(
                    fontSize: 10.sp,
                    color: targetMet
                        ? const Color(0xFF10B981)
                        : const Color(0xFFF59E0B),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
