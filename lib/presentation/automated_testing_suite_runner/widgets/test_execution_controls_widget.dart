import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class TestExecutionControlsWidget extends StatelessWidget {
  final VoidCallback onRunTests;
  final bool isRunning;

  const TestExecutionControlsWidget({
    super.key,
    required this.onRunTests,
    required this.isRunning,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Test Execution Controls',
            style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 1.h),
          Text(
            'One-tap test runs for different test suites with automated execution',
            style: TextStyle(fontSize: 12.sp, color: Colors.grey),
          ),
          SizedBox(height: 3.h),
          _buildTestSuiteCard(
            'Run All Tests',
            'Execute unit, integration, and E2E tests',
            Icons.play_circle_filled,
            Colors.blue,
            onRunTests,
            isRunning,
          ),
          SizedBox(height: 2.h),
          _buildTestSuiteCard(
            'Run Unit Tests Only',
            'Fast execution for unit tests',
            Icons.code,
            Colors.green,
            () {},
            false,
          ),
          SizedBox(height: 2.h),
          _buildTestSuiteCard(
            'Run Integration Tests',
            'Test component interactions',
            Icons.integration_instructions,
            Colors.orange,
            () {},
            false,
          ),
          SizedBox(height: 2.h),
          _buildTestSuiteCard(
            'Run E2E Tests',
            'Full user journey testing',
            Icons.devices,
            Colors.purple,
            () {},
            false,
          ),
        ],
      ),
    );
  }

  Widget _buildTestSuiteCard(
    String title,
    String description,
    IconData icon,
    Color color,
    VoidCallback onTap,
    bool isRunning,
  ) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: isRunning ? null : onTap,
        child: Padding(
          padding: EdgeInsets.all(3.w),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(2.w),
                decoration: BoxDecoration(
                  color: color.withAlpha(26),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Icon(icon, color: color, size: 32.sp),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 0.5.h),
                    Text(
                      description,
                      style: TextStyle(fontSize: 11.sp, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              if (isRunning)
                SizedBox(
                  width: 24.0,
                  height: 24.0,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.0,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                )
              else
                Icon(Icons.arrow_forward_ios, size: 16.sp, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
