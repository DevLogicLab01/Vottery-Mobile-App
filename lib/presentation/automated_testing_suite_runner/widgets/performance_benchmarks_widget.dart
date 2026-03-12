import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class PerformanceBenchmarksWidget extends StatelessWidget {
  final Map<String, dynamic> benchmarks;

  const PerformanceBenchmarksWidget({super.key, required this.benchmarks});

  @override
  Widget build(BuildContext context) {
    final screenRenderTime = benchmarks['avg_screen_render_time'] ?? 0;
    final apiResponseTime = benchmarks['avg_api_response_time'] ?? 0;
    final memoryUsage = benchmarks['memory_usage_mb'] ?? 0;

    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Performance Benchmarks',
            style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 1.h),
          Text(
            'Track screen render times and API response latencies',
            style: TextStyle(fontSize: 12.sp, color: Colors.grey),
          ),
          SizedBox(height: 3.h),
          _buildBenchmarkCard(
            'Screen Render Time',
            '${screenRenderTime}ms',
            'Target: <2000ms',
            Icons.speed,
            Colors.blue,
            screenRenderTime < 2000,
          ),
          SizedBox(height: 2.h),
          _buildBenchmarkCard(
            'API Response Time',
            '${apiResponseTime}ms',
            'Target: <500ms',
            Icons.cloud,
            Colors.green,
            apiResponseTime < 500,
          ),
          SizedBox(height: 2.h),
          _buildBenchmarkCard(
            'Memory Usage',
            '${memoryUsage}MB',
            'Target: <200MB',
            Icons.memory,
            Colors.orange,
            memoryUsage < 200,
          ),
        ],
      ),
    );
  }

  Widget _buildBenchmarkCard(
    String title,
    String value,
    String target,
    IconData icon,
    Color color,
    bool meetsTarget,
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
                    target,
                    style: TextStyle(fontSize: 11.sp, color: Colors.grey),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: meetsTarget ? Colors.green : Colors.orange,
                  ),
                ),
                Icon(
                  meetsTarget ? Icons.check_circle : Icons.warning,
                  color: meetsTarget ? Colors.green : Colors.orange,
                  size: 20.sp,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
