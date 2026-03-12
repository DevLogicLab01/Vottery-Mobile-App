import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../../theme/app_theme.dart';

class CICDPipelineWidget extends StatelessWidget {
  final Map<String, dynamic> pipelineStatus;
  final VoidCallback onRefresh;

  const CICDPipelineWidget({
    super.key,
    required this.pipelineStatus,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final healthStatus = pipelineStatus['health_status'] ?? 'unknown';
    final lastRun = pipelineStatus['last_run_time'] ?? 'Never';
    final buildSuccessRate = pipelineStatus['build_success_rate'] ?? 0.0;
    final workflows = pipelineStatus['workflows'] ?? [];

    return ListView(
      padding: EdgeInsets.all(4.w),
      children: [
        Text(
          'GitHub Actions CI/CD Pipeline',
          style: GoogleFonts.inter(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 2.h),
        _buildHealthCard(healthStatus, lastRun, buildSuccessRate),
        SizedBox(height: 2.h),
        Text(
          'Active Workflows',
          style: GoogleFonts.inter(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 1.h),
        ...workflows.map((workflow) => _buildWorkflowCard(workflow)),
      ],
    );
  }

  Widget _buildHealthCard(String status, String lastRun, double successRate) {
    final isHealthy = status == 'healthy';
    final color = isHealthy ? Colors.green : Colors.orange;

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 4.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                isHealthy ? Icons.check_circle : Icons.warning,
                color: color,
                size: 10.w,
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pipeline Status: ${status.toUpperCase()}',
                      style: GoogleFonts.inter(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    Text(
                      'Last run: $lastRun',
                      style: GoogleFonts.inter(
                        fontSize: 11.sp,
                        color: AppTheme.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMetric(
                'Success Rate',
                '${successRate.toStringAsFixed(1)}%',
                Colors.green,
              ),
              _buildMetric('Avg Duration', '3.2 min', Colors.blue),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWorkflowCard(Map<String, dynamic> workflow) {
    final name = workflow['name'] ?? 'Unknown';
    final status = workflow['status'] ?? 'pending';
    final duration = workflow['duration'] ?? '0s';

    Color statusColor;
    IconData statusIcon;
    switch (status) {
      case 'success':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'failed':
        statusColor = Colors.red;
        statusIcon = Icons.error;
        break;
      default:
        statusColor = Colors.orange;
        statusIcon = Icons.pending;
    }

    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(statusIcon, color: statusColor, size: 6.w),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Duration: $duration',
                  style: GoogleFonts.inter(
                    fontSize: 10.sp,
                    color: AppTheme.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetric(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11.sp,
            color: AppTheme.textSecondaryLight,
          ),
        ),
      ],
    );
  }
}
