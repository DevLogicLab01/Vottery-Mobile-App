import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class PerformanceDashboardWidget extends StatelessWidget {
  final Map<String, dynamic> metrics;
  final Map<String, int> screenLatencies;

  const PerformanceDashboardWidget({
    super.key,
    required this.metrics,
    required this.screenLatencies,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.all(4.w),
      children: [
        Text(
          'Performance Profiling Dashboard',
          style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 2.h),
        Card(
          child: Padding(
            padding: EdgeInsets.all(4.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Real-Time Sync Latency',
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 2.h),
                ...screenLatencies.entries.map(
                  (entry) => _buildLatencyRow(entry.key, entry.value),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 2.h),
        Card(
          color: Colors.blue.shade50,
          child: Padding(
            padding: EdgeInsets.all(4.w),
            child: Row(
              children: [
                Icon(Icons.compress, color: Colors.blue, size: 8.w),
                SizedBox(width: 4.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '70% Data Transfer Reduction',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Gzip compression enabled',
                        style: TextStyle(fontSize: 11.sp),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLatencyRow(String screen, int latencyMs) {
    final color = latencyMs < 100
        ? Colors.green
        : latencyMs < 300
        ? Colors.orange
        : Colors.red;

    return Padding(
      padding: EdgeInsets.only(bottom: 1.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(screen, style: TextStyle(fontSize: 11.sp)),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Text(
              '${latencyMs}ms',
              style: TextStyle(
                fontSize: 10.sp,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
