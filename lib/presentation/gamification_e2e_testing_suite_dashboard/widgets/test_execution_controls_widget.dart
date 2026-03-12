import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class TestExecutionControlsWidget extends StatelessWidget {
  final bool isRunning;
  final VoidCallback onRunTests;
  final VoidCallback onStopTests;

  const TestExecutionControlsWidget({
    super.key,
    required this.isRunning,
    required this.onRunTests,
    required this.onStopTests,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Test Execution Controls',
          style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 2.h),
        _buildExecutionStatus(),
        SizedBox(height: 2.h),
        _buildControlButtons(context),
        SizedBox(height: 2.h),
        _buildExecutionOptions(),
        SizedBox(height: 2.h),
        _buildRecentExecutions(),
      ],
    );
  }

  Widget _buildExecutionStatus() {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isRunning
              ? [Colors.orange.shade400, Colors.orange.shade600]
              : [Colors.green.shade400, Colors.green.shade600],
        ),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Row(
        children: [
          Icon(
            isRunning ? Icons.hourglass_empty : Icons.check_circle,
            color: Colors.white,
            size: 24.sp,
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isRunning ? 'Tests Running' : 'Ready to Execute',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 0.5.h),
                Text(
                  isRunning
                      ? 'Executing test suites... Please wait'
                      : 'All test suites ready for execution',
                  style: TextStyle(fontSize: 12.sp, color: Colors.white70),
                ),
              ],
            ),
          ),
          if (isRunning)
            const CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
        ],
      ),
    );
  }

  Widget _buildControlButtons(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: isRunning ? null : onRunTests,
            icon: const Icon(Icons.play_arrow),
            label: const Text('Run All Test Suites'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E88E5),
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.grey.shade300,
              padding: EdgeInsets.symmetric(vertical: 1.5.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
            ),
          ),
        ),
        SizedBox(height: 1.h),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: isRunning ? onStopTests : null,
                icon: const Icon(Icons.stop),
                label: const Text('Stop Tests'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  disabledForegroundColor: Colors.grey,
                  padding: EdgeInsets.symmetric(vertical: 1.5.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                ),
              ),
            ),
            SizedBox(width: 2.w),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Clearing test results...')),
                  );
                },
                icon: const Icon(Icons.clear_all),
                label: const Text('Clear Results'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF1E88E5),
                  padding: EdgeInsets.symmetric(vertical: 1.5.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildExecutionOptions() {
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
            'Execution Options',
            style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 1.h),
          CheckboxListTile(
            title: const Text('Verbose Logging'),
            subtitle: const Text('Enable detailed test execution logs'),
            value: true,
            onChanged: (value) {},
            contentPadding: EdgeInsets.zero,
          ),
          CheckboxListTile(
            title: const Text('Parallel Execution'),
            subtitle: const Text('Run test suites in parallel'),
            value: false,
            onChanged: (value) {},
            contentPadding: EdgeInsets.zero,
          ),
          CheckboxListTile(
            title: const Text('Auto-retry Failed Tests'),
            subtitle: const Text('Retry failed tests automatically'),
            value: false,
            onChanged: (value) {},
            contentPadding: EdgeInsets.zero,
          ),
          CheckboxListTile(
            title: const Text('Generate Coverage Report'),
            subtitle: const Text('Create detailed coverage analysis'),
            value: true,
            onChanged: (value) {},
            contentPadding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  Widget _buildRecentExecutions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Executions',
          style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 1.h),
        _buildExecutionCard(
          time: '2 hours ago',
          duration: '8.2s',
          status: 'passed',
          tests: 30,
        ),
        SizedBox(height: 1.h),
        _buildExecutionCard(
          time: '5 hours ago',
          duration: '7.9s',
          status: 'passed',
          tests: 30,
        ),
        SizedBox(height: 1.h),
        _buildExecutionCard(
          time: '1 day ago',
          duration: '8.5s',
          status: 'passed',
          tests: 30,
        ),
      ],
    );
  }

  Widget _buildExecutionCard({
    required String time,
    required String duration,
    required String status,
    required int tests,
  }) {
    final isPassed = status == 'passed';
    return Container(
      padding: EdgeInsets.all(2.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(
            isPassed ? Icons.check_circle : Icons.error,
            color: isPassed ? Colors.green : Colors.red,
            size: 20.sp,
          ),
          SizedBox(width: 2.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Test Suite Execution',
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 0.5.h),
                Text(
                  '$time • $duration • $tests tests',
                  style: TextStyle(fontSize: 11.sp, color: Colors.black54),
                ),
              ],
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
    );
  }
}
