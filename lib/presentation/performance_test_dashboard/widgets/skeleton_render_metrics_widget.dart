import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../theme/app_theme.dart';

class SkeletonRenderMetricsWidget extends StatelessWidget {
  final Map<String, dynamic> metrics;

  const SkeletonRenderMetricsWidget({super.key, required this.metrics});

  @override
  Widget build(BuildContext context) {
    final avgRenderTime = metrics['average_render_time_ms'] ?? 0.0;
    final p95RenderTime = metrics['p95_render_time_ms'] ?? 0.0;
    final passedTests = metrics['passed_tests'] ?? 0;
    final totalTests = metrics['total_tests'] ?? 0;
    final screensTested = metrics['screens_tested'] as List<dynamic>? ?? [];

    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMetricCard(
            'Average Render Time',
            '${avgRenderTime.toStringAsFixed(1)}ms',
            avgRenderTime < 100 ? Colors.green : Colors.orange,
            'Target: < 100ms',
          ),
          SizedBox(height: 2.h),
          _buildMetricCard(
            'P95 Render Time',
            '${p95RenderTime.toStringAsFixed(1)}ms',
            p95RenderTime < 150 ? Colors.green : Colors.orange,
            'Target: < 150ms',
          ),
          SizedBox(height: 2.h),
          _buildMetricCard(
            'Test Pass Rate',
            '$passedTests / $totalTests',
            passedTests == totalTests ? Colors.green : Colors.red,
            '${((passedTests / totalTests) * 100).toStringAsFixed(1)}% passed',
          ),
          SizedBox(height: 3.h),
          Text(
            'Screen-by-Screen Results',
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
          Icon(Icons.speed, color: color, size: 10.w),
        ],
      ),
    );
  }

  Widget _buildScreenResultCard(dynamic screen) {
    final screenName = screen['screen'] ?? 'Unknown';
    final renderTime = screen['render_time_ms'] ?? 0.0;
    final isPassing = renderTime < 100;

    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(
          color: isPassing
              ? Colors.green.withValues(alpha: 0.3)
              : Colors.orange.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isPassing ? Icons.check_circle : Icons.warning,
            color: isPassing ? Colors.green : Colors.orange,
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
                  'Render time: ${renderTime.toStringAsFixed(1)}ms',
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
