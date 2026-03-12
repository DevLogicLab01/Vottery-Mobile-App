import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../theme/app_theme.dart';

class DeliveryMetricsOverviewWidget extends StatelessWidget {
  final Map<String, dynamic> metrics;

  const DeliveryMetricsOverviewWidget({
    required this.metrics,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final totalSent = metrics['total_sent'] ?? 0;
    final delivered = metrics['delivered'] ?? 0;
    final deliveryRate = metrics['delivery_rate'] ?? 0.0;
    final bounceRate = metrics['bounce_rate'] ?? 0.0;
    final failoverCount = metrics['failover_count'] ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Overview Metrics',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimaryDark,
          ),
        ),
        SizedBox(height: 2.h),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                title: 'Total Sent',
                value: totalSent.toString(),
                icon: Icons.send,
                color: Colors.blue,
              ),
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: _buildMetricCard(
                title: 'Delivered',
                value: delivered.toString(),
                icon: Icons.check_circle,
                color: Colors.green,
              ),
            ),
          ],
        ),
        SizedBox(height: 2.h),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                title: 'Delivery Rate',
                value: '${deliveryRate.toStringAsFixed(1)}%',
                icon: Icons.trending_up,
                color: _getDeliveryRateColor(deliveryRate),
                subtitle: _getDeliveryRateStatus(deliveryRate),
              ),
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: _buildMetricCard(
                title: 'Bounce Rate',
                value: '${bounceRate.toStringAsFixed(1)}%',
                icon: Icons.warning,
                color: bounceRate > 5 ? Colors.red : Colors.orange,
              ),
            ),
          ],
        ),
        SizedBox(height: 2.h),
        _buildMetricCard(
          title: 'Failover Count',
          value: failoverCount.toString(),
          icon: Icons.swap_horiz,
          color: failoverCount > 0 ? Colors.orange : Colors.grey,
          subtitle: failoverCount > 0 ? 'Provider switches detected' : 'No failovers',
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    String? subtitle,
  }) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: color.withAlpha(77)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20.sp),
              SizedBox(width: 2.w),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: AppTheme.textSecondaryDark,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          if (subtitle != null) ...[
            SizedBox(height: 0.5.h),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 10.sp,
                color: AppTheme.textSecondaryDark,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getDeliveryRateColor(double rate) {
    if (rate >= 95) return Colors.green;
    if (rate >= 90) return Colors.yellow;
    return Colors.red;
  }

  String _getDeliveryRateStatus(double rate) {
    if (rate >= 95) return 'Excellent';
    if (rate >= 90) return 'Good';
    if (rate >= 80) return 'Fair';
    return 'Poor';
  }
}