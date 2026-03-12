import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class CiCdIntegrationWidget extends StatelessWidget {
  const CiCdIntegrationWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'CI/CD Integration',
          style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 1.h),
        Text(
          'GitHub Actions workflow status with automated test execution on pull requests',
          style: TextStyle(fontSize: 12.sp, color: Colors.black54),
        ),
        SizedBox(height: 2.h),
        _buildPipelineStatus(),
        SizedBox(height: 2.h),
        _buildWorkflowRuns(),
        SizedBox(height: 2.h),
        _buildPerformanceBenchmarks(),
        SizedBox(height: 2.h),
        _buildIntegrationSettings(),
      ],
    );
  }

  Widget _buildPipelineStatus() {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4CAF50), Color(0xFF388E3C)],
        ),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: Colors.white, size: 24.sp),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pipeline Status: Passing',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 0.5.h),
                Text(
                  'Last run: 2 hours ago • Duration: 8.2s',
                  style: TextStyle(fontSize: 12.sp, color: Colors.white70),
                ),
              ],
            ),
          ),
          Icon(Icons.open_in_new, color: Colors.white, size: 18.sp),
        ],
      ),
    );
  }

  Widget _buildWorkflowRuns() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Workflow Runs',
          style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 1.h),
        _buildWorkflowCard(
          branch: 'main',
          commit: 'feat: add gamification tests',
          status: 'success',
          duration: '8.2s',
          time: '2 hours ago',
        ),
        SizedBox(height: 1.h),
        _buildWorkflowCard(
          branch: 'develop',
          commit: 'fix: update test assertions',
          status: 'success',
          duration: '7.9s',
          time: '5 hours ago',
        ),
        SizedBox(height: 1.h),
        _buildWorkflowCard(
          branch: 'feature/vp-tests',
          commit: 'test: add VP earning tests',
          status: 'success',
          duration: '8.5s',
          time: '1 day ago',
        ),
      ],
    );
  }

  Widget _buildWorkflowCard({
    required String branch,
    required String commit,
    required String status,
    required String duration,
    required String time,
  }) {
    final isSuccess = status == 'success';
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
              Icon(
                isSuccess ? Icons.check_circle : Icons.error,
                color: isSuccess ? Colors.green : Colors.red,
                size: 18.sp,
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: Text(
                  commit,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                decoration: BoxDecoration(
                  color: isSuccess
                      ? Colors.green.withAlpha(26)
                      : Colors.red.withAlpha(26),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.bold,
                    color: isSuccess ? Colors.green : Colors.red,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Row(
            children: [
              Icon(Icons.code_outlined, size: 14.sp, color: Colors.black54),
              SizedBox(width: 1.w),
              Text(
                branch,
                style: TextStyle(fontSize: 11.sp, color: Colors.black54),
              ),
              SizedBox(width: 2.w),
              Icon(Icons.schedule, size: 14.sp, color: Colors.black54),
              SizedBox(width: 1.w),
              Text(
                duration,
                style: TextStyle(fontSize: 11.sp, color: Colors.black54),
              ),
              SizedBox(width: 2.w),
              Icon(Icons.access_time, size: 14.sp, color: Colors.black54),
              SizedBox(width: 1.w),
              Text(
                time,
                style: TextStyle(fontSize: 11.sp, color: Colors.black54),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceBenchmarks() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Performance Benchmarks',
          style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 1.h),
        Container(
          padding: EdgeInsets.all(2.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12.0),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            children: [
              _buildBenchmarkRow(
                'VP Earning Quest Tests',
                '2.3s',
                'Target: <3s',
                true,
              ),
              const Divider(),
              _buildBenchmarkRow(
                'Prediction Pool Tests',
                '3.1s',
                'Target: <4s',
                true,
              ),
              const Divider(),
              _buildBenchmarkRow(
                'Ad Mini-game Tests',
                '2.8s',
                'Target: <3s',
                true,
              ),
              const Divider(),
              _buildBenchmarkRow(
                'Total Suite Execution',
                '8.2s',
                'Target: <30s',
                true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBenchmarkRow(
    String name,
    String actual,
    String target,
    bool meetsTarget,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 1.h),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 0.5.h),
                Text(
                  target,
                  style: TextStyle(fontSize: 11.sp, color: Colors.black54),
                ),
              ],
            ),
          ),
          Row(
            children: [
              Text(
                actual,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  color: meetsTarget ? Colors.green : Colors.red,
                ),
              ),
              SizedBox(width: 1.w),
              Icon(
                meetsTarget ? Icons.check_circle : Icons.warning,
                color: meetsTarget ? Colors.green : Colors.red,
                size: 18.sp,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIntegrationSettings() {
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
            'Integration Settings',
            style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 1.h),
          SwitchListTile(
            title: const Text('Run on Pull Requests'),
            subtitle: const Text('Automatically run tests on PRs'),
            value: true,
            onChanged: (value) {},
            contentPadding: EdgeInsets.zero,
          ),
          SwitchListTile(
            title: const Text('Run on Push to Main'),
            subtitle: const Text('Execute tests on main branch commits'),
            value: true,
            onChanged: (value) {},
            contentPadding: EdgeInsets.zero,
          ),
          SwitchListTile(
            title: const Text('Block Merge on Failure'),
            subtitle: const Text('Prevent merging if tests fail'),
            value: true,
            onChanged: (value) {},
            contentPadding: EdgeInsets.zero,
          ),
          SwitchListTile(
            title: const Text('Send Notifications'),
            subtitle: const Text('Notify team on test failures'),
            value: false,
            onChanged: (value) {},
            contentPadding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }
}
