import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/system_monitoring_service.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/error_boundary_wrapper.dart';
import '../../widgets/shimmer_skeleton_loader.dart';
import './widgets/bundle_optimization_widget.dart';
import './widgets/image_optimization_widget.dart';
import './widgets/lazy_loading_controls_widget.dart';
import './widgets/performance_dashboard_widget.dart';
import './widgets/performance_header_widget.dart';
import './widgets/screen_load_metrics_widget.dart';
import './widgets/websocket_performance_widget.dart';

class MobileAppPerformanceOptimizationHub extends StatefulWidget {
  const MobileAppPerformanceOptimizationHub({super.key});

  @override
  State<MobileAppPerformanceOptimizationHub> createState() =>
      _MobileAppPerformanceOptimizationHubState();
}

class _MobileAppPerformanceOptimizationHubState
    extends State<MobileAppPerformanceOptimizationHub>
    with SingleTickerProviderStateMixin {
  final SystemMonitoringService _monitoringService =
      SystemMonitoringService.instance;

  late TabController _tabController;
  bool _isLoading = true;
  Map<String, dynamic> _performanceOverview = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _loadPerformanceData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadPerformanceData() async {
    setState(() => _isLoading = true);

    await Future.delayed(const Duration(milliseconds: 800));

    setState(() {
      _performanceOverview = {
        'avg_load_time': 1847,
        'performance_score': 87,
        'critical_alerts': 3,
        'slowest_screens': 12,
      };
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ErrorBoundaryWrapper(
      screenName: 'MobileAppPerformanceOptimizationHub',
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
          title: 'Performance Optimization',
          actions: [
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
            : SingleChildScrollView(
                child: Column(
                  children: [
                    PerformanceHeaderWidget(
                      avgLoadTime: _performanceOverview['avg_load_time'] ?? 0,
                      performanceScore:
                          _performanceOverview['performance_score'] ?? 0,
                      criticalAlerts:
                          _performanceOverview['critical_alerts'] ?? 0,
                    ),
                    _buildTabBar(),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: const [
                          ScreenLoadMetricsWidget(),
                          LazyLoadingControlsWidget(),
                          BundleOptimizationWidget(),
                          ImageOptimizationWidget(),
                          WebsocketPerformanceWidget(),
                          PerformanceDashboardWidget(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        labelColor: AppTheme.primaryLight,
        unselectedLabelColor: AppTheme.textSecondaryLight,
        indicatorColor: AppTheme.primaryLight,
        labelStyle: TextStyle(fontSize: 10.sp, fontWeight: FontWeight.w600),
        isScrollable: true,
        tabs: const [
          Tab(text: 'Screen Load'),
          Tab(text: 'Lazy Loading'),
          Tab(text: 'Bundle'),
          Tab(text: 'Images'),
          Tab(text: 'WebSocket'),
          Tab(text: 'Code Splitting'),
        ],
      ),
    );
  }
}
