import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class CacheAnalyticsWidget extends StatelessWidget {
  final Map<String, dynamic> stats;

  const CacheAnalyticsWidget({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final electionsCount = stats['elections_count'] ?? 0;
    final votesCount = stats['votes_count'] ?? 0;
    final profilesCount = stats['profiles_count'] ?? 0;
    final aiResponsesCount = stats['ai_responses_count'] ?? 0;
    final cacheHitRate = (stats['cache_hit_rate'] ?? 0.0) * 100;

    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cache Analytics',
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 2.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMetric(
                  label: 'Elections',
                  value: electionsCount.toString(),
                  color: Colors.blue,
                ),
                _buildMetric(
                  label: 'Votes',
                  value: votesCount.toString(),
                  color: Colors.green,
                ),
                _buildMetric(
                  label: 'Profiles',
                  value: profilesCount.toString(),
                  color: Colors.orange,
                ),
                _buildMetric(
                  label: 'AI Responses',
                  value: aiResponsesCount.toString(),
                  color: Colors.purple,
                ),
              ],
            ),
            SizedBox(height: 2.h),
            LinearProgressIndicator(
              value: cacheHitRate / 100,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
            ),
            SizedBox(height: 1.h),
            Text(
              'Cache Hit Rate: ${cacheHitRate.toStringAsFixed(1)}%',
              style: TextStyle(fontSize: 12.sp, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetric({
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 11.sp, color: Colors.grey),
        ),
      ],
    );
  }
}
