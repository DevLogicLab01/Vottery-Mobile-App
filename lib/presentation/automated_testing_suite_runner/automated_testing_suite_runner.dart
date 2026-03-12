import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/performance_testing_service.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/error_boundary_wrapper.dart';
import '../../widgets/shimmer_skeleton_loader.dart';
import './widgets/ci_cd_pipeline_widget.dart';
import './widgets/performance_benchmarks_widget.dart';
import './widgets/regression_alerts_widget.dart';
import './widgets/test_coverage_widget.dart';
import './widgets/test_execution_controls_widget.dart';
import './widgets/test_results_visualization_widget.dart';

class AutomatedTestingSuiteRunner extends StatefulWidget {
  const AutomatedTestingSuiteRunner({super.key});

  @override
  State<AutomatedTestingSuiteRunner> createState() =>
      _AutomatedTestingSuiteRunnerState();
}

class _AutomatedTestingSuiteRunnerState
    extends State<AutomatedTestingSuiteRunner>
    with SingleTickerProviderStateMixin {
  final PerformanceTestingService _testingService =
      PerformanceTestingService.instance;

  late TabController _tabController;
  bool _isLoading = true;
  bool _isRunningTests = false;

  Map<String, dynamic> _coverageData = {};
  Map<String, dynamic> _cicdStatus = {};
  Map<String, dynamic> _testResults = {};
  Map<String, dynamic> _benchmarks = {};
  List<Map<String, dynamic>> _regressions = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _loadTestData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadTestData() async {
    setState(() => _isLoading = true);

    try {
      await Future.delayed(const Duration(milliseconds: 800));

      setState(() {
        _coverageData = {
          'unit_test_coverage': 82.5,
          'integration_test_coverage': 75.3,
          'e2e_test_coverage': 68.7,
          'total_tests': 1247,
          'passing_tests': 1198,
          'failing_tests': 49,
        };

        _cicdStatus = {
          'pipeline_status': 'passing',
          'last_run': DateTime.now().subtract(const Duration(hours: 2)),
          'build_duration': 420,
          'github_actions_status': 'success',
        };

        _testResults = {
          'unit_tests': {'passed': 845, 'failed': 12, 'skipped': 3},
          'integration_tests': {'passed': 287, 'failed': 18, 'skipped': 5},
          'e2e_tests': {'passed': 66, 'failed': 19, 'skipped': 2},
        };

        _benchmarks = {
          'avg_screen_render_time': 1847,
          'avg_api_response_time': 320,
          'memory_usage_mb': 145,
        };

        _regressions = [];
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Load test data error: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _runAllTests() async {
    setState(() => _isRunningTests = true);

    try {
      await _testingService.runAllPerformanceTests();
      await _loadTestData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All tests completed successfully'),
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
      screenName: 'AutomatedTestingSuiteRunner',
      onRetry: _loadTestData,
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
          title: 'Automated Testing Suite',
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
              onPressed: _loadTestData,
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
                        TestCoverageWidget(coverageData: _coverageData),
                        CiCdPipelineWidget(cicdStatus: _cicdStatus),
                        TestExecutionControlsWidget(
                          onRunTests: _runAllTests,
                          isRunning: _isRunningTests,
                        ),
                        TestResultsVisualizationWidget(
                          testResults: _testResults,
                        ),
                        PerformanceBenchmarksWidget(benchmarks: _benchmarks),
                        RegressionAlertsWidget(
                          regressions: _regressions,
                          onRefresh: _loadTestData,
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
    final totalTests = _coverageData['total_tests'] ?? 0;
    final passingTests = _coverageData['passing_tests'] ?? 0;
    final failingTests = _coverageData['failing_tests'] ?? 0;
    final unitCoverage = _coverageData['unit_test_coverage'] ?? 0.0;

    final hasFailures = failingTests > 0;

    return Container(
      padding: EdgeInsets.all(4.w),
      color: hasFailures ? Colors.red.shade50 : Colors.green.shade50,
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                hasFailures ? Icons.warning : Icons.check_circle,
                color: hasFailures ? Colors.red : Colors.green,
                size: 8.w,
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasFailures
                          ? '$failingTests Tests Failing'
                          : 'All Tests Passing',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: hasFailures ? Colors.red : Colors.green,
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
                  'Total Tests',
                  totalTests.toString(),
                  Colors.blue,
                ),
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: _buildMetricCard(
                  'Passing',
                  passingTests.toString(),
                  Colors.green,
                ),
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: _buildMetricCard(
                  'Failing',
                  failingTests.toString(),
                  Colors.red,
                ),
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: _buildMetricCard(
                  'Coverage',
                  '${unitCoverage.toStringAsFixed(1)}%',
                  Colors.purple,
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
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 0.5.h),
          Text(
            label,
            style: TextStyle(fontSize: 10.sp, color: Colors.grey),
            overflow: TextOverflow.ellipsis,
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
        labelStyle: TextStyle(fontSize: 10.sp, fontWeight: FontWeight.w600),
        isScrollable: true,
        tabs: const [
          Tab(text: 'Coverage'),
          Tab(text: 'CI/CD'),
          Tab(text: 'Execution'),
          Tab(text: 'Results'),
          Tab(text: 'Benchmarks'),
          Tab(text: 'Regressions'),
        ],
      ),
    );
  }
}
