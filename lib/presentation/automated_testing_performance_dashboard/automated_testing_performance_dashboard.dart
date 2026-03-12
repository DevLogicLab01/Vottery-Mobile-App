import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/performance_testing_service.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/error_boundary_wrapper.dart';
import '../../widgets/shimmer_skeleton_loader.dart';
import './widgets/ci_cd_pipeline_widget.dart';
import './widgets/performance_benchmark_widget.dart';
import './widgets/regression_alerts_widget.dart';
import './widgets/test_coverage_widget.dart';
import './widgets/test_execution_widget.dart';
import './widgets/test_history_widget.dart';

class AutomatedTestingPerformanceDashboard extends StatefulWidget {
  const AutomatedTestingPerformanceDashboard({super.key});

  @override
  State<AutomatedTestingPerformanceDashboard> createState() =>
      _AutomatedTestingPerformanceDashboardState();
}

class _AutomatedTestingPerformanceDashboardState
    extends State<AutomatedTestingPerformanceDashboard>
    with SingleTickerProviderStateMixin {
  final PerformanceTestingService _testingService =
      PerformanceTestingService.instance;

  late TabController _tabController;
  bool _isLoading = true;
  bool _isRunningTests = false;

  Map<String, dynamic> _coverageData = {};
  Map<String, dynamic> _cicdStatus = {};
  Map<String, dynamic> _benchmarkData = {};
  List<Map<String, dynamic>> _testHistory = [];
  List<Map<String, dynamic>> _regressionAlerts = [];

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
      final results = await Future.wait([
        _testingService.getTestCoverageMetrics(),
        _testingService.getCICDPipelineStatus(),
        _testingService.getPerformanceBenchmarks(),
        _testingService.getTestHistory(),
        _testingService.detectRegressions(),
      ]);

      if (mounted) {
        setState(() {
          _coverageData = results[0] as Map<String, dynamic>;
          _cicdStatus = results[1] as Map<String, dynamic>;
          _benchmarkData = results[2] as Map<String, dynamic>;
          _testHistory = results[3] as List<Map<String, dynamic>>;
          _regressionAlerts = results[4] as List<Map<String, dynamic>>;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Load test data error: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _runTestSuite(String suiteType) async {
    setState(() => _isRunningTests = true);

    try {
      await _testingService.runTestSuite(suiteType);
      await _loadTestData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$suiteType tests completed successfully'),
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
      screenName: 'AutomatedTestingPerformanceDashboard',
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
          title: 'Automated Testing & Performance',
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
              onPressed: _isRunningTests ? null : () => _showTestSuiteDialog(),
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
                        TestCoverageWidget(
                          coverageData: _coverageData,
                          onRefresh: _loadTestData,
                        ),
                        CICDPipelineWidget(
                          pipelineStatus: _cicdStatus,
                          onRefresh: _loadTestData,
                        ),
                        TestExecutionWidget(
                          onRunTests: _runTestSuite,
                          isRunning: _isRunningTests,
                        ),
                        PerformanceBenchmarkWidget(
                          benchmarkData: _benchmarkData,
                          onRefresh: _loadTestData,
                        ),
                        TestHistoryWidget(
                          testHistory: _testHistory,
                          onRefresh: _loadTestData,
                        ),
                        RegressionAlertsWidget(
                          regressionAlerts: _regressionAlerts,
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
    final unitCoverage = _coverageData['unit_test_coverage'] ?? 0.0;
    final integrationCoverage =
        _coverageData['integration_test_coverage'] ?? 0.0;
    final e2eCoverage = _coverageData['e2e_test_coverage'] ?? 0.0;
    final pipelineHealth = _cicdStatus['health_status'] ?? 'unknown';

    return Container(
      padding: EdgeInsets.all(4.w),
      color: pipelineHealth == 'healthy'
          ? Colors.green.shade50
          : Colors.orange.shade50,
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                pipelineHealth == 'healthy'
                    ? Icons.check_circle
                    : Icons.warning,
                color: pipelineHealth == 'healthy'
                    ? Colors.green
                    : Colors.orange,
                size: 8.w,
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CI/CD Pipeline: ${pipelineHealth.toUpperCase()}',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: pipelineHealth == 'healthy'
                            ? Colors.green
                            : Colors.orange,
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
                child: _buildCoverageCard(
                  'Unit Tests',
                  '${unitCoverage.toStringAsFixed(1)}%',
                  unitCoverage >= 80 ? Colors.green : Colors.orange,
                ),
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: _buildCoverageCard(
                  'Integration',
                  '${integrationCoverage.toStringAsFixed(1)}%',
                  integrationCoverage >= 70 ? Colors.green : Colors.orange,
                ),
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: _buildCoverageCard(
                  'E2E Tests',
                  '${e2eCoverage.toStringAsFixed(1)}%',
                  e2eCoverage >= 60 ? Colors.green : Colors.orange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCoverageCard(String label, String value, Color color) {
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
          ),
          SizedBox(height: 0.5.h),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.sp,
              color: AppTheme.textSecondaryLight,
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
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
          Tab(text: 'Execute'),
          Tab(text: 'Benchmarks'),
          Tab(text: 'History'),
          Tab(text: 'Regressions'),
        ],
      ),
    );
  }

  void _showTestSuiteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Run Test Suite'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text('Unit Tests'),
              onTap: () {
                Navigator.pop(context);
                _runTestSuite('unit');
              },
            ),
            ListTile(
              title: Text('Integration Tests'),
              onTap: () {
                Navigator.pop(context);
                _runTestSuite('integration');
              },
            ),
            ListTile(
              title: Text('E2E Tests'),
              onTap: () {
                Navigator.pop(context);
                _runTestSuite('e2e');
              },
            ),
            ListTile(
              title: Text('All Tests'),
              onTap: () {
                Navigator.pop(context);
                _runTestSuite('all');
              },
            ),
          ],
        ),
      ),
    );
  }
}
