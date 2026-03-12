import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../theme/app_theme.dart';
import '../../../widgets/custom_icon_widget.dart';

class GDPRAutoDisablePanelWidget extends StatelessWidget {
  final List<Map<String, dynamic>> gdprCountries;

  const GDPRAutoDisablePanelWidget({super.key, required this.gdprCountries});

  @override
  Widget build(BuildContext context) {
    final disabledCount = gdprCountries
        .where((c) => c['biometric_enabled'] == false)
        .length;

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CustomIconWidget(
                iconName: 'shield',
                size: 6.w,
                color: Colors.blue.shade700,
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: Text(
                  'GDPR Auto-Disable Logic',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Text(
                  'Active',
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: Colors.green.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Container(
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'GDPR Article 9 - Special Category Data',
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue.shade900,
                  ),
                ),
                SizedBox(height: 1.h),
                Text(
                  'Biometric data is classified as special category personal data under GDPR. Automated restriction enforced for all 27 EU member states.',
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: Colors.blue.shade700,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'EU Countries',
                  gdprCountries.length.toString(),
                  Icons.public,
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: _buildStatCard(
                  'Auto-Disabled',
                  disabledCount.toString(),
                  Icons.block,
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: _buildStatCard(
                  'Compliance',
                  '${((disabledCount / gdprCountries.length) * 100).toStringAsFixed(0)}%',
                  Icons.verified,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          ExpansionTile(
            title: Text(
              'View All GDPR Countries (${gdprCountries.length})',
              style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600),
            ),
            children: [
              Container(
                padding: EdgeInsets.all(3.w),
                child: Wrap(
                  spacing: 2.w,
                  runSpacing: 1.h,
                  children: gdprCountries.map((country) {
                    final enabled =
                        country['biometric_enabled'] as bool? ?? false;
                    return Chip(
                      label: Text(
                        country['country_code'] as String,
                        style: TextStyle(fontSize: 10.sp),
                      ),
                      backgroundColor: enabled
                          ? Colors.orange.shade100
                          : Colors.green.shade100,
                      avatar: Icon(
                        enabled ? Icons.warning_amber : Icons.check_circle,
                        size: 4.w,
                        color: enabled ? Colors.orange : Colors.green,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: AppTheme.backgroundLight,
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        children: [
          Icon(icon, size: 5.w, color: AppTheme.primaryLight),
          SizedBox(height: 0.5.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryLight,
            ),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 9.sp, color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
