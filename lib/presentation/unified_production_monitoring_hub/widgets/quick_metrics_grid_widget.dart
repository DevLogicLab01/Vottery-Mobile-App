import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

class QuickMetricsGridWidget extends StatelessWidget {
  final double apiLatencyP95;
  final int dbConnectionsCurrent;
  final int dbConnectionsMax;
  final double cacheHitRate;
  final double adFillRate;

  const QuickMetricsGridWidget({
    super.key,
    required this.apiLatencyP95,
    required this.dbConnectionsCurrent,
    required this.dbConnectionsMax,
    required this.cacheHitRate,
    required this.adFillRate,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 2.w,
      mainAxisSpacing: 1.h,
      childAspectRatio: 1.6,
      children: [
        _MetricCard(
          icon: Icons.speed,
          label: 'API Latency p95',
          value: '${apiLatencyP95.toStringAsFixed(0)}ms',
          target: '< 100ms',
          isGood: apiLatencyP95 < 100,
          color: const Color(0xFF3B82F6),
        ),
        _MetricCard(
          icon: Icons.storage,
          label: 'DB Connections',
          value: '$dbConnectionsCurrent/$dbConnectionsMax',
          target: 'Max $dbConnectionsMax',
          isGood: dbConnectionsCurrent < dbConnectionsMax * 0.8,
          color: const Color(0xFF8B5CF6),
        ),
        _MetricCard(
          icon: Icons.cached,
          label: 'Cache Hit Rate',
          value: '${cacheHitRate.toStringAsFixed(0)}%',
          target: '> 80%',
          isGood: cacheHitRate >= 80,
          color: const Color(0xFF10B981),
        ),
        _MetricCard(
          icon: Icons.ads_click,
          label: 'Ad Fill Rate',
          value: '${adFillRate.toStringAsFixed(0)}%',
          target: '> 70%',
          isGood: adFillRate >= 70,
          color: const Color(0xFFF59E0B),
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String target;
  final bool isGood;
  final Color color;

  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.target,
    required this.isGood,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 4.w),
              const Spacer(),
              Container(
                width: 2.w,
                height: 2.w,
                decoration: BoxDecoration(
                  color: isGood
                      ? const Color(0xFF22C55E)
                      : const Color(0xFFEF4444),
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 9.sp,
                  color: const Color(0xFF6B7280),
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
              Text(
                'Target: $target',
                style: GoogleFonts.inter(
                  fontSize: 8.sp,
                  color: const Color(0xFF9CA3AF),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
