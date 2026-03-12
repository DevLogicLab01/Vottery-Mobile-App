import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class CiCdPipelineWidget extends StatelessWidget {
  final Map<String, dynamic> cicdStatus;

  const CiCdPipelineWidget({super.key, required this.cicdStatus});

  @override
  Widget build(BuildContext context) {
    final pipelineStatus = cicdStatus['pipeline_status'] ?? 'unknown';
    final lastRun = cicdStatus['last_run'] as DateTime?;
    final buildDuration = cicdStatus['build_duration'] ?? 0;
    final githubStatus = cicdStatus['github_actions_status'] ?? 'unknown';

    final isPassing = pipelineStatus == 'passing';

    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'CI/CD Pipeline Status',
            style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 1.h),
          Text(
            'Monitor GitHub Actions workflow status and automated test execution',
            style: TextStyle(fontSize: 12.sp, color: Colors.grey),
          ),
          SizedBox(height: 3.h),
          Card(
            elevation: 2,
            color: isPassing ? Colors.green.shade50 : Colors.red.shade50,
            child: Padding(
              padding: EdgeInsets.all(3.w),
              child: Row(
                children: [
                  Icon(
                    isPassing ? Icons.check_circle : Icons.error,
                    color: isPassing ? Colors.green : Colors.red,
                    size: 40.sp,
                  ),
                  SizedBox(width: 3.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isPassing ? 'Pipeline Passing' : 'Pipeline Failing',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                            color: isPassing ? Colors.green : Colors.red,
                          ),
                        ),
                        SizedBox(height: 0.5.h),
                        if (lastRun != null)
                          Text(
                            'Last run: ${_formatDateTime(lastRun)}',
                            style: TextStyle(
                              fontSize: 11.sp,
                              color: Colors.grey[700],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 2.h),
          _buildStatusCard(
            'GitHub Actions',
            githubStatus,
            Icons.code,
            Colors.blue,
          ),
          SizedBox(height: 2.h),
          _buildMetricCard(
            'Build Duration',
            '${buildDuration}s',
            Icons.timer,
            Colors.orange,
          ),
          SizedBox(height: 3.h),
          _buildWorkflowSteps(),
        ],
      ),
    );
  }

  Widget _buildStatusCard(
    String title,
    String status,
    IconData icon,
    Color color,
  ) {
    final isSuccess = status == 'success';

    return Card(
      elevation: 2,
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
              child: Icon(icon, color: color, size: 24.sp),
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: Text(
                title,
                style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
              decoration: BoxDecoration(
                color: isSuccess ? Colors.green : Colors.red,
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Text(
                status.toUpperCase(),
                style: TextStyle(fontSize: 10.sp, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 2,
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
              child: Icon(icon, color: color, size: 24.sp),
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: Text(
                title,
                style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkflowSteps() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Workflow Steps',
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 2.h),
            _buildWorkflowStep('Checkout Code', true, '5s'),
            _buildWorkflowStep('Install Dependencies', true, '45s'),
            _buildWorkflowStep('Run Unit Tests', true, '120s'),
            _buildWorkflowStep('Run Integration Tests', true, '180s'),
            _buildWorkflowStep('Build Application', true, '70s'),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkflowStep(String step, bool success, String duration) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 1.h),
      child: Row(
        children: [
          Icon(
            success ? Icons.check_circle : Icons.error,
            color: success ? Colors.green : Colors.red,
            size: 20.sp,
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Text(
              step,
              style: TextStyle(fontSize: 12.sp, color: Colors.grey[700]),
            ),
          ),
          Text(
            duration,
            style: TextStyle(fontSize: 11.sp, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}
