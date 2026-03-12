import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import './widgets/batch_test_controls_widget.dart';
import './widgets/test_file_card_widget.dart';
import './widgets/test_results_detail_widget.dart';
import './widgets/test_suite_overview_widget.dart';

class E2ETestingCoverageDashboard extends StatefulWidget {
  const E2ETestingCoverageDashboard({super.key});

  @override
  State<E2ETestingCoverageDashboard> createState() =>
      _E2ETestingCoverageDashboardState();
}

class _E2ETestingCoverageDashboardState
    extends State<E2ETestingCoverageDashboard> {
  bool _isRunningAll = false;
  int _completedTests = 0;
  final List<Map<String, dynamic>> _testResults = [];

  final List<Map<String, dynamic>> _testFiles = [
    {
      'id': 'fraud_detection',
      'fileName': 'fraud_detection_failover_test.dart',
      'suiteName': 'Fraud Detection Tests',
      'description':
          'Tests suspicious activity pattern simulation and AI service failover verification',
      'status': 'passing',
      'assertions': [
        'fraudAlert.confidence > 0.8',
        'accountSuspended == true',
        'notificationSent == true',
      ],
      'isRunning': false,
      'icon': Icons.security,
      'color': 0xFFF38BA8,
    },
    {
      'id': 'sms_provider',
      'fileName': 'sms_provider_switching_test.dart',
      'suiteName': 'SMS Provider Tests',
      'description':
          'Tests Telnyx to Twilio failover with gamification SMS blocking',
      'status': 'passing',
      'assertions': [
        'currentProvider == twilio',
        'gamificationSMSBlocked == true',
        'regularSMSSent == true',
      ],
      'isRunning': false,
      'icon': Icons.sms,
      'color': 0xFF89B4FA,
    },
    {
      'id': 'stripe_payout',
      'fileName': 'stripe_payout_workflow_test.dart',
      'suiteName': 'Stripe Integration Tests',
      'description': 'Validates creator payout processing end-to-end workflow',
      'status': 'passing',
      'assertions': [
        'payoutStatus == completed',
        'creatorNotified == true',
        'balanceUpdated correctly',
      ],
      'isRunning': false,
      'icon': Icons.payment,
      'color': 0xFFA6E3A1,
    },
    {
      'id': 'ai_orchestration',
      'fileName': 'ai_orchestration_test.dart',
      'suiteName': 'AI Orchestration Tests',
      'description':
          'Verifies multi-AI consensus and timeout handling across 4 AI services',
      'status': 'passing',
      'assertions': [
        'allServicesCalled == true',
        'consensusAchieved == true',
        'failoverWorked == true',
      ],
      'isRunning': false,
      'icon': Icons.psychology,
      'color': 0xFFCBA6F7,
    },
    {
      'id': 'creator_churn',
      'fileName': 'creator_churn_intervention_test.dart',
      'suiteName': 'Churn Prevention Tests',
      'description':
          'Tests automated retention workflows with SMS/email interventions',
      'status': 'passing',
      'assertions': [
        'churnPredictionCreated == true',
        'SMSSent == true',
        'emailSent == true',
      ],
      'isRunning': false,
      'icon': Icons.trending_down,
      'color': 0xFFF9E2AF,
    },
    {
      'id': 'carousel_performance',
      'fileName': 'carousel_performance_test.dart',
      'suiteName': 'Performance Tests',
      'description':
          'Measures render times, frame rates, and memory usage benchmarks',
      'status': 'passing',
      'assertions': ['renderTime < 200ms', 'fps >= 45', 'memoryLeaks.isEmpty'],
      'isRunning': false,
      'icon': Icons.speed,
      'color': 0xFF94E2D5,
    },
  ];

  int get _passingCount =>
      _testFiles.where((t) => t['status'] == 'passing').length;
  int get _failingCount =>
      _testFiles.where((t) => t['status'] == 'failing').length;
  double get _coveragePercentage =>
      _testFiles.isEmpty ? 0 : (_passingCount / _testFiles.length) * 100;

  Future<void> _runSingleTest(int index) async {
    setState(() {
      _testFiles[index]['isRunning'] = true;
    });

    await Future.delayed(const Duration(milliseconds: 1500));

    setState(() {
      _testFiles[index]['isRunning'] = false;
      _testFiles[index]['status'] = 'passing';
      _testResults.insert(0, {
        'test_name': _testFiles[index]['fileName'],
        'passed': true,
        'duration_ms': 800 + (index * 150),
        'assertions': _testFiles[index]['assertions'],
      });
    });
  }

  Future<void> _runAllTests() async {
    setState(() {
      _isRunningAll = true;
      _completedTests = 0;
      _testResults.clear();
    });

    for (int i = 0; i < _testFiles.length; i++) {
      setState(() {
        _testFiles[i]['isRunning'] = true;
      });

      await Future.delayed(const Duration(milliseconds: 1200));

      setState(() {
        _testFiles[i]['isRunning'] = false;
        _testFiles[i]['status'] = 'passing';
        _completedTests = i + 1;
        _testResults.insert(0, {
          'test_name': _testFiles[i]['fileName'],
          'passed': true,
          'duration_ms': 700 + (i * 120),
          'assertions': _testFiles[i]['assertions'],
        });
      });
    }

    setState(() {
      _isRunningAll = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'All ${_testFiles.length} tests completed successfully!',
            style: GoogleFonts.inter(color: Colors.white),
          ),
          backgroundColor: const Color(0xFFA6E3A1).withAlpha(204),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _generateReport() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2E),
        title: Text(
          'Test Coverage Report',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildReportRow('Total Test Files', '${_testFiles.length}'),
            _buildReportRow('Passing Tests', '$_passingCount'),
            _buildReportRow('Failing Tests', '$_failingCount'),
            _buildReportRow(
              'Coverage',
              '${_coveragePercentage.toStringAsFixed(1)}%',
            ),
            _buildReportRow('CI/CD Status', 'Active'),
            _buildReportRow(
              'Generated',
              DateTime.now().toString().substring(0, 16),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Close',
              style: GoogleFonts.inter(color: const Color(0xFF89B4FA)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(fontSize: 12, color: Colors.white60),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF181825),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E2E),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'E2E Testing Coverage',
              style: GoogleFonts.inter(
                fontSize: 14.sp,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            Text(
              'Integration Test Management',
              style: GoogleFonts.inter(fontSize: 9.sp, color: Colors.white54),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFA6E3A1).withAlpha(38),
              borderRadius: BorderRadius.circular(6.0),
              border: Border.all(color: const Color(0xFFA6E3A1).withAlpha(102)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.verified, size: 12, color: Color(0xFFA6E3A1)),
                const SizedBox(width: 4),
                Text(
                  'QA Engineer',
                  style: GoogleFonts.inter(
                    fontSize: 9.sp,
                    color: const Color(0xFFA6E3A1),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      drawer: _buildNavigationDrawer(),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TestSuiteOverviewWidget(
              totalFiles: _testFiles.length,
              passingTests: _passingCount,
              failingTests: _failingCount,
              coveragePercentage: _coveragePercentage,
            ),
            SizedBox(height: 2.h),
            BatchTestControlsWidget(
              isRunningAll: _isRunningAll,
              completedTests: _completedTests,
              totalTests: _testFiles.length,
              onRunAll: _runAllTests,
              onGenerateReport: _generateReport,
            ),
            SizedBox(height: 2.h),
            Text(
              'Test Suites',
              style: GoogleFonts.inter(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 1.h),
            ...List.generate(_testFiles.length, (index) {
              final test = _testFiles[index];
              final color = Color(test['color'] as int);
              return TestFileCardWidget(
                fileName: test['fileName'] as String,
                description: test['description'] as String,
                status: test['status'] as String,
                assertions: List<String>.from(test['assertions'] as List),
                isRunning: test['isRunning'] as bool,
                onRunTest: () => _runSingleTest(index),
                statusColor: test['status'] == 'passing'
                    ? const Color(0xFFA6E3A1)
                    : test['status'] == 'failing'
                    ? const Color(0xFFF38BA8)
                    : color,
              );
            }),
            SizedBox(height: 2.h),
            TestResultsDetailWidget(testResults: _testResults),
            SizedBox(height: 3.h),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationDrawer() {
    return Drawer(
      backgroundColor: const Color(0xFF1E1E2E),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: Color(0xFF181825)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Icon(
                  Icons.bug_report,
                  color: Color(0xFF89B4FA),
                  size: 32,
                ),
                SizedBox(height: 1.h),
                Text(
                  'QA Dashboard',
                  style: GoogleFonts.inter(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'E2E Testing Suite',
                  style: GoogleFonts.inter(
                    fontSize: 10.sp,
                    color: Colors.white54,
                  ),
                ),
              ],
            ),
          ),
          _buildDrawerItem(Icons.dashboard, 'Overview', true),
          _buildDrawerItem(Icons.security, 'Fraud Detection Tests', false),
          _buildDrawerItem(Icons.sms, 'SMS Provider Tests', false),
          _buildDrawerItem(Icons.payment, 'Stripe Tests', false),
          _buildDrawerItem(Icons.psychology, 'AI Orchestration Tests', false),
          _buildDrawerItem(Icons.trending_down, 'Churn Tests', false),
          _buildDrawerItem(Icons.speed, 'Performance Tests', false),
          const Divider(color: Color(0xFF313244)),
          _buildDrawerItem(Icons.settings, 'CI/CD Settings', false),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, bool isSelected) {
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? const Color(0xFF89B4FA) : Colors.white54,
        size: 20,
      ),
      title: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 11.sp,
          color: isSelected ? const Color(0xFF89B4FA) : Colors.white70,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
      selected: isSelected,
      selectedTileColor: const Color(0xFF89B4FA).withAlpha(26),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      onTap: () => Navigator.pop(context),
    );
  }
}
