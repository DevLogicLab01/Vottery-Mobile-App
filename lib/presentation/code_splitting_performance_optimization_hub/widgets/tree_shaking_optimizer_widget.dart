import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class TreeShakingOptimizerWidget extends StatelessWidget {
  const TreeShakingOptimizerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tree Shaking Optimization',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            'Removes unused code from production build',
            style: TextStyle(
              fontSize: 11.sp,
              color: AppTheme.textSecondaryLight,
            ),
          ),
          SizedBox(height: 3.h),
          _buildSavingsCard(),
          SizedBox(height: 3.h),
          _buildOptimizationsCard(),
          SizedBox(height: 3.h),
          _buildPackagesCard(),
        ],
      ),
    );
  }

  Widget _buildSavingsCard() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryLight, AppTheme.secondaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.delete_sweep, size: 6.w, color: Colors.white),
              SizedBox(width: 3.w),
              Text(
                'Total Savings',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '12.3',
                style: TextStyle(
                  fontSize: 32.sp,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: 2.w),
              Padding(
                padding: EdgeInsets.only(bottom: 1.h),
                child: Text(
                  'MB removed',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Colors.white.withAlpha(204),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Text(
            '14.5% of original bundle size',
            style: TextStyle(
              fontSize: 11.sp,
              color: Colors.white.withAlpha(204),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptimizationsCard() {
    final optimizations = [
      {
        'name': 'Unused Imports',
        'removed': 234,
        'size': 3.2,
        'icon': Icons.code,
      },
      {
        'name': 'Dead Code',
        'removed': 89,
        'size': 2.8,
        'icon': Icons.delete_outline,
      },
      {
        'name': 'Unused Assets',
        'removed': 45,
        'size': 4.1,
        'icon': Icons.image,
      },
      {
        'name': 'Duplicate Dependencies',
        'removed': 12,
        'size': 2.2,
        'icon': Icons.content_copy,
      },
    ];

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
          Text(
            'Optimization Breakdown',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          SizedBox(height: 2.h),
          ...optimizations.map((opt) => _buildOptimizationRow(opt)),
        ],
      ),
    );
  }

  Widget _buildOptimizationRow(Map<String, dynamic> opt) {
    return Padding(
      padding: EdgeInsets.only(bottom: 2.h),
      child: Row(
        children: [
          Container(
            width: 10.w,
            height: 10.w,
            decoration: BoxDecoration(
              color: AppTheme.accentLight.withAlpha(26),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Icon(
              opt['icon'] as IconData,
              size: 5.w,
              color: AppTheme.accentLight,
            ),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  opt['name'] as String,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimaryLight,
                  ),
                ),
                Text(
                  '${opt['removed']} items removed',
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: AppTheme.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${opt['size']} MB',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w700,
              color: AppTheme.accentLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPackagesCard() {
    final packages = [
      {'name': 'flutter', 'used': 85, 'total': 100},
      {'name': 'supabase_flutter', 'used': 92, 'total': 100},
      {'name': 'google_fonts', 'used': 12, 'total': 100},
      {'name': 'cached_network_image', 'used': 78, 'total': 100},
      {'name': 'livekit_client', 'used': 45, 'total': 100},
    ];

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
          Text(
            'Package Usage',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          SizedBox(height: 2.h),
          ...packages.map((pkg) => _buildPackageRow(pkg)),
        ],
      ),
    );
  }

  Widget _buildPackageRow(Map<String, dynamic> pkg) {
    final percentage = pkg['used'] as int;
    final color = percentage > 70
        ? AppTheme.accentLight
        : percentage > 40
        ? AppTheme.warningLight
        : AppTheme.errorLight;

    return Padding(
      padding: EdgeInsets.only(bottom: 2.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                pkg['name'] as String,
                style: TextStyle(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimaryLight,
                ),
              ),
              Text(
                '$percentage% used',
                style: TextStyle(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
          SizedBox(height: 0.5.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(4.0),
            child: LinearProgressIndicator(
              value: percentage / 100,
              backgroundColor: AppTheme.borderLight,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 1.h,
            ),
          ),
        ],
      ),
    );
  }
}
