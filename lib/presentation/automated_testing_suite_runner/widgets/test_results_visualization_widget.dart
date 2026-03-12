import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class TestResultsVisualizationWidget extends StatelessWidget {
  final Map<String, dynamic> testResults;

  const TestResultsVisualizationWidget({super.key, required this.testResults});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Test Results Visualization',
            style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 1.h),
          Text(
            'Pass/fail breakdowns and error logs for all test suites',
            style: TextStyle(fontSize: 12.sp, color: Colors.grey),
          ),
          SizedBox(height: 3.h),
          _buildTestSuiteResults('Unit Tests', testResults['unit_tests']),
          SizedBox(height: 2.h),
          _buildTestSuiteResults(
            'Integration Tests',
            testResults['integration_tests'],
          ),
          SizedBox(height: 2.h),
          _buildTestSuiteResults('E2E Tests', testResults['e2e_tests']),
        ],
      ),
    );
  }

  Widget _buildTestSuiteResults(String title, Map<String, dynamic>? results) {
    if (results == null) return const SizedBox.shrink();

    final passed = results['passed'] ?? 0;
    final failed = results['failed'] ?? 0;
    final skipped = results['skipped'] ?? 0;
    final total = passed + failed + skipped;

    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 2.h),
            Row(
              children: [
                Expanded(
                  child: _buildResultMetric('Passed', passed, Colors.green),
                ),
                Expanded(
                  child: _buildResultMetric('Failed', failed, Colors.red),
                ),
                Expanded(
                  child: _buildResultMetric('Skipped', skipped, Colors.grey),
                ),
              ],
            ),
            SizedBox(height: 2.h),
            LinearProgressIndicator(
              value: total > 0 ? passed / total : 0,
              backgroundColor: Colors.grey[200],
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
              minHeight: 1.h,
            ),
            SizedBox(height: 1.h),
            Text(
              '${(total > 0 ? (passed / total * 100) : 0).toStringAsFixed(1)}% passing',
              style: TextStyle(fontSize: 11.sp, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultMetric(String label, int value, Color color) {
    return Column(
      children: [
        Text(
          value.toString(),
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        SizedBox(height: 0.5.h),
        Text(
          label,
          style: TextStyle(fontSize: 11.sp, color: Colors.grey),
        ),
      ],
    );
  }
}
