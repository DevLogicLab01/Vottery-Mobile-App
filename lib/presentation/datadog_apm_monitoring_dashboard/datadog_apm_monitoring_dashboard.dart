import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import './widgets/custom_spans_widget.dart';
import './widgets/distributed_tracing_widget.dart';
import './widgets/error_rate_tracking_widget.dart';
import './widgets/flame_graph_widget.dart';
import './widgets/mobile_analytics_widget.dart';
import './widgets/performance_metrics_widget.dart';
import './widgets/predictive_scaling_widget.dart';
import './widgets/service_dependency_map_widget.dart';
import './widgets/heatmap_visualization_widget.dart';
import './widgets/percentile_charts_widget.dart';
import './widgets/query_analysis_panel_widget.dart';

class DatadogApmMonitoringDashboard extends StatefulWidget {
  const DatadogApmMonitoringDashboard({super.key});

  @override
  State<DatadogApmMonitoringDashboard> createState() =>
      _DatadogApmMonitoringDashboardState();
}

class _DatadogApmMonitoringDashboardState
    extends State<DatadogApmMonitoringDashboard> {
  int _selectedTabIndex = 0;

  final List<Map<String, dynamic>> _tabs = [
    {'title': 'Overview', 'icon': Icons.dashboard},
    {'title': 'Tracing', 'icon': Icons.timeline},
    {'title': 'Dependencies', 'icon': Icons.account_tree},
    {'title': 'Performance', 'icon': Icons.speed},
    {'title': 'Mobile', 'icon': Icons.phone_android},
    {'title': 'Bottlenecks', 'icon': Icons.thermostat},
    {'title': 'Query Analysis', 'icon': Icons.storage},
    {'title': 'Percentiles', 'icon': Icons.bar_chart},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: const Color(0xFF632CA6),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Datadog APM Monitoring',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              'Real-time observability across 200+ endpoints',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12.sp,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              setState(() {});
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          _buildStatusOverview(),
          _buildTabBar(),
          Expanded(child: _buildTabContent()),
        ],
      ),
    );
  }

  Widget _buildStatusOverview() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(3.w),
      decoration: const BoxDecoration(
        color: Color(0xFF632CA6),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20.0),
          bottomRight: Radius.circular(20.0),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatusCard(
              'System Health',
              '98.5%',
              Icons.health_and_safety,
              Colors.green,
            ),
          ),
          SizedBox(width: 2.w),
          Expanded(
            child: _buildStatusCard(
              'Active Traces',
              '1,247',
              Icons.show_chart,
              Colors.blue,
            ),
          ),
          SizedBox(width: 2.w),
          Expanded(
            child: _buildStatusCard(
              'Alerts',
              '3',
              Icons.warning_amber,
              Colors.orange,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(2.w),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(38),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20.sp),
          SizedBox(height: 0.5.h),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 11.sp,
              fontWeight: FontWeight.w400,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 1.h),
      height: 6.h,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 3.w),
        itemCount: _tabs.length,
        itemBuilder: (context, index) {
          final isSelected = _selectedTabIndex == index;
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedTabIndex = index;
              });
            },
            child: Container(
              margin: EdgeInsets.only(right: 2.w),
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF632CA6) : Colors.white,
                borderRadius: BorderRadius.circular(20.0),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF632CA6)
                      : Colors.grey.shade300,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _tabs[index]['icon'],
                    color: isSelected ? Colors.white : Colors.grey[700],
                    size: 16.sp,
                  ),
                  SizedBox(width: 1.w),
                  Text(
                    _tabs[index]['title'],
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey[700],
                      fontSize: 13.sp,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_selectedTabIndex) {
      case 0:
        return _buildOverviewTab();
      case 1:
        return _buildTracingTab();
      case 2:
        return const SingleChildScrollView(
          padding: EdgeInsets.all(16.0),
          child: ServiceDependencyMapWidget(),
        );
      case 3:
        return const SingleChildScrollView(
          padding: EdgeInsets.all(16.0),
          child: PerformanceMetricsWidget(),
        );
      case 4:
        return const SingleChildScrollView(
          padding: EdgeInsets.all(16.0),
          child: MobileAnalyticsWidget(),
        );
      case 5:
        return const SingleChildScrollView(
          padding: EdgeInsets.all(16.0),
          child: HeatmapVisualizationWidget(),
        );
      case 6:
        return const SingleChildScrollView(
          padding: EdgeInsets.all(16.0),
          child: QueryAnalysisPanelWidget(),
        );
      case 7:
        return const SingleChildScrollView(
          padding: EdgeInsets.all(16.0),
          child: PercentileChartsWidget(),
        );
      default:
        return const SizedBox();
    }
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(3.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ErrorRateTrackingWidget(),
          SizedBox(height: 2.h),
          const CustomSpansWidget(),
          SizedBox(height: 2.h),
          const PredictiveScalingWidget(),
        ],
      ),
    );
  }

  Widget _buildTracingTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(3.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const FlameGraphWidget(),
          SizedBox(height: 2.h),
          const DistributedTracingWidget(),
        ],
      ),
    );
  }
}
