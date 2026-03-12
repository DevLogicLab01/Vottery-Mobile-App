import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class RevenueAnalyticsWidget extends StatelessWidget {
  final Map<String, dynamic> analytics;

  const RevenueAnalyticsWidget({super.key, required this.analytics});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      padding: EdgeInsets.all(4.w),
      children: [
        Text(
          'Revenue Analytics Dashboard',
          style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 2.h),
        _buildMetricCard(
          theme,
          'Total VP Earned',
          '${analytics['total_vp_earned'] ?? 0} VP',
          Icons.stars,
          Colors.amber,
        ),
        _buildMetricCard(
          theme,
          'VP Conversion Rate',
          '1 VP = \$${analytics['vp_conversion_rate'] ?? 0.01}',
          Icons.currency_exchange,
          Colors.green,
        ),
        _buildMetricCard(
          theme,
          'Average Views',
          '${analytics['average_views'] ?? 0}',
          Icons.visibility,
          Colors.blue,
        ),
        _buildMetricCard(
          theme,
          'Engagement Rate',
          '${(analytics['engagement_rate'] ?? 0.0).toStringAsFixed(1)}%',
          Icons.trending_up,
          Colors.purple,
        ),
        _buildMetricCard(
          theme,
          'Viral Score',
          '${analytics['viral_score'] ?? 0} viral videos',
          Icons.local_fire_department,
          Colors.red,
        ),
      ],
    );
  }

  Widget _buildMetricCard(
    ThemeData theme,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      margin: EdgeInsets.only(bottom: 2.h),
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Icon(icon, color: color, size: 6.w),
            ),
            SizedBox(width: 4.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
