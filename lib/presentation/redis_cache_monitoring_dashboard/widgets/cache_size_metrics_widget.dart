import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../services/redis_cache_service.dart';

class CacheSizeMetricsWidget extends StatelessWidget {
  const CacheSizeMetricsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final cache = RedisCacheService.instance;
    final keyCount = cache.keyCount;
    final memBytes = cache.approximateMemoryBytes;
    final memKb = memBytes / 1024;
    final avgKeySize = keyCount == 0 ? 0 : (memBytes / keyCount).round();

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
            'Cache Size Metrics',
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
                child: _buildStat(
                  'Memory Used',
                  memKb < 1024
                      ? '${memKb.toStringAsFixed(1)} KB'
                      : '${(memKb / 1024).toStringAsFixed(2)} MB',
                  const Color(0xFF6366F1),
                  Icons.memory_outlined,
                ),
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: _buildStat(
                  'Keys Count',
                  '$keyCount / 10000',
                  const Color(0xFF10B981),
                  Icons.vpn_key_outlined,
                ),
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: _buildStat(
                  'Avg Key Size',
                  '$avgKeySize B',
                  const Color(0xFFF59E0B),
                  Icons.data_usage_outlined,
                ),
              ),
            ],
          ),
          SizedBox(height: 1.5.h),
          _buildMemoryBar(memKb),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value, Color color, IconData icon) {
    return Container(
      padding: EdgeInsets.all(2.w),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 14.sp),
          SizedBox(height: 0.5.h),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 11.sp,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            label,
            style: GoogleFonts.inter(fontSize: 9.sp, color: Colors.white54),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildMemoryBar(double memKb) {
    final usedMb = memKb / 1024;
    final pct = (usedMb / 100.0).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Memory Usage',
              style: GoogleFonts.inter(fontSize: 10.sp, color: Colors.white54),
            ),
            Text(
              '${(pct * 100).toStringAsFixed(1)}% of 100 MB',
              style: GoogleFonts.inter(fontSize: 10.sp, color: Colors.white54),
            ),
          ],
        ),
        SizedBox(height: 0.5.h),
        ClipRRect(
          borderRadius: BorderRadius.circular(4.0),
          child: LinearProgressIndicator(
            value: pct,
            backgroundColor: Colors.white12,
            valueColor: AlwaysStoppedAnimation<Color>(
              pct > 0.8
                  ? const Color(0xFFEF4444)
                  : pct > 0.6
                  ? const Color(0xFFF59E0B)
                  : const Color(0xFF10B981),
            ),
            minHeight: 8,
          ),
        ),
      ],
    );
  }
}
