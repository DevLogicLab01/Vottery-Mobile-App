import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import './widgets/api_response_correlation_panel_widget.dart';
import './widgets/battery_impact_panel_widget.dart';
import './widgets/frame_rate_panel_widget.dart';
import './widgets/memory_usage_panel_widget.dart';
import './widgets/optimization_recommendations_panel_widget.dart';
import './widgets/screen_load_times_panel_widget.dart';

class FlutterClientSidePerformanceProfilingDashboard extends StatefulWidget {
  const FlutterClientSidePerformanceProfilingDashboard({super.key});

  @override
  State<FlutterClientSidePerformanceProfilingDashboard> createState() =>
      _FlutterClientSidePerformanceProfilingDashboardState();
}

class _FlutterClientSidePerformanceProfilingDashboardState
    extends State<FlutterClientSidePerformanceProfilingDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static const List<Map<String, dynamic>> _tabs = [
    {'label': 'Load Times', 'icon': Icons.timer_outlined},
    {'label': 'API Correlation', 'icon': Icons.api},
    {'label': 'Memory', 'icon': Icons.memory},
    {'label': 'Frame Rate', 'icon': Icons.speed},
    {'label': 'Battery', 'icon': Icons.battery_charging_full},
    {'label': 'Recommendations', 'icon': Icons.auto_fix_high},
  ];

  static const List<Map<String, dynamic>> _overviewMetrics = [
    {
      'label': 'Avg Load Time',
      'value': '1.6s',
      'target': '< 2s',
      'status': 'good',
      'icon': Icons.timer,
    },
    {
      'label': 'Memory Usage',
      'value': '42MB',
      'target': '< 50MB',
      'status': 'good',
      'icon': Icons.memory,
    },
    {
      'label': 'Frame Rate',
      'value': '52 FPS',
      'target': '60 FPS',
      'status': 'warning',
      'icon': Icons.speed,
    },
    {
      'label': 'Battery Drain',
      'value': '2.9%/min',
      'target': '< 2%/min',
      'status': 'warning',
      'icon': Icons.battery_alert,
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'good':
        return const Color(0xFF22C55E);
      case 'warning':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFFEF4444);
    }
  }

  @override
  Widget build(BuildContext context) {
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
              'Flutter Performance Profiling',
              style: GoogleFonts.inter(
                fontSize: 13.sp,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            Text(
              'Datadog RUM Integration',
              style: GoogleFonts.inter(fontSize: 9.sp, color: Colors.white54),
            ),
          ],
        ),
        actions: [
          Container(
            margin: EdgeInsets.only(right: 2.w),
            padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
            decoration: BoxDecoration(
              color: const Color(0xFF22C55E).withAlpha(51),
              borderRadius: BorderRadius.circular(8.0),
              border: Border.all(color: const Color(0xFF22C55E).withAlpha(102)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Color(0xFF22C55E),
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: 1.w),
                Text(
                  'RUM Active',
                  style: GoogleFonts.inter(
                    fontSize: 9.sp,
                    color: const Color(0xFF22C55E),
                  ),
                ),
              ],
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(6.h),
          child: Container(
            color: const Color(0xFF1E293B),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              indicatorColor: const Color(0xFF3B82F6),
              indicatorWeight: 2,
              labelColor: const Color(0xFF3B82F6),
              unselectedLabelColor: Colors.white54,
              labelStyle: GoogleFonts.inter(
                fontSize: 10.sp,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: GoogleFonts.inter(fontSize: 10.sp),
              tabs: _tabs
                  .map(
                    (tab) => Tab(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(tab['icon'] as IconData, size: 14),
                          SizedBox(width: 1.w),
                          Text(tab['label'] as String),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          _buildOverviewHeader(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [
                ScreenLoadTimesPanelWidget(),
                ApiResponseCorrelationPanelWidget(),
                MemoryUsagePanelWidget(),
                FrameRatePanelWidget(),
                BatteryImpactPanelWidget(),
                OptimizationRecommendationsPanelWidget(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewHeader() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.5.h),
      decoration: const BoxDecoration(
        color: Color(0xFF1E293B),
        border: Border(bottom: BorderSide(color: Colors.white12)),
      ),
      child: Row(
        children: _overviewMetrics
            .map(
              (metric) => Expanded(
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: 0.5.w),
                  padding: EdgeInsets.symmetric(
                    horizontal: 1.5.w,
                    vertical: 1.h,
                  ),
                  decoration: BoxDecoration(
                    color: _statusColor(metric['status']).withAlpha(20),
                    borderRadius: BorderRadius.circular(10.0),
                    border: Border.all(
                      color: _statusColor(metric['status']).withAlpha(77),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            metric['icon'] as IconData,
                            color: _statusColor(metric['status']),
                            size: 12,
                          ),
                          SizedBox(width: 0.5.w),
                          Expanded(
                            child: Text(
                              metric['label'] as String,
                              style: GoogleFonts.inter(
                                fontSize: 8.sp,
                                color: Colors.white54,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 0.3.h),
                      Text(
                        metric['value'] as String,
                        style: GoogleFonts.inter(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w700,
                          color: _statusColor(metric['status']),
                        ),
                      ),
                      Text(
                        metric['target'] as String,
                        style: GoogleFonts.inter(
                          fontSize: 8.sp,
                          color: Colors.white38,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}
