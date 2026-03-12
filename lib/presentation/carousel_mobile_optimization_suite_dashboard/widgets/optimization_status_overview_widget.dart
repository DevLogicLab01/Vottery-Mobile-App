import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../theme/app_theme.dart';

/// Optimization Status Overview Widget
class OptimizationStatusOverviewWidget extends StatelessWidget {
  final String deviceModel;
  final String deviceTier;
  final String optimizationLevel;
  final double currentFPS;
  final bool isBatterySaverMode;

  const OptimizationStatusOverviewWidget({
    super.key,
    required this.deviceModel,
    required this.deviceTier,
    required this.optimizationLevel,
    required this.currentFPS,
    required this.isBatterySaverMode,
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
                Icons.phone_android,
                color: AppThemeColors.electricGold,
                size: 24.sp,
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Device Status',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: AppThemeColors.electricGold,
                      ),
                    ),
                    Text(
                      deviceModel,
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: AppTheme.textSecondaryDark,
                      ),
                    ),
                  ],
                ),
              ),
              _buildStatusBadge(),
            ],
          ),
          SizedBox(height: 3.h),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'Device Tier',
                  _formatTier(deviceTier),
                  _getTierColor(deviceTier),
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: _buildMetricCard(
                  'Optimization',
                  _formatOptimization(optimizationLevel),
                  AppThemeColors.neonMint,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'Current FPS',
                  currentFPS.toStringAsFixed(1),
                  _getFPSColor(currentFPS),
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: _buildMetricCard(
                  'Battery Mode',
                  isBatterySaverMode ? 'Saver' : 'Normal',
                  isBatterySaverMode ? Colors.orange : Colors.green,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
      decoration: BoxDecoration(
        color: Colors.green.withAlpha(51),
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(color: Colors.green),
      ),
      child: Text(
        'Optimized',
        style: TextStyle(
          color: Colors.green,
          fontSize: 12.sp,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildMetricCard(String label, String value, Color color) {
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

  String _formatTier(String tier) {
    switch (tier) {
      case 'high_end':
        return 'High-End';
      case 'mid_range':
        return 'Mid-Range';
      case 'low_end':
        return 'Low-End';
      default:
        return tier;
    }
  }

  String _formatOptimization(String level) {
    switch (level) {
      case 'full':
        return 'Full';
      case 'standard':
        return 'Standard';
      case 'reduced':
        return 'Reduced';
      case 'minimal':
        return 'Minimal';
      default:
        return level;
    }
  }

  Color _getTierColor(String tier) {
    switch (tier) {
      case 'high_end':
        return Colors.green;
      case 'mid_range':
        return Colors.orange;
      case 'low_end':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color _getFPSColor(double fps) {
    if (fps >= 55) return Colors.green;
    if (fps >= 40) return Colors.orange;
    return Colors.red;
  }
}
