import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class NotificationStatusOverviewWidget extends StatelessWidget {
  final Map<String, dynamic> stats;

  const NotificationStatusOverviewWidget({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final deliveryRate = (stats['delivery_rate'] ?? 0.0) * 100;
    final activeSubscriptions = stats['active_subscriptions'] ?? 0;
    final engagementRate = (stats['engagement_rate'] ?? 0.0) * 100;

    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Notification Status',
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 2.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  icon: Icons.check_circle,
                  label: 'Delivery Rate',
                  value: '${deliveryRate.toStringAsFixed(1)}%',
                  color: Colors.green,
                ),
                _buildStatItem(
                  icon: Icons.notifications_active,
                  label: 'Active Subscriptions',
                  value: activeSubscriptions.toString(),
                  color: Colors.blue,
                ),
                _buildStatItem(
                  icon: Icons.touch_app,
                  label: 'Engagement',
                  value: '${engagementRate.toStringAsFixed(1)}%',
                  color: Colors.orange,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        SizedBox(height: 1.h),
        Text(
          value,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 11.sp, color: Colors.grey),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
