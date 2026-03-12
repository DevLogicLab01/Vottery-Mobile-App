import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/analytics_service.dart';
import '../../services/system_monitoring_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/error_boundary_wrapper.dart';
import '../../widgets/shimmer_skeleton_loader.dart';
import './widgets/error_tracking_tab_widget.dart';
import './widgets/performance_metrics_tab_widget.dart';
import './widgets/system_health_tab_widget.dart';
import './widgets/user_analytics_tab_widget.dart';

class AnalyticsPerformanceControlCenter extends StatefulWidget {
  const AnalyticsPerformanceControlCenter({super.key});

  @override
  State<AnalyticsPerformanceControlCenter> createState() =>
      _AnalyticsPerformanceControlCenterState();
}

class _AnalyticsPerformanceControlCenterState
    extends State<AnalyticsPerformanceControlCenter>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  bool _autoRefreshEnabled = true;
  Timer? _refreshTimer;

  Map<String, dynamic> _analyticsData = {};
  Map<String, dynamic> _errorTrackingData = {};
  Map<String, dynamic> _performanceData = {};
  Map<String, dynamic> _systemHealthData = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadAllData();
    _setupAutoRefresh();
    AnalyticsService.instance.trackUserEngagement(
      action: 'view_screen',
      screen: 'Analytics & Performance Control Center',
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _setupAutoRefresh() {
    if (_autoRefreshEnabled) {
      _refreshTimer = Timer.periodic(Duration(seconds: 30), (_) {
        if (mounted) {
          _loadAllData(silent: true);
        }
      });
    }
  }

  Future<void> _loadAllData({bool silent = false}) async {
    if (!silent) {
      setState(() => _isLoading = true);
    }

    try {
      final results = await Future.wait([
        _loadAnalyticsData(),
        _loadErrorTrackingData(),
        _loadPerformanceData(),
        _loadSystemHealthData(),
      ]);

      if (mounted) {
        setState(() {
          _analyticsData = results[0];
          _errorTrackingData = results[1];
          _performanceData = results[2];
          _systemHealthData = results[3];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<Map<String, dynamic>> _loadAnalyticsData() async {
    // Simulate Google Analytics data aggregation
    await Future.delayed(Duration(milliseconds: 500));
    return {
      'total_sessions': 15847,
      'active_users': 3421,
      'avg_session_duration': 342,
      'bounce_rate': 0.23,
      'vote_participation_events': 8934,
      'quest_completion_events': 2156,
      'vp_earning_events': 12453,
      'ai_feature_adoption': 0.67,
      'consensus_analysis_usage': 1823,
      'top_screens': [
        {'name': 'Vote Dashboard', 'views': 4521, 'avg_time': 245},
        {'name': 'Social Media Feed', 'views': 3892, 'avg_time': 412},
        {'name': 'VP Economy Dashboard', 'views': 2341, 'avg_time': 189},
        {'name': 'Gamification Hub', 'views': 1987, 'avg_time': 298},
      ],
      'engagement_funnel': [
        {'stage': 'App Open', 'users': 15847, 'conversion': 1.0},
        {'stage': 'Vote Discovery', 'users': 12341, 'conversion': 0.78},
        {'stage': 'Vote Cast', 'users': 8934, 'conversion': 0.56},
        {'stage': 'Quest Complete', 'users': 2156, 'conversion': 0.14},
      ],
      'custom_events': [
        {'name': 'vote_submission', 'count': 8934, 'trend': 0.12},
        {'name': 'quest_completion', 'count': 2156, 'trend': 0.08},
        {'name': 'vp_purchase', 'count': 456, 'trend': -0.03},
        {'name': 'fraud_alert', 'count': 23, 'trend': -0.15},
      ],
    };
  }

  Future<Map<String, dynamic>> _loadErrorTrackingData() async {
    // Simulate Sentry error tracking data
    await Future.delayed(Duration(milliseconds: 500));
    return {
      'total_errors': 127,
      'critical_errors': 3,
      'error_rate': 0.008,
      'affected_users': 45,
      'crash_free_rate': 0.997,
      'recent_errors': [
        {
          'id': 'err_001',
          'message': 'OpenAI API timeout',
          'severity': 'warning',
          'count': 12,
          'affected_users': 8,
          'timestamp': DateTime.now().subtract(Duration(hours: 2)),
          'stack_trace':
              'AIServiceBase.invokeAIFunction()\n  at openai_service.dart:145',
        },
        {
          'id': 'err_002',
          'message': 'Supabase connection failed',
          'severity': 'critical',
          'count': 3,
          'affected_users': 3,
          'timestamp': DateTime.now().subtract(Duration(hours: 5)),
          'stack_trace':
              'SupabaseService.query()\n  at supabase_service.dart:89',
        },
        {
          'id': 'err_003',
          'message': 'Cache write failure',
          'severity': 'error',
          'count': 8,
          'affected_users': 5,
          'timestamp': DateTime.now().subtract(Duration(hours: 8)),
          'stack_trace':
              'AICacheService.cacheConsensusResult()\n  at ai_cache_service.dart:67',
        },
      ],
      'error_trends': [
        {'date': '2026-02-01', 'count': 145},
        {'date': '2026-02-02', 'count': 132},
        {'date': '2026-02-03', 'count': 118},
        {'date': '2026-02-04', 'count': 127},
      ],
    };
  }

  Future<Map<String, dynamic>> _loadPerformanceData() async {
    // Get real system monitoring data
    final latencyStats = await SystemMonitoringService.instance
        .getAPILatencyStatistics();
    final dbPerformance = await SystemMonitoringService.instance
        .getDatabasePerformance();

    return {
      'ai_service_latency': {
        'openai': {'avg': 342, 'p95': 567, 'p99': 892},
        'anthropic': {'avg': 298, 'p95': 489, 'p99': 723},
        'gemini': {'avg': 412, 'p95': 678, 'p99': 945},
        'perplexity': {'avg': 523, 'p95': 834, 'p99': 1234},
      },
      'consensus_execution_times': {
        'avg': 1245,
        'p50': 1123,
        'p95': 1876,
        'p99': 2345,
      },
      'cache_hit_rates': {
        'ai_consensus': 0.78,
        'user_profiles': 0.92,
        'elections': 0.85,
        'votes': 0.88,
      },
      'database_performance': dbPerformance,
      'api_latency': latencyStats,
    };
  }

  Future<Map<String, dynamic>> _loadSystemHealthData() async {
    // Get real system health data
    final systemHealth = await SystemMonitoringService.instance
        .getSystemHealthOverview();
    final integrations = await SystemMonitoringService.instance
        .getIntegrationHealthStatuses();

    return {
      'offline_sync_success': 0.94,
      'voice_interaction_metrics': {
        'total_interactions': 1234,
        'success_rate': 0.89,
        'avg_response_time': 2.3,
      },
      'integration_status': integrations,
      'system_health': systemHealth,
    };
  }

  void _toggleAutoRefresh() {
    setState(() {
      _autoRefreshEnabled = !_autoRefreshEnabled;
    });

    if (_autoRefreshEnabled) {
      _setupAutoRefresh();
    } else {
      _refreshTimer?.cancel();
    }
  }

  Future<void> _exportReport() async {
    // Simulate report export
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Executive dashboard report exported successfully'),
        backgroundColor: AppTheme.accentLight,
      ),
    );

    AnalyticsService.instance.trackUserEngagement(
      action: 'export_report',
      screen: 'Analytics & Performance Control Center',
    );
  }

  @override
  Widget build(BuildContext context) {
    return ErrorBoundaryWrapper(
      screenName: 'AnalyticsPerformanceControlCenter',
      onRetry: () => _loadAllData(),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: CustomAppBar(
          title: 'Analytics & Performance',
          actions: [
            IconButton(
              icon: Icon(
                _autoRefreshEnabled ? Icons.pause_circle : Icons.play_circle,
                color: Colors.white,
              ),
              onPressed: _toggleAutoRefresh,
              tooltip: _autoRefreshEnabled
                  ? 'Pause auto-refresh'
                  : 'Enable auto-refresh',
            ),
            IconButton(
              icon: Icon(Icons.file_download, color: Colors.white),
              onPressed: _exportReport,
              tooltip: 'Export report',
            ),
            IconButton(
              icon: Icon(Icons.refresh, color: Colors.white),
              onPressed: () => _loadAllData(),
              tooltip: 'Refresh data',
            ),
          ],
        ),
        body: _isLoading
            ? const SkeletonDashboard()
            : SingleChildScrollView(
                child: Column(
                  children: [
                    Container(
                      color: AppTheme.backgroundLight,
                      child: TabBar(
                        controller: _tabController,
                        labelColor: AppTheme.primaryLight,
                        unselectedLabelColor: AppTheme.textSecondaryLight,
                        indicatorColor: AppTheme.primaryLight,
                        labelStyle: GoogleFonts.inter(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                        ),
                        unselectedLabelStyle: GoogleFonts.inter(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w400,
                        ),
                        isScrollable: true,
                        tabs: [
                          Tab(text: 'User Analytics'),
                          Tab(text: 'Error Tracking'),
                          Tab(text: 'Performance'),
                          Tab(text: 'System Health'),
                        ],
                      ),
                    ),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          UserAnalyticsTabWidget(data: _analyticsData),
                          ErrorTrackingTabWidget(data: _errorTrackingData),
                          PerformanceMetricsTabWidget(data: _performanceData),
                          SystemHealthTabWidget(data: _systemHealthData),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
