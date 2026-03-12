import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../services/carousel_health_scaling_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/error_boundary_wrapper.dart';
import '../../widgets/shimmer_skeleton_loader.dart';

/// Carousel Health & Scaling Dashboard
/// Comprehensive infrastructure monitoring with system capacity, auto-scaling, and predictive alerts
class CarouselHealthScalingDashboard extends StatefulWidget {
  const CarouselHealthScalingDashboard({super.key});

  @override
  State<CarouselHealthScalingDashboard> createState() =>
      _CarouselHealthScalingDashboardState();
}

class _CarouselHealthScalingDashboardState
    extends State<CarouselHealthScalingDashboard>
    with SingleTickerProviderStateMixin {
  final CarouselHealthScalingService _healthService =
      CarouselHealthScalingService.instance;

  late TabController _tabController;
  bool _isLoading = true;
  String? _errorMessage;

  Map<String, dynamic> _healthScore = {};
  Map<String, dynamic> _capacityOverview = {};
  List<Map<String, dynamic>> _scalingHistory = [];
  List<Map<String, dynamic>> _slowQueries = [];
  List<Map<String, dynamic>> _activeBottlenecks = [];
  List<Map<String, dynamic>> _predictiveAlerts = [];

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
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait([
        _healthService.calculateHealthScore(),
        _healthService.getSystemCapacityOverview(),
        _healthService.getScalingHistory(days: 7),
        _healthService.getSlowQueries(limit: 10),
        _healthService.getActiveBottlenecks(),
        _healthService.getActivePredictiveAlerts(),
      ]);

      setState(() {
        _healthScore = results[0] as Map<String, dynamic>;
        _capacityOverview = results[1] as Map<String, dynamic>;
        _scalingHistory = results[2] as List<Map<String, dynamic>>;
        _slowQueries = results[3] as List<Map<String, dynamic>>;
        _activeBottlenecks = results[4] as List<Map<String, dynamic>>;
        _predictiveAlerts = results[5] as List<Map<String, dynamic>>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ErrorBoundaryWrapper(
      screenName: 'CarouselHealthScalingDashboard',
      onRetry: _loadDashboardData,
      child: Scaffold(
        backgroundColor: AppTheme.backgroundDark,
        appBar: AppBar(
          title: Text(
            'Carousel Health & Scaling',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryDark,
            ),
          ),
          backgroundColor: AppTheme.surfaceDark,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadDashboardData,
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            labelColor: AppThemeColors.electricGold,
            unselectedLabelColor: AppTheme.textSecondaryDark,
            indicatorColor: AppThemeColors.electricGold,
            labelStyle: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600),
            tabs: const [
              Tab(text: 'Overview'),
              Tab(text: 'Capacity'),
              Tab(text: 'Optimization'),
              Tab(text: 'Alerts'),
            ],
          ),
        ),
        body: _isLoading
            ? const SkeletonDashboard()
            : _errorMessage != null
            ? _buildErrorState()
            : TabBarView(
                controller: _tabController,
                children: [
                  _buildOverviewTab(),
                  _buildCapacityTab(),
                  _buildOptimizationTab(),
                  _buildAlertsTab(),
                ],
              ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 60.0, color: Colors.red.shade400),
            SizedBox(height: 2.h),
            Text(
              'Failed to load dashboard',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryDark,
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              _errorMessage ?? 'Unknown error',
              style: TextStyle(
                fontSize: 12.sp,
                color: AppTheme.textSecondaryDark,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ============================================
  // OVERVIEW TAB
  // ============================================

  Widget _buildOverviewTab() {
    return RefreshIndicator(
      onRefresh: _loadDashboardData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHealthScoreCard(),
            SizedBox(height: 3.h),
            _buildQuickStatsGrid(),
            SizedBox(height: 3.h),
            _buildRecentScalingEvents(),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthScoreCard() {
    final score = (_healthScore['overall_score'] as num?)?.toDouble() ?? 0.0;
    final status = _healthScore['status'] as String? ?? 'unknown';

    Color scoreColor;
    if (score >= 80) {
      scoreColor = Colors.green;
    } else if (score >= 60) {
      scoreColor = Colors.orange;
    } else {
      scoreColor = Colors.red;
    }

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        children: [
          Text(
            'Overall Health Score',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryDark,
            ),
          ),
          SizedBox(height: 2.h),
          SizedBox(
            height: 150.0,
            width: 150.0,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: score / 100,
                  strokeWidth: 12.0,
                  backgroundColor: Colors.grey.shade800,
                  valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      score.toStringAsFixed(0),
                      style: TextStyle(
                        fontSize: 32.sp,
                        fontWeight: FontWeight.bold,
                        color: scoreColor,
                      ),
                    ),
                    Text(
                      status.toUpperCase(),
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: AppTheme.textSecondaryDark,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 2.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildScoreBreakdown(
                'Database',
                (_healthScore['database_score'] as num?)?.toDouble() ?? 0.0,
              ),
              _buildScoreBreakdown(
                'Application',
                (_healthScore['application_score'] as num?)?.toDouble() ?? 0.0,
              ),
              _buildScoreBreakdown(
                'Delivery',
                (_healthScore['delivery_score'] as num?)?.toDouble() ?? 0.0,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScoreBreakdown(String label, double score) {
    return Column(
      children: [
        Text(
          score.toStringAsFixed(0),
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimaryDark,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 10.sp, color: AppTheme.textSecondaryDark),
        ),
      ],
    );
  }

  Widget _buildQuickStatsGrid() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Active Bottlenecks',
            (_healthScore['active_bottlenecks'] as int? ?? 0).toString(),
            Icons.warning,
            Colors.orange,
          ),
        ),
        SizedBox(width: 3.w),
        Expanded(
          child: _buildStatCard(
            'Slow Queries',
            (_healthScore['slow_queries'] as int? ?? 0).toString(),
            Icons.speed,
            Colors.red,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24.0),
          SizedBox(height: 1.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryDark,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 11.sp,
              color: AppTheme.textSecondaryDark,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildRecentScalingEvents() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Scaling Events',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimaryDark,
          ),
        ),
        SizedBox(height: 2.h),
        if (_scalingHistory.isEmpty)
          Center(
            child: Text(
              'No scaling events',
              style: TextStyle(
                fontSize: 12.sp,
                color: AppTheme.textSecondaryDark,
              ),
            ),
          )
        else
          ..._scalingHistory
              .take(5)
              .map((event) => _buildScalingEventCard(event)),
      ],
    );
  }

  Widget _buildScalingEventCard(Map<String, dynamic> event) {
    final actionResult = event['action_result'] as String? ?? 'unknown';
    final isSuccess = actionResult == 'success';

    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Row(
        children: [
          Icon(
            isSuccess ? Icons.check_circle : Icons.error,
            color: isSuccess ? Colors.green : Colors.red,
            size: 24.0,
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event['scaling_action'] as String? ?? 'Unknown action',
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimaryDark,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 0.5.h),
                Text(
                  'Trigger: ${event['trigger_metric']}',
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: AppTheme.textSecondaryDark,
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

  // ============================================
  // CAPACITY TAB
  // ============================================

  Widget _buildCapacityTab() {
    return RefreshIndicator(
      onRefresh: _loadDashboardData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCapacitySection('Database', _capacityOverview['database']),
            SizedBox(height: 3.h),
            _buildCapacitySection(
              'Application',
              _capacityOverview['application'],
            ),
            SizedBox(height: 3.h),
            _buildCapacitySection('CDN', _capacityOverview['cdn']),
            SizedBox(height: 3.h),
            _buildCapacitySection('Cache', _capacityOverview['cache']),
          ],
        ),
      ),
    );
  }

  Widget _buildCapacitySection(String title, dynamic data) {
    if (data == null || data is! Map<String, dynamic>) {
      return Container(
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: AppTheme.surfaceDark,
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Text(
          '$title: No data available',
          style: TextStyle(fontSize: 14.sp, color: AppTheme.textSecondaryDark),
        ),
      );
    }

    final metrics = data;
    final metricsList = metrics.entries
        .where((e) => e.value is Map && (e.value as Map).containsKey('status'))
        .toList();

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryDark,
            ),
          ),
          SizedBox(height: 2.h),
          if (metricsList.isEmpty)
            Text(
              'No metrics available',
              style: TextStyle(
                fontSize: 12.sp,
                color: AppTheme.textSecondaryDark,
              ),
            )
          else
            ...metricsList.map((entry) {
              final metricName = entry.key;
              final metricData = entry.value as Map<String, dynamic>;
              final value = (metricData['value'] as num?)?.toDouble() ?? 0.0;
              final status = metricData['status'] as String? ?? 'unknown';
              final unit = metricData['unit'] as String? ?? '';

              Color statusColor;
              if (status == 'healthy') {
                statusColor = Colors.green;
              } else if (status == 'warning') {
                statusColor = Colors.orange;
              } else {
                statusColor = Colors.red;
              }

              return Padding(
                padding: EdgeInsets.only(bottom: 1.h),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        metricName.replaceAll('_', ' ').toUpperCase(),
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: AppTheme.textSecondaryDark,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          '${value.toStringAsFixed(1)} $unit',
                          style: TextStyle(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimaryDark,
                          ),
                        ),
                        SizedBox(width: 2.w),
                        Container(
                          width: 8.0,
                          height: 8.0,
                          decoration: BoxDecoration(
                            color: statusColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  // ============================================
  // OPTIMIZATION TAB
  // ============================================

  Widget _buildOptimizationTab() {
    return RefreshIndicator(
      onRefresh: _loadDashboardData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Slow Queries',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryDark,
              ),
            ),
            SizedBox(height: 2.h),
            if (_slowQueries.isEmpty)
              Center(
                child: Text(
                  'No slow queries detected',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: AppTheme.textSecondaryDark,
                  ),
                ),
              )
            else
              ..._slowQueries.map((query) => _buildSlowQueryCard(query)),
            SizedBox(height: 3.h),
            Text(
              'Active Bottlenecks',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryDark,
              ),
            ),
            SizedBox(height: 2.h),
            if (_activeBottlenecks.isEmpty)
              Center(
                child: Text(
                  'No active bottlenecks',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: AppTheme.textSecondaryDark,
                  ),
                ),
              )
            else
              ..._activeBottlenecks.map(
                (bottleneck) => _buildBottleneckCard(bottleneck),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlowQueryCard(Map<String, dynamic> query) {
    final avgTime = query['avg_execution_time_ms'] as int? ?? 0;
    final callCount = query['call_count'] as int? ?? 0;

    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${avgTime}ms avg',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              Text(
                '$callCount calls',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: AppTheme.textSecondaryDark,
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Text(
            query['query_text'] as String? ?? 'Unknown query',
            style: TextStyle(
              fontSize: 11.sp,
              color: AppTheme.textSecondaryDark,
              fontFamily: 'monospace',
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildBottleneckCard(Map<String, dynamic> bottleneck) {
    final severity = bottleneck['severity'] as String? ?? 'unknown';
    final type = bottleneck['bottleneck_type'] as String? ?? 'unknown';

    Color severityColor;
    if (severity == 'critical') {
      severityColor = Colors.red;
    } else if (severity == 'high') {
      severityColor = Colors.orange;
    } else {
      severityColor = Colors.yellow;
    }

    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: severityColor, width: 2.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                type.toUpperCase(),
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimaryDark,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                decoration: BoxDecoration(
                  color: severityColor.withAlpha(51),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Text(
                  severity.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.bold,
                    color: severityColor,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          if (bottleneck['root_cause'] != null)
            Text(
              bottleneck['root_cause'] as String,
              style: TextStyle(
                fontSize: 12.sp,
                color: AppTheme.textSecondaryDark,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
    );
  }

  // ============================================
  // ALERTS TAB
  // ============================================

  Widget _buildAlertsTab() {
    return RefreshIndicator(
      onRefresh: _loadDashboardData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Predictive Alerts',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryDark,
              ),
            ),
            SizedBox(height: 2.h),
            if (_predictiveAlerts.isEmpty)
              Center(
                child: Text(
                  'No active predictive alerts',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: AppTheme.textSecondaryDark,
                  ),
                ),
              )
            else
              ..._predictiveAlerts.map(
                (alert) => _buildPredictiveAlertCard(alert),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPredictiveAlertCard(Map<String, dynamic> alert) {
    final metricName = alert['metric_name'] as String? ?? 'Unknown metric';
    final currentValue = (alert['current_value'] as num?)?.toDouble() ?? 0.0;
    final thresholdValue =
        (alert['threshold_value'] as num?)?.toDouble() ?? 0.0;
    final confidenceLevel =
        (alert['confidence_level'] as num?)?.toDouble() ?? 0.0;

    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.orange, width: 2.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning, color: Colors.orange, size: 20.0),
              SizedBox(width: 2.w),
              Expanded(
                child: Text(
                  metricName.toUpperCase(),
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryDark,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Text(
            'Current: ${currentValue.toStringAsFixed(2)} | Threshold: ${thresholdValue.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 12.sp,
              color: AppTheme.textSecondaryDark,
            ),
          ),
          SizedBox(height: 0.5.h),
          Text(
            'Confidence: ${(confidenceLevel * 100).toStringAsFixed(0)}%',
            style: TextStyle(
              fontSize: 11.sp,
              color: AppTheme.textSecondaryDark,
            ),
          ),
        ],
      ),
    );
  }
}

class AppThemeColors {
  static const Color electricGold = Color(0xFFFFD700);
  static const Color neonMint = Color(0xFF00FFB3);
}