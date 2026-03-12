import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class PerformanceMonitoringWidget extends StatelessWidget {
  final Map<String, dynamic> metrics;
  final VoidCallback onRefresh;

  const PerformanceMonitoringWidget({
    super.key,
    required this.metrics,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: SingleChildScrollView(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Performance Monitoring',
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 1.h),
            Text(
              'Track ad load times, viewability, and user experience impact',
              style: TextStyle(fontSize: 12.sp, color: Colors.grey),
            ),
            SizedBox(height: 3.h),
            _buildPerformanceOverview(),
            SizedBox(height: 2.h),
            _buildLoadTimeMetrics(),
            SizedBox(height: 2.h),
            _buildViewabilityMetrics(),
            SizedBox(height: 2.h),
            _buildOptimizationRecommendations(),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceOverview() {
    final impressionRate = metrics['impression_rate'] ?? 0.0;
    final clickThroughRate = metrics['click_through_rate'] ?? 0.0;
    final viewabilityPercentage = metrics['viewability_percentage'] ?? 0.0;
    final fillRate = metrics['fill_rate'] ?? 0.0;

    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Performance Overview',
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 2.h),
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    'Impression Rate',
                    '${impressionRate.toStringAsFixed(1)}%',
                    Icons.visibility,
                    Colors.blue,
                  ),
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: _buildMetricCard(
                    'CTR',
                    '${clickThroughRate.toStringAsFixed(2)}%',
                    Icons.touch_app,
                    Colors.green,
                  ),
                ),
              ],
            ),
            SizedBox(height: 2.h),
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    'Viewability',
                    '${viewabilityPercentage.toStringAsFixed(1)}%',
                    Icons.remove_red_eye,
                    Colors.orange,
                  ),
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: _buildMetricCard(
                    'Fill Rate',
                    '${fillRate.toStringAsFixed(1)}%',
                    Icons.pie_chart,
                    Colors.purple,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(2.w),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20.sp),
          SizedBox(height: 1.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(height: 0.5.h),
          Text(
            label,
            style: TextStyle(fontSize: 10.sp, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLoadTimeMetrics() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.speed, size: 20.sp, color: Colors.blue),
                SizedBox(width: 2.w),
                Text(
                  'Ad Load Times',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 2.h),
            _buildLoadTimeRow('Banner Ads', '450ms', Colors.green),
            Divider(height: 2.h),
            _buildLoadTimeRow('Interstitial Ads', '1.2s', Colors.orange),
            Divider(height: 2.h),
            _buildLoadTimeRow('Rewarded Ads', '1.5s', Colors.orange),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadTimeRow(String adType, String loadTime, Color statusColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          adType,
          style: TextStyle(fontSize: 12.sp, color: Colors.grey[700]),
        ),
        Row(
          children: [
            Container(
              width: 8.0,
              height: 8.0,
              decoration: BoxDecoration(
                color: statusColor,
                shape: BoxShape.circle,
              ),
            ),
            SizedBox(width: 2.w),
            Text(
              loadTime,
              style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildViewabilityMetrics() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.remove_red_eye, size: 20.sp, color: Colors.purple),
                SizedBox(width: 2.w),
                Text(
                  'Viewability Metrics',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 2.h),
            Text(
              'Percentage of ads that were actually viewed by users',
              style: TextStyle(fontSize: 12.sp, color: Colors.grey),
            ),
            SizedBox(height: 2.h),
            _buildViewabilityRow('Jolts Feed', 95.2),
            SizedBox(height: 1.h),
            _buildViewabilityRow('Election Discovery', 88.7),
            SizedBox(height: 1.h),
            _buildViewabilityRow('User Dashboard', 92.4),
          ],
        ),
      ),
    );
  }

  Widget _buildViewabilityRow(String placement, double percentage) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              placement,
              style: TextStyle(fontSize: 12.sp, color: Colors.grey[700]),
            ),
            Text(
              '${percentage.toStringAsFixed(1)}%',
              style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        SizedBox(height: 0.5.h),
        LinearProgressIndicator(
          value: percentage / 100,
          backgroundColor: Colors.grey[200],
          valueColor: AlwaysStoppedAnimation<Color>(
            percentage >= 90 ? Colors.green : Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildOptimizationRecommendations() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lightbulb, size: 20.sp, color: Colors.amber),
                SizedBox(width: 2.w),
                Text(
                  'Optimization Recommendations',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 2.h),
            _buildRecommendation(
              'Reduce interstitial frequency',
              'Current frequency may impact user experience',
              Icons.warning,
              Colors.orange,
            ),
            SizedBox(height: 1.h),
            _buildRecommendation(
              'Optimize banner placement',
              'Test alternative positions for better CTR',
              Icons.info,
              Colors.blue,
            ),
            SizedBox(height: 1.h),
            _buildRecommendation(
              'Increase rewarded ad visibility',
              'Promote rewarded ads for higher engagement',
              Icons.trending_up,
              Colors.green,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendation(
    String title,
    String description,
    IconData icon,
    Color color,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18.sp, color: color),
        SizedBox(width: 3.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 0.5.h),
              Text(
                description,
                style: TextStyle(fontSize: 10.sp, color: Colors.grey),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
