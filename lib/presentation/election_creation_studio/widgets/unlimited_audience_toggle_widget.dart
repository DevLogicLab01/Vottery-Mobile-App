import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

/// Unlimited Audience Toggle Widget
/// Enables unlimited audience size with auto-scaling and performance optimization
class UnlimitedAudienceToggleWidget extends StatelessWidget {
  final bool unlimitedAudienceEnabled;
  final int? maxAudienceSize;
  final bool autoScalingEnabled;
  final String performanceOptimizationLevel;
  final Function(bool) onUnlimitedToggle;
  final Function(int?) onMaxAudienceSizeChanged;
  final Function(bool) onAutoScalingToggle;
  final Function(String) onPerformanceOptimizationChanged;

  const UnlimitedAudienceToggleWidget({
    super.key,
    required this.unlimitedAudienceEnabled,
    required this.maxAudienceSize,
    required this.autoScalingEnabled,
    required this.performanceOptimizationLevel,
    required this.onUnlimitedToggle,
    required this.onMaxAudienceSizeChanged,
    required this.onAutoScalingToggle,
    required this.onPerformanceOptimizationChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CustomIconWidget(
                iconName: 'groups',
                size: 6.w,
                color: AppTheme.primaryLight,
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Unlimited Audience Size',
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimaryLight,
                      ),
                    ),
                    Text(
                      'Enable unlimited participants with auto-scaling',
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: AppTheme.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: unlimitedAudienceEnabled,
                onChanged: onUnlimitedToggle,
                activeThumbColor: AppTheme.accentLight,
              ),
            ],
          ),
          if (!unlimitedAudienceEnabled) ...[
            SizedBox(height: 2.h),
            Text(
              'Maximum Audience Size',
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimaryLight,
              ),
            ),
            SizedBox(height: 1.h),
            TextField(
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'Enter max audience size (e.g., 10000)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                prefixIcon: Icon(Icons.people_outline),
              ),
              onChanged: (value) {
                final size = int.tryParse(value);
                onMaxAudienceSizeChanged(size);
              },
            ),
          ],
          if (unlimitedAudienceEnabled) ...[
            SizedBox(height: 2.h),
            Divider(),
            SizedBox(height: 2.h),
            // Auto-Scaling Toggle
            Row(
              children: [
                CustomIconWidget(
                  iconName: 'auto_awesome',
                  size: 5.w,
                  color: AppTheme.accentLight,
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Auto-Scaling',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimaryLight,
                        ),
                      ),
                      Text(
                        'Automatically scale resources for large audiences',
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: AppTheme.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: autoScalingEnabled,
                  onChanged: onAutoScalingToggle,
                  activeThumbColor: AppTheme.accentLight,
                ),
              ],
            ),
            SizedBox(height: 2.h),
            // Performance Optimization Level
            Text(
              'Performance Optimization',
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimaryLight,
              ),
            ),
            SizedBox(height: 1.h),
            _buildOptimizationLevelSelector(),
            SizedBox(height: 2.h),
            // Performance Indicators
            Container(
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  CustomIconWidget(
                    iconName: 'info',
                    size: 5.w,
                    color: Colors.blue[700]!,
                  ),
                  SizedBox(width: 3.w),
                  Expanded(
                    child: Text(
                      _getPerformanceIndicatorText(),
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: Colors.blue[900],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOptimizationLevelSelector() {
    return Column(
      children: [
        _buildOptimizationOption(
          'standard',
          'Standard',
          'Balanced performance for most elections',
          Icons.speed,
        ),
        SizedBox(height: 1.h),
        _buildOptimizationOption(
          'high',
          'High Performance',
          'Optimized for large audiences (10K+ participants)',
          Icons.rocket_launch,
        ),
        SizedBox(height: 1.h),
        _buildOptimizationOption(
          'extreme',
          'Extreme Performance',
          'Maximum optimization for massive scale (100K+ participants)',
          Icons.flash_on,
        ),
      ],
    );
  }

  Widget _buildOptimizationOption(
    String value,
    String title,
    String description,
    IconData icon,
  ) {
    final isSelected = performanceOptimizationLevel == value;

    return GestureDetector(
      onTap: () => onPerformanceOptimizationChanged(value),
      child: Container(
        padding: EdgeInsets.all(3.w),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryLight.withAlpha(25)
              : Colors.grey[100],
          borderRadius: BorderRadius.circular(8.0),
          border: Border.all(
            color: isSelected ? AppTheme.primaryLight : AppTheme.borderLight,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? AppTheme.primaryLight
                  : AppTheme.textSecondaryLight,
              size: 6.w,
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? AppTheme.primaryLight
                          : AppTheme.textPrimaryLight,
                    ),
                  ),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 10.sp,
                      color: AppTheme.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: AppTheme.primaryLight, size: 5.w),
          ],
        ),
      ),
    );
  }

  String _getPerformanceIndicatorText() {
    switch (performanceOptimizationLevel) {
      case 'standard':
        return 'Standard optimization active. Suitable for elections up to 10,000 participants.';
      case 'high':
        return 'High performance mode enabled. Optimized caching and real-time updates for large audiences.';
      case 'extreme':
        return 'Extreme performance mode active. Advanced load balancing, CDN acceleration, and distributed processing enabled.';
      default:
        return 'Performance optimization configured.';
    }
  }
}
