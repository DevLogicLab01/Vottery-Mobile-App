import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../theme/app_theme.dart';

/// Performance Metrics Widget
class PerformanceMetricsWidget extends StatelessWidget {
  final double currentFPS;
  final double targetFPS;
  final int frameDropsCount;
  final double averageFrameTime;

  const PerformanceMetricsWidget({
    super.key,
    required this.currentFPS,
    required this.targetFPS,
    required this.frameDropsCount,
    required this.averageFrameTime,
  });

  @override
  Widget build(BuildContext context) {
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
            'Performance Metrics',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: AppThemeColors.electricGold,
            ),
          ),
          SizedBox(height: 3.h),
          _buildFPSIndicator(),
          SizedBox(height: 2.h),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'Frame Drops',
                  frameDropsCount.toString(),
                  Icons.warning,
                  frameDropsCount > 10 ? Colors.red : Colors.green,
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: _buildMetricCard(
                  'Avg Frame Time',
                  '${averageFrameTime.toStringAsFixed(1)}ms',
                  Icons.timer,
                  _getFrameTimeColor(averageFrameTime),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFPSIndicator() {
    final fpsPercentage = (currentFPS / targetFPS).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Current FPS',
              style: TextStyle(
                fontSize: 14.sp,
                color: AppTheme.textSecondaryDark,
              ),
            ),
            Text(
              '${currentFPS.toStringAsFixed(1)} / ${targetFPS.toStringAsFixed(0)}',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
                color: _getFPSColor(currentFPS),
              ),
            ),
          ],
        ),
        SizedBox(height: 1.h),
        ClipRRect(
          borderRadius: BorderRadius.circular(4.0),
          child: LinearProgressIndicator(
            value: fpsPercentage,
            backgroundColor: Colors.grey.withAlpha(51),
            valueColor: AlwaysStoppedAnimation<Color>(_getFPSColor(currentFPS)),
            minHeight: 8,
          ),
        ),
      ],
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

  Color _getFPSColor(double fps) {
    if (fps >= targetFPS * 0.9) return Colors.green;
    if (fps >= targetFPS * 0.7) return Colors.orange;
    return Colors.red;
  }

  Color _getFrameTimeColor(double frameTime) {
    if (frameTime <= 16.67) return Colors.green;
    if (frameTime <= 33.33) return Colors.orange;
    return Colors.red;
  }
}
