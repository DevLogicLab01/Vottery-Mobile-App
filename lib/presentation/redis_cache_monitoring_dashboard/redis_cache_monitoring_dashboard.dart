import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../services/database_query_optimizer.dart';
import '../../services/redis_cache_service.dart';
import './widgets/cache_invalidation_panel_widget.dart';
import './widgets/cache_key_distribution_panel_widget.dart';
import './widgets/cache_size_metrics_widget.dart';
import './widgets/cache_stats_panel_widget.dart';
import './widgets/manual_cache_control_panel_widget.dart';
import './widgets/ttl_monitoring_panel_widget.dart';

class RedisCacheMonitoringDashboard extends StatefulWidget {
  const RedisCacheMonitoringDashboard({super.key});

  @override
  State<RedisCacheMonitoringDashboard> createState() =>
      _RedisCacheMonitoringDashboardState();
}

class _RedisCacheMonitoringDashboardState
    extends State<RedisCacheMonitoringDashboard> {
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cache = RedisCacheService.instance;
    final metrics = DatabaseQueryOptimizer.instance.getPerformanceMetrics();

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E2E),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Redis Cache Monitor',
          style: GoogleFonts.inter(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        actions: [
          Container(
            margin: EdgeInsets.only(right: 3.w),
            padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
            decoration: BoxDecoration(
              color: cache.isAvailable
                  ? const Color(0xFF10B981).withAlpha(51)
                  : const Color(0xFFEF4444).withAlpha(51),
              borderRadius: BorderRadius.circular(20.0),
              border: Border.all(
                color: cache.isAvailable
                    ? const Color(0xFF10B981)
                    : const Color(0xFFEF4444),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: cache.isAvailable
                        ? const Color(0xFF10B981)
                        : const Color(0xFFEF4444),
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: 1.w),
                Text(
                  cache.isAvailable ? 'Connected' : 'Offline',
                  style: GoogleFonts.inter(
                    fontSize: 9.sp,
                    color: cache.isAvailable
                        ? const Color(0xFF10B981)
                        : const Color(0xFFEF4444),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white70),
            onPressed: () => setState(() {}),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF3B82F6)],
                ),
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Row(
                children: [
                  const Icon(Icons.speed, color: Colors.white, size: 24),
                  SizedBox(width: 3.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Redis Caching Layer Active',
                          style: GoogleFonts.inter(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          '5-min TTL • Leaderboards • Analytics • Elections',
                          style: GoogleFonts.inter(
                            fontSize: 10.sp,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${(metrics['cache_hit_rate'] as double).toStringAsFixed(1)}%',
                        style: GoogleFonts.inter(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Hit Rate',
                        style: GoogleFonts.inter(
                          fontSize: 9.sp,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 2.h),
            const CacheStatsPanelWidget(),
            SizedBox(height: 2.h),
            const CacheSizeMetricsWidget(),
            SizedBox(height: 2.h),
            const CacheKeyDistributionPanelWidget(),
            SizedBox(height: 2.h),
            const TtlMonitoringPanelWidget(),
            SizedBox(height: 2.h),
            const CacheInvalidationPanelWidget(),
            SizedBox(height: 2.h),
            const ManualCacheControlPanelWidget(),
            SizedBox(height: 3.h),
          ],
        ),
      ),
    );
  }
}
