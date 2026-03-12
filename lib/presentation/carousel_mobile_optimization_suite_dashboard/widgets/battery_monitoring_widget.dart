import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../theme/app_theme.dart';

/// Battery Monitoring Widget
class BatteryMonitoringWidget extends StatelessWidget {
  final bool isBatterySaverMode;
  final String optimizationLevel;

  const BatteryMonitoringWidget({
    super.key,
    required this.isBatterySaverMode,
    required this.optimizationLevel,
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
          Row(
            children: [
              Icon(
                isBatterySaverMode ? Icons.battery_alert : Icons.battery_full,
                color: isBatterySaverMode ? Colors.orange : Colors.green,
                size: 24.sp,
              ),
              SizedBox(width: 2.w),
              Text(
                'Battery Monitoring',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: AppThemeColors.electricGold,
                ),
              ),
            ],
          ),
          SizedBox(height: 3.h),
          if (isBatterySaverMode) ...[
            Container(
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: Colors.orange.withAlpha(26),
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(color: Colors.orange),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.warning_amber,
                        color: Colors.orange,
                        size: 20.sp,
                      ),
                      SizedBox(width: 2.w),
                      Text(
                        'Battery Saver Mode Active',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 1.h),
                  Text(
                    'Optimizations applied:',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: AppTheme.textSecondaryDark,
                    ),
                  ),
                  SizedBox(height: 0.5.h),
                  _buildOptimizationItem('Reduced animation complexity'),
                  _buildOptimizationItem('Lowered frame rate to 30fps'),
                  _buildOptimizationItem('Disabled parallax effects'),
                  _buildOptimizationItem('Increased caching'),
                ],
              ),
            ),
            SizedBox(height: 2.h),
          ],
          _buildBatteryMetric(
            'Current Optimization',
            _formatOptimization(optimizationLevel),
            AppThemeColors.neonMint,
          ),
          SizedBox(height: 2.h),
          _buildBatteryMetric(
            'Battery Impact',
            'Low',
            Colors.green,
          ),
          SizedBox(height: 2.h),
          _buildBatteryMetric(
            'Estimated Drain',
            '~2% per hour',
            Colors.blue,
          ),
        ],
      ),
    );
  }

  Widget _buildOptimizationItem(String text) {
    return Padding(
      padding: EdgeInsets.only(top: 0.5.h, left: 2.w),
      child: Row(
        children: [
          Icon(
            Icons.check_circle,
            color: Colors.orange,
            size: 14.sp,
          ),
          SizedBox(width: 2.w),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12.sp,
                color: AppTheme.textSecondaryDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBatteryMetric(String label, String value, Color color) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: color.withAlpha(77)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14.sp,
              color: AppTheme.textSecondaryDark,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  String _formatOptimization(String level) {
    switch (level) {
      case 'full':
        return 'Full Performance';
      case 'standard':
        return 'Balanced';
      case 'reduced':
        return 'Power Saving';
      case 'minimal':
        return 'Maximum Efficiency';
      default:
        return level;
    }
  }
}