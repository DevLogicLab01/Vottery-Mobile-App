import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class PredictionPoolTestWidget extends StatelessWidget {
  final VoidCallback onRunTest;
  final Map<String, dynamic>? testResults;

  const PredictionPoolTestWidget({
    super.key,
    required this.onRunTest,
    this.testResults,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Prediction Pool Lifecycle Tests',
          style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 1.h),
        Text(
          'Testing: pool creation → user prediction submission → election resolution → Brier score calculation → VP reward distribution → leaderboard update',
          style: TextStyle(fontSize: 12.sp, color: Colors.black54),
        ),
        SizedBox(height: 2.h),
        if (testResults != null) _buildTestResults(),
        SizedBox(height: 2.h),
        _buildTestCases(),
        SizedBox(height: 2.h),
        _buildRunButton(context),
      ],
    );
  }

  Widget _buildTestResults() {
    final status = testResults!['status'] as String;
    final isPassed = status == 'passed';
    return Container(
      padding: EdgeInsets.all(2.w),
      decoration: BoxDecoration(
        color: isPassed ? Colors.green.withAlpha(26) : Colors.red.withAlpha(26),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: isPassed ? Colors.green : Colors.red,
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isPassed ? Icons.check_circle : Icons.error,
                color: isPassed ? Colors.green : Colors.red,
                size: 20.sp,
              ),
              SizedBox(width: 2.w),
              Text(
                'Test Results',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  color: isPassed ? Colors.green : Colors.red,
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          _buildResultRow('Duration', testResults!['duration']),
          _buildResultRow('Tests Passed', '${testResults!['tests_passed']}'),
          _buildResultRow('Tests Failed', '${testResults!['tests_failed']}'),
          _buildResultRow('Coverage', testResults!['coverage']),
        ],
      ),
    );
  }

  Widget _buildResultRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 0.5.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 12.sp, color: Colors.black54),
          ),
          Text(
            value,
            style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildTestCases() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Test Cases',
          style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 1.h),
        _buildTestCase(
          '1. Pool Creation',
          'Verify prediction pool created with correct parameters',
          Icons.add_circle,
        ),
        _buildTestCase(
          '2. User Prediction Submission',
          'Test multiple users submitting predictions',
          Icons.how_to_vote,
        ),
        _buildTestCase(
          '3. Election Resolution',
          'Verify election outcome recorded correctly',
          Icons.check_circle,
        ),
        _buildTestCase(
          '4. Brier Score Calculation',
          'Test accuracy score calculation for predictions',
          Icons.calculate,
        ),
        _buildTestCase(
          '5. VP Reward Distribution',
          'Verify VP rewards distributed based on accuracy',
          Icons.card_giftcard,
        ),
        _buildTestCase(
          '6. Leaderboard Update',
          'Check leaderboard positions updated correctly',
          Icons.leaderboard,
        ),
        _buildTestCase(
          '7. Pool Closure',
          'Test pool closure after resolution',
          Icons.lock,
        ),
        _buildTestCase(
          '8. Edge Cases',
          'Test tie scenarios and zero participants',
          Icons.warning,
        ),
        _buildTestCase(
          '9. Transaction Verification',
          'Verify all VP transactions logged',
          Icons.receipt,
        ),
        _buildTestCase(
          '10. Notification System',
          'Test winner notifications sent correctly',
          Icons.notifications,
        ),
        _buildTestCase(
          '11. Analytics Tracking',
          'Verify prediction analytics captured',
          Icons.analytics,
        ),
        _buildTestCase(
          '12. Error Recovery',
          'Test system recovery from calculation errors',
          Icons.error_outline,
        ),
      ],
    );
  }

  Widget _buildTestCase(String title, String description, IconData icon) {
    return Container(
      margin: EdgeInsets.only(bottom: 1.h),
      padding: EdgeInsets.all(2.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF1E88E5), size: 18.sp),
          SizedBox(width: 2.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 0.5.h),
                Text(
                  description,
                  style: TextStyle(fontSize: 11.sp, color: Colors.black54),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRunButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          onRunTest();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Running Prediction Pool Lifecycle tests...'),
              duration: Duration(seconds: 2),
            ),
          );
        },
        icon: const Icon(Icons.play_arrow),
        label: const Text('Run Prediction Pool Tests'),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1E88E5),
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: 1.5.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
        ),
      ),
    );
  }
}
