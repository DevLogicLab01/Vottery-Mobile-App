import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class TestResultsAnalyticsWidget extends StatelessWidget {
  final Map<String, dynamic> testResults;

  const TestResultsAnalyticsWidget({super.key, required this.testResults});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Test Results Analytics',
          style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 2.h),
        _buildOverallMetrics(),
        SizedBox(height: 2.h),
        _buildSuiteBreakdown(),
        SizedBox(height: 2.h),
        _buildCoverageAnalysis(),
        SizedBox(height: 2.h),
        _buildTrendAnalysis(),
      ],
    );
  }

  Widget _buildOverallMetrics() {
    final totalTests = _calculateTotalTests();
    final totalPassed = _calculateTotalPassed();
    final successRate = totalTests > 0
        ? (totalPassed / totalTests * 100).toStringAsFixed(1)
        : '0.0';
    final avgDuration = _calculateAvgDuration();

    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E88E5), Color(0xFF1565C0)],
        ),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        children: [
          Text(
            'Overall Test Metrics',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 2.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMetricColumn('Total Tests', '$totalTests', Icons.science),
              _buildMetricColumn('Passed', '$totalPassed', Icons.check_circle),
              _buildMetricColumn(
                'Success Rate',
                '$successRate%',
                Icons.trending_up,
              ),
              _buildMetricColumn('Avg Duration', avgDuration, Icons.schedule),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricColumn(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 20.sp),
        SizedBox(height: 0.5.h),
        Text(
          value,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 10.sp, color: Colors.white70),
        ),
      ],
    );
  }

  Widget _buildSuiteBreakdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Test Suite Breakdown',
          style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 1.h),
        if (testResults.containsKey('vp_tests'))
          _buildSuiteCard(
            'VP Earning Quest Tests',
            testResults['vp_tests'],
            Icons.attach_money,
          ),
        if (testResults.containsKey('prediction_tests')) SizedBox(height: 1.h),
        if (testResults.containsKey('prediction_tests'))
          _buildSuiteCard(
            'Prediction Pool Tests',
            testResults['prediction_tests'],
            Icons.poll,
          ),
        if (testResults.containsKey('ad_tests')) SizedBox(height: 1.h),
        if (testResults.containsKey('ad_tests'))
          _buildSuiteCard(
            'Ad Mini-game Tests',
            testResults['ad_tests'],
            Icons.games,
          ),
        if (testResults.isEmpty)
          Container(
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Center(
              child: Text(
                'No test results available. Run tests to see analytics.',
                style: TextStyle(fontSize: 12.sp, color: Colors.black54),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSuiteCard(
    String name,
    Map<String, dynamic> results,
    IconData icon,
  ) {
    final status = results['status'] as String;
    final isPassed = status == 'passed';
    return Container(
      padding: EdgeInsets.all(2.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF1E88E5), size: 18.sp),
              SizedBox(width: 2.w),
              Expanded(
                child: Text(
                  name,
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                decoration: BoxDecoration(
                  color: isPassed
                      ? Colors.green.withAlpha(26)
                      : Colors.red.withAlpha(26),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.bold,
                    color: isPassed ? Colors.green : Colors.red,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildResultDetail('Duration', results['duration']),
              _buildResultDetail('Passed', '${results['tests_passed']}'),
              _buildResultDetail('Failed', '${results['tests_failed']}'),
              _buildResultDetail('Coverage', results['coverage']),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResultDetail(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 10.sp, color: Colors.black54),
        ),
      ],
    );
  }

  Widget _buildCoverageAnalysis() {
    return Container(
      padding: EdgeInsets.all(2.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Coverage Analysis',
            style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 1.h),
          _buildCoverageBar('Gamification Service', 87, Colors.green),
          SizedBox(height: 1.h),
          _buildCoverageBar('VP Service', 92, Colors.green),
          SizedBox(height: 1.h),
          _buildCoverageBar('Prediction Service', 85, Colors.green),
          SizedBox(height: 1.h),
          _buildCoverageBar('Blockchain Service', 78, Colors.orange),
        ],
      ),
    );
  }

  Widget _buildCoverageBar(String name, int percentage, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              name,
              style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600),
            ),
            Text(
              '$percentage%',
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        SizedBox(height: 0.5.h),
        LinearProgressIndicator(
          value: percentage / 100,
          backgroundColor: Colors.grey.shade200,
          valueColor: AlwaysStoppedAnimation<Color>(color),
          minHeight: 8,
        ),
      ],
    );
  }

  Widget _buildTrendAnalysis() {
    return Container(
      padding: EdgeInsets.all(2.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Trend Analysis (Last 7 Days)',
            style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 1.h),
          _buildTrendRow('Test Executions', '42', '+12%', true),
          const Divider(),
          _buildTrendRow('Success Rate', '98.5%', '+2.1%', true),
          const Divider(),
          _buildTrendRow('Avg Duration', '8.3s', '-0.5s', true),
          const Divider(),
          _buildTrendRow('Coverage', '87%', '+3%', true),
        ],
      ),
    );
  }

  Widget _buildTrendRow(
    String metric,
    String value,
    String change,
    bool isPositive,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 1.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            metric,
            style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600),
          ),
          Row(
            children: [
              Text(
                value,
                style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold),
              ),
              SizedBox(width: 2.w),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 1.5.w,
                  vertical: 0.5.h,
                ),
                decoration: BoxDecoration(
                  color: isPositive
                      ? Colors.green.withAlpha(26)
                      : Colors.red.withAlpha(26),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Row(
                  children: [
                    Icon(
                      isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                      size: 12.sp,
                      color: isPositive ? Colors.green : Colors.red,
                    ),
                    Text(
                      change,
                      style: TextStyle(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.bold,
                        color: isPositive ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  int _calculateTotalTests() {
    int total = 0;
    for (var result in testResults.values) {
      if (result is Map<String, dynamic>) {
        total += (result['tests_passed'] as int? ?? 0);
        total += (result['tests_failed'] as int? ?? 0);
      }
    }
    return total;
  }

  int _calculateTotalPassed() {
    int total = 0;
    for (var result in testResults.values) {
      if (result is Map<String, dynamic>) {
        total += (result['tests_passed'] as int? ?? 0);
      }
    }
    return total;
  }

  String _calculateAvgDuration() {
    if (testResults.isEmpty) return '0s';
    double totalSeconds = 0;
    int count = 0;
    for (var result in testResults.values) {
      if (result is Map<String, dynamic> && result.containsKey('duration')) {
        final duration = result['duration'] as String;
        final seconds = double.tryParse(duration.replaceAll('s', '')) ?? 0;
        totalSeconds += seconds;
        count++;
      }
    }
    return count > 0 ? '${(totalSeconds / count).toStringAsFixed(1)}s' : '0s';
  }
}
