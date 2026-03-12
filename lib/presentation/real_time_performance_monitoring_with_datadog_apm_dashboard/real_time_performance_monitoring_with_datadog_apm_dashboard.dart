import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import './widgets/alert_history_panel_widget.dart';
import './widgets/cache_performance_panel_widget.dart';
import './widgets/connection_pool_panel_widget.dart';
import './widgets/query_latency_panel_widget.dart';
import './widgets/sla_compliance_panel_widget.dart';

class RealTimePerformanceMonitoringWithDatadogApmDashboard
    extends StatefulWidget {
  const RealTimePerformanceMonitoringWithDatadogApmDashboard({super.key});

  @override
  State<RealTimePerformanceMonitoringWithDatadogApmDashboard> createState() =>
      _RealTimePerformanceMonitoringWithDatadogApmDashboardState();
}

class _RealTimePerformanceMonitoringWithDatadogApmDashboardState
    extends State<RealTimePerformanceMonitoringWithDatadogApmDashboard> {
  int _selectedTab = 0;

  final List<Map<String, dynamic>> _statusCards = [
    {
      'label': 'Query P95',
      'value': '87ms',
      'target': '< 100ms',
      'ok': true,
      'icon': Icons.speed,
    },
    {
      'label': 'Cache Hit',
      'value': '87%',
      'target': '> 85%',
      'ok': true,
      'icon': Icons.memory,
    },
    {
      'label': 'Pool Util',
      'value': '42%',
      'target': '< 80%',
      'ok': true,
      'icon': Icons.hub,
    },
    {
      'label': 'SLA Score',
      'value': '99.95%',
      'target': '> 99.9%',
      'ok': true,
      'icon': Icons.verified_outlined,
    },
  ];

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
              'Datadog APM Dashboard',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              'Real-Time Performance Monitoring',
              style: GoogleFonts.inter(
                color: const Color(0xFF94A3B8),
                fontSize: 9.sp,
              ),
            ),
          ],
        ),
        actions: [
          Container(
            margin: EdgeInsets.only(right: 3.w),
            padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
            decoration: BoxDecoration(
              color: const Color(0xFF22C55E).withAlpha(38),
              borderRadius: BorderRadius.circular(6.0),
              border: Border.all(color: const Color(0xFF22C55E).withAlpha(77)),
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
                  'Live',
                  style: GoogleFonts.inter(
                    color: const Color(0xFF22C55E),
                    fontSize: 10.sp,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Status overview cards
          Container(
            color: const Color(0xFF1E293B),
            padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.5.h),
            child: Row(
              children: _statusCards
                  .map((card) => Expanded(child: _statusCard(card)))
                  .toList(),
            ),
          ),
          // Tab bar
          Container(
            color: const Color(0xFF1E293B),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _tabItem(0, 'Latency'),
                  _tabItem(1, 'Cache'),
                  _tabItem(2, 'Pool'),
                  _tabItem(3, 'SLA'),
                  _tabItem(4, 'Alerts'),
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

  Widget _statusCard(Map<String, dynamic> card) {
    final ok = card['ok'] as bool;
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 1.w),
      padding: EdgeInsets.symmetric(vertical: 1.h, horizontal: 1.w),
      decoration: BoxDecoration(
        color: ok
            ? const Color(0xFF22C55E).withAlpha(20)
            : const Color(0xFFEF4444).withAlpha(20),
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(
          color: ok
              ? const Color(0xFF22C55E).withAlpha(64)
              : const Color(0xFFEF4444).withAlpha(64),
        ),
      ),
      child: Column(
        children: [
          Icon(
            card['icon'] as IconData,
            color: ok ? const Color(0xFF22C55E) : const Color(0xFFEF4444),
            size: 16,
          ),
          SizedBox(height: 0.3.h),
          Text(
            card['value'] as String,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 11.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            card['label'] as String,
            style: GoogleFonts.inter(
              color: const Color(0xFF94A3B8),
              fontSize: 8.sp,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
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
        return const QueryLatencyPanelWidget();
      case 1:
        return const CachePerformancePanelWidget();
      case 2:
        return const ConnectionPoolPanelWidget();
      case 3:
        return const SlaCompliancePanelWidget();
      case 4:
        return const AlertHistoryPanelWidget();
      default:
        return const QueryLatencyPanelWidget();
    }
  }
}
