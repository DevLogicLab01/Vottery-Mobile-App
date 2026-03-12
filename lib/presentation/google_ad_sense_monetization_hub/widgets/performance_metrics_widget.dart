import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class PerformanceMetricsWidget extends StatelessWidget {
  final Map<String, dynamic> metricsData;
  final VoidCallback onRefresh;

  const PerformanceMetricsWidget({
    super.key,
    required this.metricsData,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final impressionRate = metricsData['impression_rate'] ?? 0.0;
    final clickThroughRate = metricsData['click_through_rate'] ?? 0.0;
    final viewabilityPercentage = metricsData['viewability_percentage'] ?? 0.0;
    final fillRate = metricsData['fill_rate'] ?? 0.0;

    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: SingleChildScrollView(
        padding: EdgeInsets.all(3.w),
        child: Column(
          children: [
            _buildMetricCard(
              'Impression Rate',
              impressionRate,
              Icons.visibility,
              Colors.blue,
              'Number of ad impressions per user session',
            ),
            SizedBox(height: 2.h),
            _buildMetricCard(
              'Click-Through Rate',
              clickThroughRate,
              Icons.touch_app,
              Colors.green,
              'Percentage of impressions that result in clicks',
            ),
            SizedBox(height: 2.h),
            _buildMetricCard(
              'Viewability Percentage',
              viewabilityPercentage,
              Icons.remove_red_eye,
              Colors.orange,
              'Percentage of ads that are actually viewable',
            ),
            SizedBox(height: 2.h),
            _buildMetricCard(
              'Fill Rate',
              fillRate,
              Icons.pie_chart,
              Colors.purple,
              'Percentage of ad requests that are filled',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(
    String title,
    double value,
    IconData icon,
    Color color,
    String description,
  ) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          children: [
            Row(
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
                      Text(
                        description,
                        style: TextStyle(fontSize: 11.sp, color: Colors.grey),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 2.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${value.toStringAsFixed(2)}%',
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                _buildTrendIndicator(value),
              ],
            ),
            SizedBox(height: 1.h),
            LinearProgressIndicator(
              value: value / 100,
              backgroundColor: color.withAlpha(51),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendIndicator(double value) {
    final isPositive = value > 50;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
      decoration: BoxDecoration(
        color: isPositive
            ? Colors.green.withAlpha(26)
            : Colors.red.withAlpha(26),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPositive ? Icons.trending_up : Icons.trending_down,
            color: isPositive ? Colors.green : Colors.red,
            size: 14.sp,
          ),
          SizedBox(width: 1.w),
          Text(
            isPositive ? 'Good' : 'Low',
            style: TextStyle(
              fontSize: 11.sp,
              color: isPositive ? Colors.green : Colors.red,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
