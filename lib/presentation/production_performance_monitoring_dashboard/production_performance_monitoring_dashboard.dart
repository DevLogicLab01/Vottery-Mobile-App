import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../widgets/custom_app_bar.dart';
import './widgets/performance_overview_header_widget.dart';
import './widgets/crash_rate_analytics_widget.dart';
import './widgets/api_latency_monitoring_widget.dart';
import './widgets/session_stability_widget.dart';
import './widgets/screen_error_analysis_widget.dart';
import './widgets/remediation_actions_log_widget.dart';
import './widgets/anomaly_detection_widget.dart';
import '../../widgets/error_boundary_wrapper.dart';
import '../../widgets/shimmer_skeleton_loader.dart';

class ProductionPerformanceMonitoringDashboard extends StatefulWidget {
  const ProductionPerformanceMonitoringDashboard({super.key});

  @override
  State<ProductionPerformanceMonitoringDashboard> createState() =>
      _ProductionPerformanceMonitoringDashboardState();
}

class _ProductionPerformanceMonitoringDashboardState
    extends State<ProductionPerformanceMonitoringDashboard> {
  bool _isLoading = true;
  bool _autoRefreshEnabled = true;
  Timer? _refreshTimer;

  Map<String, dynamic> _systemHealthScore = {};
  List<Map<String, dynamic>> _crashRateMetrics = [];
  List<Map<String, dynamic>> _apiLatencyMetrics = [];
  Map<String, dynamic> _sessionStabilityData = {};
  List<Map<String, dynamic>> _screenErrors = [];
  List<Map<String, dynamic>> _remediationActions = [];
  List<Map<String, dynamic>> _anomalies = [];

  @override
  void initState() {
    super.initState();
    _loadMonitoringData();
    _setupAutoRefresh();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _setupAutoRefresh() {
    if (_autoRefreshEnabled) {
      _refreshTimer = Timer.periodic(Duration(minutes: 5), (_) {
        if (mounted) {
          _loadMonitoringData(silent: true);
        }
      });
    }
  }

  Future<void> _loadMonitoringData({bool silent = false}) async {
    if (!silent) {
      setState(() => _isLoading = true);
    }

    try {
      final results = await Future.wait([
        _loadSystemHealthScore(),
        _loadCrashRateMetrics(),
        _loadAPILatencyMetrics(),
        _loadSessionStabilityData(),
        _loadScreenErrors(),
        _loadRemediationActions(),
        _loadAnomalies(),
      ]);

      if (mounted) {
        setState(() {
          _systemHealthScore = results[0] as Map<String, dynamic>;
          _crashRateMetrics = results[1] as List<Map<String, dynamic>>;
          _apiLatencyMetrics = results[2] as List<Map<String, dynamic>>;
          _sessionStabilityData = results[3] as Map<String, dynamic>;
          _screenErrors = results[4] as List<Map<String, dynamic>>;
          _remediationActions = results[5] as List<Map<String, dynamic>>;
          _anomalies = results[6] as List<Map<String, dynamic>>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<Map<String, dynamic>> _loadSystemHealthScore() async {
    await Future.delayed(Duration(milliseconds: 300));
    return {
      'overall_health_score': 96.5,
      'active_incidents': 2,
      'automated_remediations': 8,
      'status': 'healthy',
    };
  }

  Future<List<Map<String, dynamic>>> _loadCrashRateMetrics() async {
    await Future.delayed(Duration(milliseconds: 300));
    return [
      {
        'screen_name': 'Vote Casting',
        'crash_rate_percentage': 1.2,
        'crashes_per_1000_sessions': 12,
        'severity': 'low',
        'trend': 'decreasing',
      },
      {
        'screen_name': 'Social Feed',
        'crash_rate_percentage': 0.8,
        'crashes_per_1000_sessions': 8,
        'severity': 'low',
        'trend': 'stable',
      },
      {
        'screen_name': 'Creator Studio',
        'crash_rate_percentage': 2.5,
        'crashes_per_1000_sessions': 25,
        'severity': 'critical',
        'trend': 'increasing',
      },
    ];
  }

  Future<List<Map<String, dynamic>>> _loadAPILatencyMetrics() async {
    await Future.delayed(Duration(milliseconds: 300));
    return [
      {
        'service_name': 'Supabase',
        'average_latency_p95': 1.8,
        'severity': 'low',
        'status': 'healthy',
      },
      {
        'service_name': 'Stripe',
        'average_latency_p95': 2.2,
        'severity': 'low',
        'status': 'healthy',
      },
      {
        'service_name': 'OpenAI',
        'average_latency_p95': 3.5,
        'severity': 'high',
        'status': 'degraded',
      },
      {
        'service_name': 'Anthropic',
        'average_latency_p95': 2.9,
        'severity': 'medium',
        'status': 'healthy',
      },
      {
        'service_name': 'Perplexity',
        'average_latency_p95': 2.1,
        'severity': 'low',
        'status': 'healthy',
      },
    ];
  }

  Future<Map<String, dynamic>> _loadSessionStabilityData() async {
    await Future.delayed(Duration(milliseconds: 300));
    return {
      'session_stability_score': 97.5,
      'successful_sessions': 9750,
      'total_sessions': 10000,
      'severity': 'low',
      'trend': 'stable',
    };
  }

  Future<List<Map<String, dynamic>>> _loadScreenErrors() async {
    await Future.delayed(Duration(milliseconds: 300));
    return [
      {
        'screen_name': 'Vote Dashboard',
        'error_count': 15,
        'error_types': ['Network Timeout', 'Null Reference'],
        'severity': 'medium',
      },
      {
        'screen_name': 'Payment Processing',
        'error_count': 8,
        'error_types': ['API Error', 'Validation Failed'],
        'severity': 'high',
      },
      {
        'screen_name': 'Creator Analytics',
        'error_count': 3,
        'error_types': ['Data Loading Error'],
        'severity': 'low',
      },
    ];
  }

  Future<List<Map<String, dynamic>>> _loadRemediationActions() async {
    await Future.delayed(Duration(milliseconds: 300));
    return [
      {
        'action_type': 'fallback_api_activation',
        'trigger_metric': 'OpenAI API Latency',
        'action_result': 'Success',
        'execution_time': 0.5,
        'executed_at': DateTime.now().subtract(Duration(hours: 2)),
      },
      {
        'action_type': 'rate_limiting_adjustment',
        'trigger_metric': 'API Request Spike',
        'action_result': 'Success',
        'execution_time': 0.2,
        'executed_at': DateTime.now().subtract(Duration(hours: 5)),
      },
      {
        'action_type': 'circuit_breaker_engagement',
        'trigger_metric': 'Service Failure Rate',
        'action_result': 'Success',
        'execution_time': 0.1,
        'executed_at': DateTime.now().subtract(Duration(hours: 8)),
      },
    ];
  }

  Future<List<Map<String, dynamic>>> _loadAnomalies() async {
    await Future.delayed(Duration(milliseconds: 300));
    return [
      {
        'metric_name': 'Creator Studio Crash Rate',
        'current_value': 2.5,
        'baseline_value': 1.0,
        'degradation_percentage': 150.0,
        'detected_at': DateTime.now().subtract(Duration(hours: 1)),
      },
      {
        'metric_name': 'OpenAI API Latency',
        'current_value': 3.5,
        'baseline_value': 2.0,
        'degradation_percentage': 75.0,
        'detected_at': DateTime.now().subtract(Duration(hours: 3)),
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    return ErrorBoundaryWrapper(
      screenName: 'ProductionPerformanceMonitoringDashboard',
      onRetry: () => _loadMonitoringData(),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: CustomAppBar(
          title: 'Production Performance Monitoring',
          actions: [
            IconButton(
              icon: Icon(
                _autoRefreshEnabled ? Icons.pause_circle : Icons.play_circle,
                color: Colors.white,
              ),
              onPressed: () {
                setState(() {
                  _autoRefreshEnabled = !_autoRefreshEnabled;
                  if (_autoRefreshEnabled) {
                    _setupAutoRefresh();
                  } else {
                    _refreshTimer?.cancel();
                  }
                });
              },
            ),
            IconButton(
              icon: Icon(Icons.refresh, color: Colors.white),
              onPressed: () => _loadMonitoringData(),
            ),
          ],
        ),
        body: _isLoading
            ? const SkeletonDashboard()
            : RefreshIndicator(
                onRefresh: () => _loadMonitoringData(),
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(3.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      PerformanceOverviewHeaderWidget(
                        systemHealthScore: _systemHealthScore,
                      ),
                      SizedBox(height: 2.h),
                      CrashRateAnalyticsWidget(
                        crashRateMetrics: _crashRateMetrics,
                      ),
                      SizedBox(height: 2.h),
                      ApiLatencyMonitoringWidget(
                        apiLatencyMetrics: _apiLatencyMetrics,
                      ),
                      SizedBox(height: 2.h),
                      SessionStabilityWidget(
                        sessionStabilityData: _sessionStabilityData,
                      ),
                      SizedBox(height: 2.h),
                      ScreenErrorAnalysisWidget(screenErrors: _screenErrors),
                      SizedBox(height: 2.h),
                      AnomalyDetectionWidget(anomalies: _anomalies),
                      SizedBox(height: 2.h),
                      RemediationActionsLogWidget(
                        remediationActions: _remediationActions,
                      ),
                      SizedBox(height: 2.h),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
