import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/performance_testing_service.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/error_boundary_wrapper.dart';
import '../../widgets/shimmer_skeleton_loader.dart';
import './widgets/error_boundary_metrics_widget.dart';
import './widgets/regression_detection_widget.dart';
import './widgets/sentry_delivery_metrics_widget.dart';
import './widgets/skeleton_render_metrics_widget.dart';

class PerformanceTestDashboard extends StatefulWidget {
  const PerformanceTestDashboard({super.key});

  @override
  State<PerformanceTestDashboard> createState() =>
      _PerformanceTestDashboardState();
}

class _PerformanceTestDashboardState extends State<PerformanceTestDashboard>
    with SingleTickerProviderStateMixin {
  final PerformanceTestingService _testingService =
      PerformanceTestingService.instance;

  late TabController _tabController;
  bool _isLoading = true;
  bool _isRunningTests = false;

  Map<String, dynamic> _skeletonMetrics = {};
  Map<String, dynamic> _errorBoundaryMetrics = {};
  Map<String, dynamic> _sentryMetrics = {};
  List<Map<String, dynamic>> _regressions = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadTestResults();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadTestResults() async {
    setState(() => _isLoading = true);

    try {
      final results = await Future.wait([
        _testingService.getSkeletonLoaderMetrics(),
        _testingService.getErrorBoundaryMetrics(),
        _testingService.getSentryDeliveryMetrics(),
        _testingService.detectRegressions(),
      ]);

      if (mounted) {
        setState(() {
          _skeletonMetrics = results[0] as Map<String, dynamic>;
          _errorBoundaryMetrics = results[1] as Map<String, dynamic>;
          _sentryMetrics = results[2] as Map<String, dynamic>;
          _regressions = results[3] as List<Map<String, dynamic>>;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Load test results error: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _runAllTests() async {
    setState(() => _isRunningTests = true);

    try {
      await _testingService.runAllPerformanceTests();
      await _loadTestResults();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Performance tests completed successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Test execution failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isRunningTests = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ErrorBoundaryWrapper(
      screenName: 'PerformanceTestDashboard',
      onRetry: _loadTestResults,
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
          title: 'Performance Testing',
          actions: [
            IconButton(
              icon: _isRunningTests
                  ? SizedBox(
                      width: 20.0,
                      height: 20.0,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.0,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppTheme.textPrimaryLight,
                        ),
                      ),
                    )
                  : CustomIconWidget(
                      iconName: 'play_arrow',
                      size: 6.w,
                      color: AppTheme.textPrimaryLight,
                    ),
              onPressed: _isRunningTests ? null : _runAllTests,
            ),
            IconButton(
              icon: CustomIconWidget(
                iconName: 'refresh',
                size: 6.w,
                color: AppTheme.textPrimaryLight,
              ),
              onPressed: _loadTestResults,
            ),
            SizedBox(width: 2.w),
          ],
        ),
        body: _isLoading
            ? const SkeletonDashboard()
            : Column(
                children: [
                  _buildOverviewHeader(),
                  _buildTabBar(),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        SkeletonRenderMetricsWidget(metrics: _skeletonMetrics),
                        ErrorBoundaryMetricsWidget(
                          metrics: _errorBoundaryMetrics,
                        ),
                        SentryDeliveryMetricsWidget(metrics: _sentryMetrics),
                        RegressionDetectionWidget(
                          regressions: _regressions,
                          onRefresh: _loadTestResults,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildOverviewHeader() {
    final hasRegressions = _regressions.isNotEmpty;
    final avgSkeletonRender = _skeletonMetrics['average_render_time_ms'] ?? 0.0;
    final avgErrorRecovery =
        _errorBoundaryMetrics['average_recovery_latency_ms'] ?? 0.0;
    final sentryDeliveryRate = _sentryMetrics['delivery_success_rate'] ?? 100.0;

    return Container(
      padding: EdgeInsets.all(4.w),
      color: hasRegressions ? Colors.red.shade50 : Colors.green.shade50,
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                hasRegressions ? Icons.warning : Icons.check_circle,
                color: hasRegressions ? Colors.red : Colors.green,
                size: 8.w,
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasRegressions
                          ? '${_regressions.length} Performance Regressions Detected'
                          : 'All Tests Passing',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: hasRegressions ? Colors.red : Colors.green,
                      ),
                    ),
                    SizedBox(height: 0.5.h),
                    Text(
                      'Last run: ${DateTime.now().toString().substring(0, 16)}',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: AppTheme.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'Skeleton Render',
                  '${avgSkeletonRender.toStringAsFixed(1)}ms',
                  avgSkeletonRender < 100 ? Colors.green : Colors.orange,
                ),
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: _buildMetricCard(
                  'Error Recovery',
                  '${avgErrorRecovery.toStringAsFixed(1)}ms',
                  avgErrorRecovery < 500 ? Colors.green : Colors.orange,
                ),
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: _buildMetricCard(
                  'Sentry Delivery',
                  '${sentryDeliveryRate.toStringAsFixed(1)}%',
                  sentryDeliveryRate > 95 ? Colors.green : Colors.red,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String label, String value, Color color) {
    return Container(
      padding: EdgeInsets.all(2.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(height: 0.5.h),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.sp,
              color: AppTheme.textSecondaryLight,
            ),
            textAlign: TextAlign.center,
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
        labelStyle: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w600),
        isScrollable: true,
        tabs: const [
          Tab(text: 'Skeleton Loaders'),
          Tab(text: 'Error Boundaries'),
          Tab(text: 'Sentry Events'),
          Tab(text: 'Regressions'),
        ],
      ),
    );
  }
}
