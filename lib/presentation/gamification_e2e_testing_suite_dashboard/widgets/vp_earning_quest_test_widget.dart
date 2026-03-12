import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class VpEarningQuestTestWidget extends StatelessWidget {
  final VoidCallback onRunTest;
  final Map<String, dynamic>? testResults;

  const VpEarningQuestTestWidget({
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
          'VP Earning → Quest → Redemption Tests',
          style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 1.h),
        Text(
          'Complete flow testing: vote cast → 10 VP earned → quest progress updated → quest completed → 50 VP reward → rewards shop redemption → VP deducted → item unlocked',
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
          '1. Vote Cast → VP Earned',
          'Verify 10 VP credited after vote submission',
          Icons.how_to_vote,
        ),
        _buildTestCase(
          '2. Quest Progress Update',
          'Check quest progress increments correctly',
          Icons.trending_up,
        ),
        _buildTestCase(
          '3. Quest Completion',
          'Verify 50 VP reward on quest completion',
          Icons.emoji_events,
        ),
        _buildTestCase(
          '4. Rewards Shop Redemption',
          'Test VP deduction and item unlock',
          Icons.shopping_cart,
        ),
        _buildTestCase(
          '5. VP Balance Verification',
          'Confirm accurate VP balance throughout flow',
          Icons.account_balance_wallet,
        ),
        _buildTestCase(
          '6. Transaction Logging',
          'Verify all transactions recorded correctly',
          Icons.receipt_long,
        ),
        _buildTestCase(
          '7. Leaderboard Update',
          'Check leaderboard position after VP changes',
          Icons.leaderboard,
        ),
        _buildTestCase(
          '8. Error Handling',
          'Test insufficient VP and network failures',
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
              content: Text('Running VP Earning Quest Redemption tests...'),
              duration: Duration(seconds: 2),
            ),
          );
        },
        icon: const Icon(Icons.play_arrow),
        label: const Text('Run VP Test Suite'),
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
