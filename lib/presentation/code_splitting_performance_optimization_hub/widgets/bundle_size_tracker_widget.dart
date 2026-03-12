import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class BundleSizeTrackerWidget extends StatelessWidget {
  const BundleSizeTrackerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final modules = [
      {'name': 'Core', 'size': 8.5, 'color': AppTheme.primaryLight},
      {'name': 'Social Feed', 'size': 4.2, 'color': AppTheme.secondaryLight},
      {'name': 'Voting', 'size': 3.8, 'color': AppTheme.accentLight},
      {'name': 'Analytics', 'size': 2.9, 'color': Color(0xFFF59E0B)},
      {'name': 'Gamification', 'size': 2.1, 'color': Color(0xFF8B5CF6)},
      {'name': 'Messaging', 'size': 1.8, 'color': Color(0xFFEC4899)},
      {'name': 'Admin', 'size': 3.2, 'color': Color(0xFF06B6D4)},
      {'name': 'Creator Tools', 'size': 2.7, 'color': Color(0xFF14B8A6)},
      {'name': 'Other', 'size': 6.0, 'color': AppTheme.textSecondaryLight},
    ];

    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bundle Size by Feature Module',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          SizedBox(height: 2.h),
          _buildTotalSizeCard(),
          SizedBox(height: 3.h),
          ...modules.map((module) => _buildModuleCard(module)),
        ],
      ),
    );
  }

  Widget _buildTotalSizeCard() {
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
          Text(
            'Total Bundle Size',
            style: TextStyle(
              fontSize: 12.sp,
              color: Colors.white.withAlpha(204),
            ),
          ),
          SizedBox(height: 1.h),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '35.2',
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
                  'MB',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withAlpha(204),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Row(
            children: [
              Icon(Icons.trending_down, size: 4.w, color: AppTheme.accentLight),
              SizedBox(width: 2.w),
              Text(
                '58.6% reduction from 85.0 MB',
                style: TextStyle(fontSize: 11.sp, color: Colors.white),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModuleCard(Map<String, dynamic> module) {
    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Row(
        children: [
          Container(
            width: 10.w,
            height: 10.w,
            decoration: BoxDecoration(
              color: (module['color'] as Color).withAlpha(26),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Icon(
              Icons.folder,
              size: 5.w,
              color: module['color'] as Color,
            ),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  module['name'] as String,
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimaryLight,
                  ),
                ),
                SizedBox(height: 0.5.h),
                Text(
                  '${module['size']} MB',
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: AppTheme.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${((module['size'] as double) / 35.2 * 100).toStringAsFixed(1)}%',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w700,
              color: module['color'] as Color,
            ),
          ),
        ],
      ),
    );
  }
}
