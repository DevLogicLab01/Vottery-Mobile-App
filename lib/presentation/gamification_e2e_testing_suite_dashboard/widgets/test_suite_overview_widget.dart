import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class TestSuiteOverviewWidget extends StatelessWidget {
  final VoidCallback onRunAllTests;

  const TestSuiteOverviewWidget({super.key, required this.onRunAllTests});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Test Suite Overview',
          style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 2.h),
        _buildMetricsGrid(),
        SizedBox(height: 2.h),
        _buildTestSuitesSection(),
        SizedBox(height: 2.h),
        _buildQuickActionsSection(context),
      ],
    );
  }

  Widget _buildMetricsGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 2.w,
      mainAxisSpacing: 2.h,
      childAspectRatio: 1.5,
      children: [
        _buildMetricCard(
          icon: Icons.check_circle,
          title: 'Test Coverage',
          value: '87%',
          subtitle: 'Target: >80%',
          color: Colors.green,
        ),
        _buildMetricCard(
          icon: Icons.speed,
          title: 'Avg Execution Time',
          value: '28s',
          subtitle: 'Target: <30s',
          color: Colors.blue,
        ),
        _buildMetricCard(
          icon: Icons.bug_report,
          title: 'Failed Tests',
          value: '0',
          subtitle: 'Last 24 hours',
          color: Colors.orange,
        ),
        _buildMetricCard(
          icon: Icons.trending_up,
          title: 'Success Rate',
          value: '100%',
          subtitle: 'Last 50 runs',
          color: Colors.purple,
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required IconData icon,
    required String title,
    required String value,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(2.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20.sp),
              SizedBox(width: 2.w),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(fontSize: 12.sp, color: Colors.black54),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(fontSize: 10.sp, color: Colors.black38),
          ),
        ],
      ),
    );
  }

  Widget _buildTestSuitesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Test Suites',
          style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 1.h),
        _buildTestSuiteCard(
          title: 'VP Earning → Quest → Redemption',
          tests: 8,
          status: 'passed',
          lastRun: '2 hours ago',
        ),
        SizedBox(height: 1.h),
        _buildTestSuiteCard(
          title: 'Prediction Pool Lifecycle',
          tests: 12,
          status: 'passed',
          lastRun: '3 hours ago',
        ),
        SizedBox(height: 1.h),
        _buildTestSuiteCard(
          title: 'Ad Mini-game → Blockchain',
          tests: 10,
          status: 'passed',
          lastRun: '1 hour ago',
        ),
      ],
    );
  }

  Widget _buildTestSuiteCard({
    required String title,
    required int tests,
    required String status,
    required String lastRun,
  }) {
    final statusColor = status == 'passed' ? Colors.green : Colors.red;
    return Container(
      padding: EdgeInsets.all(2.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.science, color: Colors.blue, size: 20.sp),
          SizedBox(width: 2.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 0.5.h),
                Text(
                  '$tests tests • Last run: $lastRun',
                  style: TextStyle(fontSize: 11.sp, color: Colors.black54),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
            decoration: BoxDecoration(
              color: statusColor.withAlpha(26),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Text(
              status.toUpperCase(),
              style: TextStyle(
                fontSize: 10.sp,
                fontWeight: FontWeight.bold,
                color: statusColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 1.h),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: onRunAllTests,
                icon: const Icon(Icons.play_arrow),
                label: const Text('Run All Tests'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E88E5),
                  foregroundColor: Colors.white,
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
                    const SnackBar(
                      content: Text('Generating coverage report...'),
                    ),
                  );
                },
                icon: const Icon(Icons.assessment),
                label: const Text('Coverage Report'),
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
}
