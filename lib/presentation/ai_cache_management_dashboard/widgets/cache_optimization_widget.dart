import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class CacheOptimizationWidget extends StatelessWidget {
  final Map<String, dynamic> cacheStats;
  final VoidCallback onClearCache;
  final VoidCallback onOptimize;

  const CacheOptimizationWidget({
    super.key,
    required this.cacheStats,
    required this.onClearCache,
    required this.onOptimize,
  });

  @override
  Widget build(BuildContext context) {
    final totalItems = cacheStats['total_cache_items'] ?? 0;
    final estimatedSize = totalItems * 5; // Rough estimate in KB

    return ListView(
      padding: EdgeInsets.all(3.w),
      children: [
        Card(
          child: Padding(
            padding: EdgeInsets.all(4.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Storage Usage',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 2.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total Items:', style: TextStyle(fontSize: 14.sp)),
                    Text(
                      totalItems.toString(),
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 1.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Estimated Size:', style: TextStyle(fontSize: 14.sp)),
                    Text(
                      '~\${estimatedSize}KB',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 2.h),
                LinearProgressIndicator(
                  value: (totalItems / 100).clamp(0.0, 1.0),
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    totalItems > 80 ? Colors.red : Colors.blue,
                  ),
                ),
                SizedBox(height: 1.h),
                Text(
                  totalItems > 80
                      ? 'Cache is getting full. Consider clearing old data.'
                      : 'Cache usage is optimal.',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: totalItems > 80 ? Colors.red : Colors.green,
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 2.h),
        Card(
          child: Padding(
            padding: EdgeInsets.all(4.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Optimization Actions',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 2.h),
                ListTile(
                  leading: const Icon(Icons.auto_fix_high, color: Colors.blue),
                  title: const Text('Auto-Optimize Cache'),
                  subtitle: const Text('Remove expired and duplicate entries'),
                  trailing: ElevatedButton(
                    onPressed: onOptimize,
                    child: const Text('Optimize'),
                  ),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.delete_forever, color: Colors.red),
                  title: const Text('Clear All Cache'),
                  subtitle: const Text('Remove all cached data'),
                  trailing: ElevatedButton(
                    onPressed: onClearCache,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                    child: const Text(
                      'Clear',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 2.h),
        Card(
          child: Padding(
            padding: EdgeInsets.all(4.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cache Performance',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 2.h),
                _buildPerformanceMetric('Cache Hit Rate', '85%', Colors.green),
                SizedBox(height: 1.h),
                _buildPerformanceMetric(
                  'Sync Success Rate',
                  '92%',
                  Colors.blue,
                ),
                SizedBox(height: 1.h),
                _buildPerformanceMetric(
                  'Offline Functionality',
                  '100%',
                  Colors.green,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPerformanceMetric(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 13.sp)),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.5.h),
          decoration: BoxDecoration(
            color: color.withAlpha(26),
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}
