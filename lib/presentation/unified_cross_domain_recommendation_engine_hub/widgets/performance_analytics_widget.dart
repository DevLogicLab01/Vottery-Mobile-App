import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../theme/app_theme.dart';

class PerformanceAnalyticsWidget extends StatelessWidget {
  final Map<String, dynamic> engineStatus;

  const PerformanceAnalyticsWidget({super.key, required this.engineStatus});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Performance Analytics',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryLight,
            ),
          ),
          SizedBox(height: 2.h),
          _buildMetricCard(
            'Algorithm Performance',
            '${engineStatus['algorithm_performance']?.toStringAsFixed(1) ?? '0.0'}%',
            Icons.psychology,
            Colors.purple,
          ),
          _buildMetricCard(
            'User Engagement Rate',
            '${engineStatus['user_engagement_rate']?.toStringAsFixed(1) ?? '0.0'}%',
            Icons.trending_up,
            Colors.green,
          ),
          _buildMetricCard(
            'Ranking Effectiveness',
            '${engineStatus['ranking_effectiveness']?.toStringAsFixed(1) ?? '0.0'}%',
            Icons.star,
            Colors.orange,
          ),
        ],
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
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 8.w),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimaryLight,
                  ),
                ),
                SizedBox(height: 0.5.h),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
