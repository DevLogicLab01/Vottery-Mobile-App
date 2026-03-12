import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../../theme/app_theme.dart';

class PerformanceBenchmarkWidget extends StatelessWidget {
  final Map<String, dynamic> benchmarkData;
  final VoidCallback onRefresh;

  const PerformanceBenchmarkWidget({
    super.key,
    required this.benchmarkData,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final screenRenderTimes = benchmarkData['screen_render_times'] ?? [];
    final apiLatencies = benchmarkData['api_latencies'] ?? [];
    final memoryUsage = benchmarkData['memory_usage'] ?? {};

    return ListView(
      padding: EdgeInsets.all(4.w),
      children: [
        Text(
          'Performance Benchmarks',
          style: GoogleFonts.inter(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 2.h),
        Text(
          'Screen Render Times',
          style: GoogleFonts.inter(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 1.h),
        ...screenRenderTimes.map(
          (screen) => _buildBenchmarkCard(
            screen['screen_name'] ?? 'Unknown',
            '${screen['render_time_ms'] ?? 0}ms',
            screen['render_time_ms'] < 2000 ? Colors.green : Colors.red,
            'Target: <2000ms',
          ),
        ),
        SizedBox(height: 2.h),
        Text(
          'API Response Latencies',
          style: GoogleFonts.inter(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 1.h),
        ...apiLatencies.map(
          (api) => _buildBenchmarkCard(
            api['endpoint'] ?? 'Unknown',
            '${api['latency_ms'] ?? 0}ms',
            api['latency_ms'] < 500 ? Colors.green : Colors.orange,
            'Target: <500ms',
          ),
        ),
        SizedBox(height: 2.h),
        _buildMemoryUsageCard(memoryUsage),
      ],
    );
  }

  Widget _buildBenchmarkCard(
    String label,
    String value,
    Color color,
    String target,
  ) {
    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  target,
                  style: GoogleFonts.inter(
                    fontSize: 10.sp,
                    color: AppTheme.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemoryUsageCard(Map<String, dynamic> memoryData) {
    final avgMemory = memoryData['average_mb'] ?? 0.0;
    final peakMemory = memoryData['peak_mb'] ?? 0.0;

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Memory Usage Analysis',
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 2.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMemoryStat(
                'Average',
                '${avgMemory.toStringAsFixed(1)} MB',
                Colors.blue,
              ),
              _buildMemoryStat(
                'Peak',
                '${peakMemory.toStringAsFixed(1)} MB',
                Colors.orange,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMemoryStat(String label, String value, Color color) {
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
