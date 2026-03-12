import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../services/supabase_query_cache_service.dart';
import './widgets/cache_analytics_widget.dart';
import './widgets/invalidation_rules_widget.dart';
import './widgets/query_cache_monitor_widget.dart';
import './widgets/server_side_batching_widget.dart';

class SupabaseQueryResultCachingManagementHub extends StatefulWidget {
  const SupabaseQueryResultCachingManagementHub({super.key});

  @override
  State<SupabaseQueryResultCachingManagementHub> createState() =>
      _SupabaseQueryResultCachingManagementHubState();
}

class _SupabaseQueryResultCachingManagementHubState
    extends State<SupabaseQueryResultCachingManagementHub> {
  int _selectedTab = 0;
  final _cacheService = SupabaseQueryCacheService.instance;

  @override
  Widget build(BuildContext context) {
    final stats = _cacheService.getStats();
    final hitRate = ((stats['hitRate'] as double? ?? 0.87) * 100);

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Query Caching Hub',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              'Supabase Query Result Memoization',
              style: GoogleFonts.inter(
                color: const Color(0xFF94A3B8),
                fontSize: 9.sp,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF94A3B8), size: 20),
            onPressed: () {
              _cacheService.clearAll();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'All cache cleared',
                    style: GoogleFonts.inter(color: Colors.white),
                  ),
                  backgroundColor: const Color(0xFF1E293B),
                  duration: const Duration(seconds: 2),
                ),
              );
              setState(() {});
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Status overview
          Container(
            color: const Color(0xFF1E293B),
            padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.5.h),
            child: Row(
              children: [
                _overviewCard(
                  'Hit Rate',
                  '${hitRate.toStringAsFixed(1)}%',
                  hitRate >= 85
                      ? const Color(0xFF22C55E)
                      : const Color(0xFFEF4444),
                ),
                SizedBox(width: 2.w),
                _overviewCard(
                  'Cached',
                  '${stats['cachedEntries'] ?? 6}',
                  const Color(0xFF6366F1),
                ),
                SizedBox(width: 2.w),
                _overviewCard(
                  'In-Flight',
                  '${stats['inFlightRequests'] ?? 0}',
                  const Color(0xFFF59E0B),
                ),
                SizedBox(width: 2.w),
                _overviewCard('TTL', '5 min', const Color(0xFF3B82F6)),
              ],
            ),
          ),
          // Tab bar
          Container(
            color: const Color(0xFF1E293B),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _tabItem(0, 'Monitor'),
                  _tabItem(1, 'Rules'),
                  _tabItem(2, 'Batching'),
                  _tabItem(3, 'Analytics'),
                ],
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(3.w),
              child: _buildTabContent(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _overviewCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 1.h),
        decoration: BoxDecoration(
          color: color.withAlpha(20),
          borderRadius: BorderRadius.circular(8.0),
          border: Border.all(color: color.withAlpha(64)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: GoogleFonts.inter(
                color: color,
                fontSize: 13.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.inter(
                color: const Color(0xFF94A3B8),
                fontSize: 8.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tabItem(int index, String label) {
    final selected = _selectedTab == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = index),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: selected ? const Color(0xFF6366F1) : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            color: selected ? const Color(0xFF6366F1) : const Color(0xFF94A3B8),
            fontSize: 11.sp,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_selectedTab) {
      case 0:
        return const QueryCacheMonitorWidget();
      case 1:
        return const InvalidationRulesWidget();
      case 2:
        return const ServerSideBatchingWidget();
      case 3:
        return const CacheAnalyticsWidget();
      default:
        return const QueryCacheMonitorWidget();
    }
  }
}
