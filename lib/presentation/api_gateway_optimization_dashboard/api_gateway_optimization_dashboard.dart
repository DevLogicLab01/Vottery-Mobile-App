import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/api_gateway_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/error_boundary_wrapper.dart';
import '../../widgets/shimmer_skeleton_loader.dart';
import './widgets/circuit_breaker_panel_widget.dart';
import './widgets/failover_tuning_widget.dart';
import './widgets/routing_analytics_widget.dart';
import './widgets/zone_rate_limit_card_widget.dart';

class ApiGatewayOptimizationDashboard extends StatefulWidget {
  const ApiGatewayOptimizationDashboard({super.key});

  @override
  State<ApiGatewayOptimizationDashboard> createState() =>
      _ApiGatewayOptimizationDashboardState();
}

class _ApiGatewayOptimizationDashboardState
    extends State<ApiGatewayOptimizationDashboard>
    with SingleTickerProviderStateMixin {
  final APIGatewayService _gatewayService = APIGatewayService();
  late TabController _tabController;

  bool _isLoading = true;
  Map<String, dynamic> _gatewayOverview = {};
  List<Map<String, dynamic>> _zoneRateLimits = [];
  List<Map<String, dynamic>> _circuitBreakers = [];
  Map<String, dynamic> _routingAnalytics = {};
  Map<String, dynamic> _failoverConfig = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadDashboardData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    try {
      final overview = await _gatewayService.getGatewayOverview();
      final zones = await _gatewayService.getZoneRateLimits();
      final breakers = await _gatewayService.getCircuitBreakers();
      final analytics = await _gatewayService.getRoutingAnalytics();
      final failover = await _gatewayService.getFailoverConfiguration();

      setState(() {
        _gatewayOverview = overview;
        _zoneRateLimits = zones;
        _circuitBreakers = breakers;
        _routingAnalytics = analytics;
        _failoverConfig = failover;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load gateway data: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ErrorBoundaryWrapper(
      screenName: 'ApiGatewayOptimizationDashboard',
      onRetry: _loadDashboardData,
      child: Scaffold(
        backgroundColor: AppTheme.backgroundLight,
        appBar: CustomAppBar(
          title: 'API Gateway Optimization',
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadDashboardData,
            ),
          ],
        ),
        body: _isLoading
            ? _buildLoadingState()
            : Column(
                children: [
                  _buildOverviewHeader(),
                  _buildTabBar(),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildRateLimitingTab(),
                        _buildRoutingAnalyticsTab(),
                        _buildCircuitBreakerTab(),
                        _buildFailoverTuningTab(),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return ListView(
      padding: EdgeInsets.all(4.w),
      children: List.generate(
        3,
        (index) => Padding(
          padding: EdgeInsets.only(bottom: 2.h),
          child: SkeletonCard(height: 20.h, width: double.infinity),
        ),
      ),
    );
  }

  Widget _buildOverviewHeader() {
    final totalRequests = _gatewayOverview['total_requests'] ?? 0;
    final avgLatency = _gatewayOverview['avg_latency_ms'] ?? 0;
    final errorRate = _gatewayOverview['error_rate'] ?? 0.0;
    final activeCircuits = _gatewayOverview['active_circuits'] ?? 0;

    return Container(
      margin: EdgeInsets.all(4.w),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 10.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Gateway Status',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'Total Requests',
                  totalRequests.toString(),
                  Icons.api,
                  Colors.blue,
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: _buildMetricCard(
                  'Avg Latency',
                  '${avgLatency}ms',
                  Icons.speed,
                  Colors.orange,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'Error Rate',
                  '${errorRate.toStringAsFixed(2)}%',
                  Icons.error_outline,
                  errorRate > 5 ? Colors.red : Colors.green,
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: _buildMetricCard(
                  'Active Circuits',
                  activeCircuits.toString(),
                  Icons.electrical_services,
                  Colors.purple,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20.sp),
          SizedBox(width: 2.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: AppTheme.textSecondaryLight,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: color,
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

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        labelColor: AppTheme.primaryLight,
        unselectedLabelColor: AppTheme.textSecondaryLight,
        indicatorColor: AppTheme.primaryLight,
        labelStyle: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600),
        unselectedLabelStyle: TextStyle(fontSize: 12.sp),
        isScrollable: true,
        tabs: const [
          Tab(text: 'Rate Limiting'),
          Tab(text: 'Routing Analytics'),
          Tab(text: 'Circuit Breakers'),
          Tab(text: 'Failover Tuning'),
        ],
      ),
    );
  }

  Widget _buildRateLimitingTab() {
    return ListView(
      padding: EdgeInsets.all(4.w),
      children: [
        Text(
          'Zone-Based Rate Limiting',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimaryLight,
          ),
        ),
        SizedBox(height: 2.h),
        ..._zoneRateLimits.map(
          (zone) => Padding(
            padding: EdgeInsets.only(bottom: 2.h),
            child: ZoneRateLimitCardWidget(
              zone: zone,
              onUpdate: _loadDashboardData,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRoutingAnalyticsTab() {
    return RoutingAnalyticsWidget(
      analytics: _routingAnalytics,
      onRefresh: _loadDashboardData,
    );
  }

  Widget _buildCircuitBreakerTab() {
    return CircuitBreakerPanelWidget(
      circuitBreakers: _circuitBreakers,
      onUpdate: _loadDashboardData,
    );
  }

  Widget _buildFailoverTuningTab() {
    return FailoverTuningWidget(
      configuration: _failoverConfig,
      onUpdate: _loadDashboardData,
    );
  }
}
