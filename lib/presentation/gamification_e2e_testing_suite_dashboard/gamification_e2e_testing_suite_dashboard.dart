import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import './widgets/ad_minigame_blockchain_test_widget.dart';
import './widgets/ci_cd_integration_widget.dart';
import './widgets/prediction_pool_test_widget.dart';
import './widgets/test_execution_controls_widget.dart';
import './widgets/test_results_analytics_widget.dart';
import './widgets/test_suite_overview_widget.dart';
import './widgets/vp_earning_quest_test_widget.dart';

class GamificationE2eTestingSuiteDashboard extends StatefulWidget {
  const GamificationE2eTestingSuiteDashboard({super.key});

  @override
  State<GamificationE2eTestingSuiteDashboard> createState() =>
      _GamificationE2eTestingSuiteDashboardState();
}

class _GamificationE2eTestingSuiteDashboardState
    extends State<GamificationE2eTestingSuiteDashboard> {
  String _selectedTab = 'overview';
  bool _isRunningTests = false;
  final Map<String, dynamic> _testResults = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Gamification E2E Testing Suite',
          style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1E88E5),
        elevation: 0,
      ),
      drawer: _buildNavigationDrawer(),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [const Color(0xFF1E88E5).withAlpha(26), Colors.white],
          ),
        ),
        child: _buildContent(),
      ),
    );
  }

  Widget _buildNavigationDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1E88E5), Color(0xFF1565C0)],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(Icons.bug_report, size: 40.sp, color: Colors.white),
                SizedBox(height: 1.h),
                Text(
                  'E2E Test Suite',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'QA & Developer Access',
                  style: TextStyle(color: Colors.white70, fontSize: 12.sp),
                ),
              ],
            ),
          ),
          _buildDrawerItem(
            icon: Icons.dashboard,
            title: 'Overview',
            value: 'overview',
          ),
          _buildDrawerItem(
            icon: Icons.attach_money,
            title: 'VP Earning Tests',
            value: 'vp_tests',
          ),
          _buildDrawerItem(
            icon: Icons.poll,
            title: 'Prediction Pool Tests',
            value: 'prediction_tests',
          ),
          _buildDrawerItem(
            icon: Icons.games,
            title: 'Ad Mini-game Tests',
            value: 'ad_tests',
          ),
          _buildDrawerItem(
            icon: Icons.play_circle,
            title: 'Test Execution',
            value: 'execution',
          ),
          _buildDrawerItem(
            icon: Icons.integration_instructions,
            title: 'CI/CD Integration',
            value: 'cicd',
          ),
          _buildDrawerItem(
            icon: Icons.analytics,
            title: 'Test Analytics',
            value: 'analytics',
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.settings, color: Colors.grey),
            title: const Text('Test Configuration'),
            onTap: () {
              Navigator.pop(context);
              _showConfigurationDialog();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required String value,
  }) {
    final isSelected = _selectedTab == value;
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? const Color(0xFF1E88E5) : Colors.grey,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? const Color(0xFF1E88E5) : Colors.black87,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      selectedTileColor: const Color(0xFF1E88E5).withAlpha(26),
      onTap: () {
        setState(() {
          _selectedTab = value;
        });
        Navigator.pop(context);
      },
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(2.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatusBanner(),
          SizedBox(height: 2.h),
          _buildTabContent(),
        ],
      ),
    );
  }

  Widget _buildStatusBanner() {
    return Container(
      padding: EdgeInsets.all(2.w),
      decoration: BoxDecoration(
        color: _isRunningTests
            ? Colors.orange.withAlpha(26)
            : Colors.green.withAlpha(26),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: _isRunningTests ? Colors.orange : Colors.green,
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Icon(
            _isRunningTests ? Icons.hourglass_empty : Icons.check_circle,
            color: _isRunningTests ? Colors.orange : Colors.green,
            size: 24.sp,
          ),
          SizedBox(width: 2.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isRunningTests ? 'Tests Running' : 'Test Suite Ready',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: _isRunningTests ? Colors.orange : Colors.green,
                  ),
                ),
                Text(
                  _isRunningTests
                      ? 'Executing automated test suite...'
                      : 'All systems operational',
                  style: TextStyle(fontSize: 12.sp, color: Colors.black54),
                ),
              ],
            ),
          ),
          if (_isRunningTests)
            const CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
            ),
        ],
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_selectedTab) {
      case 'overview':
        return TestSuiteOverviewWidget(onRunAllTests: _runAllTests);
      case 'vp_tests':
        return VpEarningQuestTestWidget(
          onRunTest: _runVpTests,
          testResults: _testResults['vp_tests'],
        );
      case 'prediction_tests':
        return PredictionPoolTestWidget(
          onRunTest: _runPredictionTests,
          testResults: _testResults['prediction_tests'],
        );
      case 'ad_tests':
        return AdMinigameBlockchainTestWidget(
          onRunTest: _runAdTests,
          testResults: _testResults['ad_tests'],
        );
      case 'execution':
        return TestExecutionControlsWidget(
          isRunning: _isRunningTests,
          onRunTests: _runAllTests,
          onStopTests: _stopTests,
        );
      case 'cicd':
        return const CiCdIntegrationWidget();
      case 'analytics':
        return TestResultsAnalyticsWidget(testResults: _testResults);
      default:
        return TestSuiteOverviewWidget(onRunAllTests: _runAllTests);
    }
  }

  Future<void> _runAllTests() async {
    setState(() {
      _isRunningTests = true;
    });

    try {
      // Simulate running all test suites
      await Future.delayed(const Duration(seconds: 2));
      await _runVpTests();
      await Future.delayed(const Duration(seconds: 1));
      await _runPredictionTests();
      await Future.delayed(const Duration(seconds: 1));
      await _runAdTests();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All test suites completed successfully'),
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
        setState(() {
          _isRunningTests = false;
        });
      }
    }
  }

  Future<void> _runVpTests() async {
    await Future.delayed(const Duration(seconds: 2));
    setState(() {
      _testResults['vp_tests'] = {
        'status': 'passed',
        'duration': '2.3s',
        'tests_passed': 8,
        'tests_failed': 0,
        'coverage': '85%',
        'timestamp': DateTime.now().toIso8601String(),
      };
    });
  }

  Future<void> _runPredictionTests() async {
    await Future.delayed(const Duration(seconds: 2));
    setState(() {
      _testResults['prediction_tests'] = {
        'status': 'passed',
        'duration': '3.1s',
        'tests_passed': 12,
        'tests_failed': 0,
        'coverage': '92%',
        'timestamp': DateTime.now().toIso8601String(),
      };
    });
  }

  Future<void> _runAdTests() async {
    await Future.delayed(const Duration(seconds: 2));
    setState(() {
      _testResults['ad_tests'] = {
        'status': 'passed',
        'duration': '2.8s',
        'tests_passed': 10,
        'tests_failed': 0,
        'coverage': '88%',
        'timestamp': DateTime.now().toIso8601String(),
      };
    });
  }

  void _stopTests() {
    setState(() {
      _isRunningTests = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Test execution stopped'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _showConfigurationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Test Configuration'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SwitchListTile(
              title: const Text('Verbose Logging'),
              value: true,
              onChanged: (value) {},
            ),
            SwitchListTile(
              title: const Text('Auto-retry Failed Tests'),
              value: false,
              onChanged: (value) {},
            ),
            SwitchListTile(
              title: const Text('Generate Coverage Reports'),
              value: true,
              onChanged: (value) {},
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
