import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/system_monitoring_service.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/error_boundary_wrapper.dart';
import '../../widgets/shimmer_skeleton_loader.dart';
import './widgets/api_health_score_widget.dart';
import './widgets/bottleneck_detection_widget.dart';
import './widgets/caching_strategy_widget.dart';
import './widgets/database_monitoring_widget.dart';
import './widgets/endpoint_monitoring_widget.dart';
import './widgets/performance_alerts_widget.dart';

class ApiPerformanceOptimizationDashboard extends StatefulWidget {
  const ApiPerformanceOptimizationDashboard({super.key});

  @override
  State<ApiPerformanceOptimizationDashboard> createState() =>
      _ApiPerformanceOptimizationDashboardState();
}

class _ApiPerformanceOptimizationDashboardState
    extends State<ApiPerformanceOptimizationDashboard>
    with SingleTickerProviderStateMixin {
  final SystemMonitoringService _monitoringService =
      SystemMonitoringService.instance;

  late TabController _tabController;
  bool _isLoading = true;
  bool _autoRefreshEnabled = true;
  Timer? _refreshTimer;

  Map<String, dynamic> _apiHealthScore = {};
  List<Map<String, dynamic>> _endpointMetrics = [];
  List<Map<String, dynamic>> _bottlenecks = [];
  List<Map<String, dynamic>> _cachingRecommendations = [];
  List<Map<String, dynamic>> _performanceAlerts = [];
  Map<String, dynamic> _databaseMetrics = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadPerformanceData();
    _setupAutoRefresh();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _setupAutoRefresh() {
    if (_autoRefreshEnabled) {
      _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
        if (mounted) {
          _loadPerformanceData(silent: true);
        }
      });
    }
  }

  Future<void> _loadPerformanceData({bool silent = false}) async {
    if (!silent) {
      setState(() => _isLoading = true);
    }

    try {
      final results = await Future.wait([
        _loadAPIHealthScore(),
        _loadEndpointMetrics(),
        _loadBottlenecks(),
        _loadCachingRecommendations(),
        _loadPerformanceAlerts(),
        _loadDatabaseMetrics(),
      ]);

      if (mounted) {
        setState(() {
          _apiHealthScore = results[0] as Map<String, dynamic>;
          _endpointMetrics = results[1] as List<Map<String, dynamic>>;
          _bottlenecks = results[2] as List<Map<String, dynamic>>;
          _cachingRecommendations = results[3] as List<Map<String, dynamic>>;
          _performanceAlerts = results[4] as List<Map<String, dynamic>>;
          _databaseMetrics = results[5] as Map<String, dynamic>;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Load performance data error: $e');
      if (mounted && !silent) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<Map<String, dynamic>> _loadAPIHealthScore() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return {
      'overall_score': 87.5,
      'avg_response_time': 245,
      'error_rate': 0.8,
      'optimization_opportunities': 12,
      'uptime_percentage': 99.7,
    };
  }

  Future<List<Map<String, dynamic>>> _loadEndpointMetrics() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return [
      {
        'endpoint': '/api/v1/lottery/cast-vote',
        'avg_response_time': 187,
        'p50': 145,
        'p95': 320,
        'p99': 580,
        'requests_per_min': 1250,
        'error_rate': 0.3,
        'status': 'healthy',
      },
      {
        'endpoint': '/api/v1/gamification/rewards',
        'avg_response_time': 412,
        'p50': 380,
        'p95': 650,
        'p99': 920,
        'requests_per_min': 890,
        'error_rate': 1.2,
        'status': 'warning',
      },
      {
        'endpoint': '/api/v1/elections/results',
        'avg_response_time': 156,
        'p50': 120,
        'p95': 280,
        'p99': 450,
        'requests_per_min': 2100,
        'error_rate': 0.1,
        'status': 'healthy',
      },
      {
        'endpoint': '/api/v1/audit/logs',
        'avg_response_time': 678,
        'p50': 590,
        'p95': 1200,
        'p99': 1850,
        'requests_per_min': 340,
        'error_rate': 2.5,
        'status': 'critical',
      },
    ];
  }

  Future<List<Map<String, dynamic>>> _loadBottlenecks() async {
    await Future.delayed(const Duration(milliseconds: 350));
    return [
      {
        'type': 'slow_query',
        'endpoint': '/api/v1/audit/logs',
        'query': 'SELECT * FROM cryptographic_audit_logs WHERE...',
        'avg_execution_time': 1240,
        'frequency': 340,
        'root_cause': 'Missing index on timestamp column',
        'recommendation': 'Add composite index on (timestamp, user_id)',
        'severity': 'high',
      },
      {
        'type': 'n_plus_one',
        'endpoint': '/api/v1/gamification/rewards',
        'query': 'Fetching user badges in loop',
        'avg_execution_time': 380,
        'frequency': 890,
        'root_cause': 'Sequential badge queries per user',
        'recommendation': 'Use JOIN or batch query for badges',
        'severity': 'medium',
      },
      {
        'type': 'large_payload',
        'endpoint': '/api/v1/elections/results',
        'query': 'Returning full election data',
        'avg_execution_time': 156,
        'frequency': 2100,
        'root_cause': 'Unnecessary fields in response',
        'recommendation': 'Implement field selection/pagination',
        'severity': 'low',
      },
    ];
  }

  Future<List<Map<String, dynamic>>> _loadCachingRecommendations() async {
    await Future.delayed(const Duration(milliseconds: 320));
    return [
      {
        'endpoint': '/api/v1/elections/results',
        'cache_type': 'Redis',
        'ttl_seconds': 300,
        'hit_rate_projection': 78.5,
        'latency_reduction': 65,
        'cost_savings': 240,
        'priority': 'high',
      },
      {
        'endpoint': '/api/v1/gamification/leaderboard',
        'cache_type': 'In-Memory',
        'ttl_seconds': 60,
        'hit_rate_projection': 92.3,
        'latency_reduction': 85,
        'cost_savings': 180,
        'priority': 'high',
      },
      {
        'endpoint': '/api/v1/lottery/draw-history',
        'cache_type': 'CDN',
        'ttl_seconds': 3600,
        'hit_rate_projection': 95.8,
        'latency_reduction': 90,
        'cost_savings': 320,
        'priority': 'medium',
      },
    ];
  }

  Future<List<Map<String, dynamic>>> _loadPerformanceAlerts() async {
    await Future.delayed(const Duration(milliseconds: 280));
    return [
      {
        'alert_type': 'threshold_exceeded',
        'endpoint': '/api/v1/audit/logs',
        'metric': 'avg_response_time',
        'threshold': 500,
        'current_value': 678,
        'severity': 'critical',
        'triggered_at': DateTime.now().subtract(const Duration(minutes: 12)),
        'escalation_status': 'pending',
      },
      {
        'alert_type': 'error_rate_spike',
        'endpoint': '/api/v1/gamification/rewards',
        'metric': 'error_rate',
        'threshold': 1.0,
        'current_value': 1.2,
        'severity': 'warning',
        'triggered_at': DateTime.now().subtract(const Duration(minutes: 5)),
        'escalation_status': 'acknowledged',
      },
    ];
  }

  Future<Map<String, dynamic>> _loadDatabaseMetrics() async {
    await Future.delayed(const Duration(milliseconds: 360));
    return {
      'connection_pool_usage': 67.5,
      'slow_queries_count': 23,
      'missing_indexes': 5,
      'table_bloat_percentage': 12.3,
      'index_recommendations': [
        {
          'table': 'cryptographic_audit_logs',
          'columns': ['timestamp', 'user_id'],
          'type': 'composite',
          'impact': 'high',
        },
        {
          'table': 'user_gamification',
          'columns': ['level'],
          'type': 'single',
          'impact': 'medium',
        },
      ],
    };
  }

  void _toggleAutoRefresh() {
    setState(() {
      _autoRefreshEnabled = !_autoRefreshEnabled;
      if (_autoRefreshEnabled) {
        _setupAutoRefresh();
      } else {
        _refreshTimer?.cancel();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ErrorBoundaryWrapper(
      screenName: 'ApiPerformanceOptimizationDashboard',
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
          title: 'API Performance',
          actions: [
            IconButton(
              icon: Icon(
                _autoRefreshEnabled ? Icons.pause : Icons.play_arrow,
                size: 6.w,
                color: AppTheme.textPrimaryLight,
              ),
              onPressed: _toggleAutoRefresh,
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
                  ApiHealthScoreWidget(healthScore: _apiHealthScore),
                  SizedBox(height: 2.h),
                  TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    labelColor: AppTheme.primaryLight,
                    unselectedLabelColor: AppTheme.textSecondaryLight,
                    indicatorColor: AppTheme.primaryLight,
                    labelStyle: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                    ),
                    unselectedLabelStyle: TextStyle(fontSize: 14.sp),
                    tabs: const [
                      Tab(text: 'Endpoints'),
                      Tab(text: 'Bottlenecks'),
                      Tab(text: 'Caching'),
                      Tab(text: 'Alerts'),
                      Tab(text: 'Database'),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        EndpointMonitoringWidget(endpoints: _endpointMetrics),
                        BottleneckDetectionWidget(bottlenecks: _bottlenecks),
                        CachingStrategyWidget(
                          recommendations: _cachingRecommendations,
                        ),
                        PerformanceAlertsWidget(alerts: _performanceAlerts),
                        DatabaseMonitoringWidget(metrics: _databaseMetrics),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class SkeletonDashboard extends StatelessWidget {
  const SkeletonDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(4.w),
      child: Column(
        children: [
          ShimmerSkeletonLoader(
            child: Container(
              height: 15.h,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(12.0),
              ),
            ),
          ),
          SizedBox(height: 2.h),
          Expanded(
            child: ListView.builder(
              itemCount: 5,
              itemBuilder: (context, index) => Padding(
                padding: EdgeInsets.only(bottom: 2.h),
                child: ShimmerSkeletonLoader(
                  child: Container(
                    height: 12.h,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
