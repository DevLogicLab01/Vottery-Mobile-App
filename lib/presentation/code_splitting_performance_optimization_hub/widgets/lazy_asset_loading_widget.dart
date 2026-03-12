import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class LazyAssetLoadingWidget extends StatelessWidget {
  const LazyAssetLoadingWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Lazy Asset Loading',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            'Assets load only when visible in viewport',
            style: TextStyle(
              fontSize: 11.sp,
              color: AppTheme.textSecondaryLight,
            ),
          ),
          SizedBox(height: 3.h),
          _buildMetricsCard(),
          SizedBox(height: 3.h),
          _buildConfigurationCard(),
          SizedBox(height: 3.h),
          _buildAssetTypesCard(),
        ],
      ),
    );
  }

  Widget _buildMetricsCard() {
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
            'Loading Metrics',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              Expanded(
                child: _buildMetricItem(
                  'Lazy Loaded',
                  '156',
                  AppTheme.accentLight,
                ),
              ),
              Expanded(
                child: _buildMetricItem(
                  'Eager Loaded',
                  '24',
                  AppTheme.textSecondaryLight,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              Expanded(
                child: _buildMetricItem(
                  'Avg Load Time',
                  '180ms',
                  AppTheme.secondaryLight,
                ),
              ),
              Expanded(
                child: _buildMetricItem(
                  'Cache Hit Rate',
                  '94.2%',
                  AppTheme.primaryLight,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 10.sp, color: AppTheme.textSecondaryLight),
        ),
        SizedBox(height: 0.5.h),
        Text(
          value,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildConfigurationCard() {
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
            'Configuration',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          SizedBox(height: 2.h),
          _buildConfigItem(
            'Viewport Threshold',
            '0.1 (10% visible)',
            Icons.visibility,
          ),
          _buildConfigItem(
            'Preload Distance',
            '2 screens ahead',
            Icons.fast_forward,
          ),
          _buildConfigItem(
            'Cache Strategy',
            'LRU with 100MB limit',
            Icons.storage,
          ),
          _buildConfigItem(
            'Placeholder Type',
            'Low-quality blur',
            Icons.blur_on,
          ),
        ],
      ),
    );
  }

  Widget _buildConfigItem(String label, String value, IconData icon) {
    return Padding(
      padding: EdgeInsets.only(bottom: 2.h),
      child: Row(
        children: [
          Icon(icon, size: 5.w, color: AppTheme.primaryLight),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: AppTheme.textSecondaryLight,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimaryLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssetTypesCard() {
    final assetTypes = [
      {'type': 'Images', 'count': 89, 'size': 12.4},
      {'type': 'Videos', 'count': 34, 'size': 45.2},
      {'type': 'Fonts', 'count': 12, 'size': 2.1},
      {'type': 'Icons', 'count': 21, 'size': 0.8},
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
            'Asset Types',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          SizedBox(height: 2.h),
          ...assetTypes.map((asset) => _buildAssetTypeRow(asset)),
        ],
      ),
    );
  }

  Widget _buildAssetTypeRow(Map<String, dynamic> asset) {
    return Padding(
      padding: EdgeInsets.only(bottom: 2.h),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              asset['type'] as String,
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimaryLight,
              ),
            ),
          ),
          Expanded(
            child: Text(
              '${asset['count']} files',
              style: TextStyle(
                fontSize: 11.sp,
                color: AppTheme.textSecondaryLight,
              ),
            ),
          ),
          Text(
            '${asset['size']} MB',
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryLight,
            ),
          ),
        ],
      ),
    );
  }
}
