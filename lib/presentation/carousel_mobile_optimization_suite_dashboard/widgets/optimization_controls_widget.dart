import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../theme/app_theme.dart';

/// Optimization Controls Widget
class OptimizationControlsWidget extends StatelessWidget {
  final String optimizationLevel;
  final bool shouldEnableParallax;
  final bool shouldEnableGlassmorphism;

  const OptimizationControlsWidget({
    super.key,
    required this.optimizationLevel,
    required this.shouldEnableParallax,
    required this.shouldEnableGlassmorphism,
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
            'Active Optimizations',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: AppThemeColors.electricGold,
            ),
          ),
          SizedBox(height: 2.h),
          _buildOptimizationItem('Parallax Effects', shouldEnableParallax),
          _buildOptimizationItem('Glassmorphism', shouldEnableGlassmorphism),
          _buildOptimizationItem('Adaptive Speed', true),
          _buildOptimizationItem('Progressive Loading', true),
          _buildOptimizationItem('Image Compression', true),
        ],
      ),
    );
  }

  Widget _buildOptimizationItem(String label, bool isEnabled) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 1.h),
      child: Row(
        children: [
          Icon(
            isEnabled ? Icons.check_circle : Icons.cancel,
            color: isEnabled ? Colors.green : Colors.grey,
            size: 20.sp,
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14.sp,
                color: isEnabled
                    ? AppTheme.textPrimaryDark
                    : AppTheme.textSecondaryDark,
              ),
            ),
          ),
          Text(
            isEnabled ? 'Enabled' : 'Disabled',
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: isEnabled ? Colors.green : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}
