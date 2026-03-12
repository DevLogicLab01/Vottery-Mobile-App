import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class PWAInstallationWidget extends StatelessWidget {
  const PWAInstallationWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 8.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.install_mobile,
                size: 6.w,
                color: AppTheme.primaryLight,
              ),
              SizedBox(width: 2.w),
              Text(
                'Mobile App Features',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          _buildFeatureItem(
            icon: Icons.offline_bolt,
            title: 'Offline Voting',
            description: 'Vote without internet connection',
          ),
          SizedBox(height: 1.5.h),
          _buildFeatureItem(
            icon: Icons.notifications_active,
            title: 'Push Notifications',
            description: 'Get instant alerts for election updates',
          ),
          SizedBox(height: 1.5.h),
          _buildFeatureItem(
            icon: Icons.sync,
            title: 'Auto Sync',
            description: 'Automatic background synchronization',
          ),
          SizedBox(height: 1.5.h),
          _buildFeatureItem(
            icon: Icons.security,
            title: 'Secure Storage',
            description: 'Encrypted local vote storage',
          ),
          SizedBox(height: 2.h),
          Container(
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: AppTheme.primaryLight.withAlpha(13),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle, size: 5.w, color: Colors.green),
                SizedBox(width: 2.w),
                Expanded(
                  child: Text(
                    'All features are enabled and ready to use',
                    style: TextStyle(
                      fontSize: 10.sp,
                      color: AppTheme.textSecondaryLight,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(2.w),
          decoration: BoxDecoration(
            color: AppTheme.primaryLight.withAlpha(13),
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Icon(icon, size: 6.w, color: AppTheme.primaryLight),
        ),
        SizedBox(width: 3.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 0.5.h),
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
      ],
    );
  }
}
