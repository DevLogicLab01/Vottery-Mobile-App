import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class AdMinigameBlockchainTestWidget extends StatelessWidget {
  final VoidCallback onRunTest;
  final Map<String, dynamic>? testResults;

  const AdMinigameBlockchainTestWidget({
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
          'Ad Mini-game → Blockchain Tests',
          style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 1.h),
        Text(
          'Testing: ad view → spin wheel game → VP reward → blockchain transaction logging → merkle root generation → blockchain verification via web3dart → audit trail creation',
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
          '1. Ad View Tracking',
          'Verify ad impression logged correctly',
          Icons.visibility,
        ),
        _buildTestCase(
          '2. Spin Wheel Game',
          'Test mini-game mechanics and randomization',
          Icons.casino,
        ),
        _buildTestCase(
          '3. VP Reward Calculation',
          'Verify correct VP amount awarded',
          Icons.card_giftcard,
        ),
        _buildTestCase(
          '4. Blockchain Transaction Logging',
          'Test transaction recorded on blockchain',
          Icons.link,
        ),
        _buildTestCase(
          '5. Merkle Root Generation',
          'Verify merkle root calculated correctly',
          Icons.account_tree,
        ),
        _buildTestCase(
          '6. Web3dart Verification',
          'Test blockchain verification via web3dart',
          Icons.verified,
        ),
        _buildTestCase(
          '7. Audit Trail Creation',
          'Verify complete audit trail generated',
          Icons.history,
        ),
        _buildTestCase(
          '8. Hash Validation',
          'Test blockchain hash integrity',
          Icons.fingerprint,
        ),
        _buildTestCase(
          '9. Transaction Confirmation',
          'Verify transaction confirmation received',
          Icons.check_circle_outline,
        ),
        _buildTestCase(
          '10. Error Handling',
          'Test blockchain connection failures',
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
              content: Text('Running Ad Mini-game Blockchain tests...'),
              duration: Duration(seconds: 2),
            ),
          );
        },
        icon: const Icon(Icons.play_arrow),
        label: const Text('Run Ad Mini-game Tests'),
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
