import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class DataMinimizationPanelWidget extends StatelessWidget {
  const DataMinimizationPanelWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.all(3.w),
      children: [
        Text(
          'Data Minimization & Privacy',
          style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 2.h),
        Card(
          elevation: 2.0,
          child: Padding(
            padding: EdgeInsets.all(3.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.privacy_tip, color: Colors.green, size: 20.sp),
                    SizedBox(width: 2.w),
                    Text(
                      'Privacy-First Approach',
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 2.h),
                _buildPrivacyItem(
                  'Binary Signal Only',
                  'System stores only over-18/under-18 result, not exact age or DOB',
                ),
                _buildPrivacyItem(
                  'Immediate Deletion',
                  'Selfie images deleted immediately after verification completes',
                ),
                _buildPrivacyItem(
                  'No Biometric Storage',
                  'Facial features not stored, only verification result',
                ),
                _buildPrivacyItem(
                  'Reusable Verification',
                  'Digital wallet allows one-time verification for multiple elections',
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 2.h),
        Card(
          elevation: 2.0,
          child: Padding(
            padding: EdgeInsets.all(3.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Data Retention Policy',
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 1.h),
                Text(
                  'Verification Result: 365 days\nSelfie Images: 0 seconds (immediate deletion)\nDocument Scans: 0 seconds (immediate deletion)',
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPrivacyItem(String title, String description) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 1.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle, color: Colors.green, size: 16.sp),
          SizedBox(width: 2.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
