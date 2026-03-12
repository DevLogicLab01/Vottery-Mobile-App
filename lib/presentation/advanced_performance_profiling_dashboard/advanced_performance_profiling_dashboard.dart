import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart' as google_fonts;
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/performance_profiling_service.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/error_boundary_wrapper.dart';
import '../../widgets/shimmer_skeleton_loader.dart';
import './widgets/bottleneck_detection_widget.dart';
import './widgets/comparison_reports_widget.dart';
import './widgets/flame_graph_visualization_widget.dart';
import './widgets/optimization_recommendations_widget.dart';
import './widgets/per_screen_metrics_widget.dart';
import './widgets/performance_timeline_widget.dart';
import './widgets/real_time_alert_monitoring_widget.dart';

/// Advanced Performance Profiling Dashboard
/// Per-screen CPU/memory/network monitoring with automated bottleneck detection
class AdvancedPerformanceProfilingDashboard extends StatefulWidget {
  const AdvancedPerformanceProfilingDashboard({super.key});

  @override
  State<AdvancedPerformanceProfilingDashboard> createState() =>
      _AdvancedPerformanceProfilingDashboardState();
}

class _AdvancedPerformanceProfilingDashboardState
    extends State<AdvancedPerformanceProfilingDashboard>
    with SingleTickerProviderStateMixin {
  final PerformanceProfilingService _profilingService =
      PerformanceProfilingService.instance;

  late TabController _tabController;
  bool _isLoading = true;
  bool _isProfilingActive = false;
  Map<String, dynamic> _bottleneckSummary = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 7, vsync: this);
    _loadPerformanceData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    if (_isProfilingActive) {
      _profilingService.stopProfilingSession();
    }
    super.dispose();
  }

  Future<void> _loadPerformanceData() async {
    setState(() => _isLoading = true);

    final summary = await _profilingService.getPerformanceBottleneckSummary(
      hours: 24,
    );

    setState(() {
      _bottleneckSummary = summary;
      _isLoading = false;
    });
  }

  void _toggleProfiling() {
    setState(() {
      _isProfilingActive = !_isProfilingActive;
    });

    if (_isProfilingActive) {
      _profilingService.startProfilingSession();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Performance profiling started'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      _profilingService.stopProfilingSession();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Performance profiling stopped'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ErrorBoundaryWrapper(
      screenName: 'AdvancedPerformanceProfilingDashboard',
      onRetry: _loadPerformanceData,
      child: Scaffold(
        backgroundColor: AppTheme.backgroundLight,
        appBar: CustomAppBar(
          leading: Padding(
            padding: EdgeInsets.only(left: 4.w),
            child: IconButton(
              icon: CustomIconWidget(
                iconName: 'arrow_back',
                size: 6.w,
                color: AppTheme.textPrimaryLight,
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          title: 'Performance Profiling',
          actions: [
            IconButton(
              icon: Icon(
                _isProfilingActive ? Icons.stop_circle : Icons.play_circle,
                size: 6.w,
                color: _isProfilingActive ? Colors.red : Colors.green,
              ),
              onPressed: _toggleProfiling,
            ),
            IconButton(
              icon: CustomIconWidget(
                iconName: 'refresh',
                size: 6.w,
                color: AppTheme.textPrimaryLight,
              ),
              onPressed: _loadPerformanceData,
            ),
            SizedBox(width: 2.w),
          ],
        ),
        body: _isLoading
            ? const SkeletonDashboard()
            : Column(
                children: [
                  _buildPerformanceHeader(),
                  _buildTabBar(),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: const [
                        PerScreenMetricsWidget(),
                        BottleneckDetectionWidget(),
                        OptimizationRecommendationsWidget(),
                        FlameGraphVisualizationWidget(),
                        PerformanceTimelineWidget(),
                        ComparisonReportsWidget(),
                        RealTimeAlertMonitoringWidget(),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildPerformanceHeader() {
    final totalBottlenecks = _bottleneckSummary['total_bottlenecks'] ?? 0;
    final criticalCount = _bottleneckSummary['critical_count'] ?? 0;
    final unresolvedCount = _bottleneckSummary['unresolved_count'] ?? 0;

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              _buildMetricCard(
                icon: Icons.warning,
                label: 'Total Bottlenecks',
                value: totalBottlenecks.toString(),
                color: Colors.orange,
              ),
              SizedBox(width: 2.w),
              _buildMetricCard(
                icon: Icons.error,
                label: 'Critical',
                value: criticalCount.toString(),
                color: Colors.red,
              ),
              SizedBox(width: 2.w),
              _buildMetricCard(
                icon: Icons.pending,
                label: 'Unresolved',
                value: unresolvedCount.toString(),
                color: Colors.blue,
              ),
            ],
          ),
          if (_isProfilingActive) ...[
            SizedBox(height: 2.h),
            Container(
              padding: EdgeInsets.all(2.w),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(color: Colors.green),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.fiber_manual_record,
                    color: Colors.green,
                    size: 4.w,
                  ),
                  SizedBox(width: 2.w),
                  Expanded(
                    child: Text(
                      'Profiling Active - Collecting metrics in real-time',
                      style: TextStyle(
                        fontSize: 10.sp,
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(3.w),
        decoration: BoxDecoration(
          color: color.withAlpha(26),
          borderRadius: BorderRadius.circular(8.0),
          border: Border.all(color: color.withAlpha(51)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 6.w),
            SizedBox(height: 1.h),
            Text(
              value,
              style: google_fonts.GoogleFonts.inter(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            SizedBox(height: 0.5.h),
            Text(
              label,
              style: TextStyle(fontSize: 9.sp, color: Colors.grey.shade700),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: AppTheme.primaryLight,
        unselectedLabelColor: AppTheme.textSecondaryLight,
        indicatorColor: AppTheme.primaryLight,
        isScrollable: true,
        labelStyle: TextStyle(fontSize: 10.sp, fontWeight: FontWeight.w600),
        unselectedLabelStyle: TextStyle(fontSize: 10.sp),
        tabs: const [
          Tab(text: 'Metrics'),
          Tab(text: 'Bottlenecks'),
          Tab(text: 'Recommendations'),
          Tab(text: 'Flame Graph'),
          Tab(text: 'Timeline'),
          Tab(text: 'Comparison'),
          Tab(text: 'Alerts'),
        ],
      ),
    );
  }
}
