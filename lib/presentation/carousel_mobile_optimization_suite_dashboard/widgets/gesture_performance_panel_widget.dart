import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../theme/app_theme.dart';

/// Gesture Performance Panel Widget
class GesturePerformancePanelWidget extends StatelessWidget {
  final Map<String, dynamic> gestureAnalytics;
  final double swipeVelocityThreshold;

  const GesturePerformancePanelWidget({
    super.key,
    required this.gestureAnalytics,
    required this.swipeVelocityThreshold,
  });

  @override
  Widget build(BuildContext context) {
    final avgResponseTime =
        (gestureAnalytics['avg_response_time'] as num?)?.toDouble() ?? 0.0;
    final successRate =
        (gestureAnalytics['success_rate'] as num?)?.toDouble() ?? 0.0;
    final totalGestures = gestureAnalytics['total_gestures'] as int? ?? 0;

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Gesture Performance',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: AppThemeColors.electricGold,
            ),
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'Avg Response',
                  '${avgResponseTime.toStringAsFixed(0)}ms',
                  Icons.speed,
                  _getResponseColor(avgResponseTime),
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: _buildMetricCard(
                  'Success Rate',
                  '${successRate.toStringAsFixed(1)}%',
                  Icons.check_circle,
                  _getSuccessColor(successRate),
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'Total Gestures',
                  totalGestures.toString(),
                  Icons.touch_app,
                  AppThemeColors.neonMint,
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: _buildMetricCard(
                  'Velocity Threshold',
                  '${swipeVelocityThreshold.toStringAsFixed(0)} px/s',
                  Icons.swipe,
                  AppThemeColors.electricGold,
                ),
              ),
            ],
          ),
          SizedBox(height: 3.h),
          _buildRecommendations(avgResponseTime, successRate),
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
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: color.withAlpha(77)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20.sp),
          SizedBox(height: 1.h),
          Text(
            label,
            style: TextStyle(
              fontSize: 12.sp,
              color: AppTheme.textSecondaryDark,
            ),
          ),
          SizedBox(height: 0.5.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendations(double responseTime, double successRate) {
    final recommendations = <String>[];

    if (responseTime > 100) {
      recommendations.add('Consider reducing animation complexity');
    }
    if (successRate < 90) {
      recommendations.add('Increase touch target sizes');
    }
    if (recommendations.isEmpty) {
      recommendations.add('Gesture performance is optimal');
    }

    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: AppThemeColors.electricGold.withAlpha(26),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb,
                color: AppThemeColors.electricGold,
                size: 18.sp,
              ),
              SizedBox(width: 2.w),
              Text(
                'Recommendations',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: AppThemeColors.electricGold,
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          ...recommendations.map(
            (rec) => Padding(
              padding: EdgeInsets.only(top: 0.5.h),
              child: Row(
                children: [
                  Icon(
                    Icons.arrow_right,
                    color: AppTheme.textSecondaryDark,
                    size: 16.sp,
                  ),
                  SizedBox(width: 1.w),
                  Expanded(
                    child: Text(
                      rec,
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: AppTheme.textSecondaryDark,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getResponseColor(double responseTime) {
    if (responseTime <= 50) return Colors.green;
    if (responseTime <= 100) return Colors.orange;
    return Colors.red;
  }

  Color _getSuccessColor(double successRate) {
    if (successRate >= 95) return Colors.green;
    if (successRate >= 85) return Colors.orange;
    return Colors.red;
  }
}
