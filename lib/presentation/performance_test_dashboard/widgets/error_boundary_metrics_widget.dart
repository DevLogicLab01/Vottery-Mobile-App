import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../theme/app_theme.dart';

class ErrorBoundaryMetricsWidget extends StatelessWidget {
  final Map<String, dynamic> metrics;

  const ErrorBoundaryMetricsWidget({super.key, required this.metrics});

  @override
  Widget build(BuildContext context) {
    final avgRecoveryTime = metrics['average_recovery_latency_ms'] ?? 0.0;
    final recoveryRate = metrics['recovery_rate_percentage'] ?? 0.0;
    final totalErrors = metrics['total_errors_caught'] ?? 0;
    final successfulRecoveries = metrics['successful_recoveries'] ?? 0;
    final screensTested = metrics['screens_tested'] as List<dynamic>? ?? [];

    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMetricCard(
            'Average Recovery Time',
            '${avgRecoveryTime.toStringAsFixed(1)}ms',
            avgRecoveryTime < 500 ? Colors.green : Colors.red,
            'Target: < 500ms',
          ),
          SizedBox(height: 2.h),
          _buildMetricCard(
            'Recovery Success Rate',
            '${recoveryRate.toStringAsFixed(1)}%',
            recoveryRate > 95 ? Colors.green : Colors.orange,
            '$successfulRecoveries / $totalErrors recovered',
          ),
          SizedBox(height: 3.h),
          Text(
            'Recovery Test Results',
            style: GoogleFonts.inter(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 2.h),
          ...screensTested.map((screen) => _buildScreenResultCard(screen)),
        ],
      ),
    );
  }

  Widget _buildMetricCard(
    String label,
    String value,
    Color color,
    String subtitle,
  ) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 14.sp,
                    color: AppTheme.textSecondaryLight,
                  ),
                ),
                SizedBox(height: 1.h),
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                SizedBox(height: 0.5.h),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    color: AppTheme.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.healing, color: color, size: 10.w),
        ],
      ),
    );
  }

  Widget _buildScreenResultCard(dynamic screen) {
    final screenName = screen['screen'] ?? 'Unknown';
    final recoveryTime = screen['recovery_time_ms'] ?? 0.0;
    final success = screen['success'] ?? false;

    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(
          color: success
              ? Colors.green.withValues(alpha: 0.3)
              : Colors.red.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            success ? Icons.check_circle : Icons.error,
            color: success ? Colors.green : Colors.red,
            size: 6.w,
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  screenName,
                  style: GoogleFonts.inter(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 0.5.h),
                Text(
                  'Recovery: ${recoveryTime.toStringAsFixed(1)}ms - ${success ? "Success" : "Failed"}',
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
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
}
