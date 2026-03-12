import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../theme/app_theme.dart';

/// Device Capability Widget
class DeviceCapabilityWidget extends StatelessWidget {
  final String deviceModel;
  final String deviceTier;
  final double targetFrameRate;
  final int imageQuality;

  const DeviceCapabilityWidget({
    super.key,
    required this.deviceModel,
    required this.deviceTier,
    required this.targetFrameRate,
    required this.imageQuality,
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
            'Device Capabilities',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: AppThemeColors.electricGold,
            ),
          ),
          SizedBox(height: 2.h),
          _buildCapabilityRow(
            'Target Frame Rate',
            '${targetFrameRate.toStringAsFixed(0)} fps',
            Icons.speed,
          ),
          _buildCapabilityRow('Image Quality', '$imageQuality%', Icons.image),
          _buildCapabilityRow(
            'Hardware Tier',
            _formatTier(deviceTier),
            Icons.memory,
          ),
        ],
      ),
    );
  }

  Widget _buildCapabilityRow(String label, String value, IconData icon) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 1.h),
      child: Row(
        children: [
          Icon(icon, color: AppThemeColors.neonMint, size: 20.sp),
          SizedBox(width: 3.w),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14.sp,
                color: AppTheme.textSecondaryDark,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryDark,
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
}
