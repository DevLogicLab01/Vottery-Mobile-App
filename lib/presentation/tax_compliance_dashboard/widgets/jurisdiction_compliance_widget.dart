import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

/// Jurisdiction Compliance Widget
/// Shows jurisdiction-specific compliance scores and registration tracking
class JurisdictionComplianceWidget extends StatelessWidget {
  final List<Map<String, dynamic>> jurisdictions;
  final VoidCallback onRefresh;

  const JurisdictionComplianceWidget({
    super.key,
    required this.jurisdictions,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (jurisdictions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.public_off,
              size: 15.w,
              color: AppTheme.textSecondaryLight,
            ),
            SizedBox(height: 2.h),
            Text(
              'No jurisdictions registered',
              style: TextStyle(
                fontSize: 14.sp,
                color: AppTheme.textSecondaryLight,
              ),
            ),
            SizedBox(height: 1.h),
            ElevatedButton(
              onPressed: onRefresh,
              child: Text('Register Jurisdiction'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(4.w),
      itemCount: jurisdictions.length,
      itemBuilder: (context, index) {
        final jurisdiction = jurisdictions[index];
        return _buildJurisdictionCard(jurisdiction);
      },
    );
  }

  Widget _buildJurisdictionCard(Map<String, dynamic> jurisdiction) {
    final name = jurisdiction['jurisdiction_name'] ?? 'Unknown';
    final code = jurisdiction['jurisdiction_code'] ?? 'N/A';
    final registrationNumber =
        jurisdiction['registration_number'] ?? 'Not provided';
    final isActive = jurisdiction['is_active'] ?? false;

    return Card(
      margin: EdgeInsets.only(bottom: 2.h),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: isActive
              ? Colors.green.withAlpha(26)
              : Colors.grey.withAlpha(26),
          child: Text(
            code.substring(0, 2).toUpperCase(),
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w700,
              color: isActive ? Colors.green : Colors.grey,
            ),
          ),
        ),
        title: Text(
          name,
          style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          'Registration: $registrationNumber',
          style: TextStyle(fontSize: 12.sp),
        ),
        trailing: Container(
          padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
          decoration: BoxDecoration(
            color: isActive
                ? Colors.green.withAlpha(26)
                : Colors.grey.withAlpha(26),
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: Text(
            isActive ? 'Active' : 'Inactive',
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: FontWeight.w600,
              color: isActive ? Colors.green : Colors.grey,
            ),
          ),
        ),
        children: [
          Padding(
            padding: EdgeInsets.all(4.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow('Jurisdiction Code', code),
                SizedBox(height: 1.h),
                _buildInfoRow('Registration Number', registrationNumber),
                SizedBox(height: 1.h),
                _buildInfoRow('Status', isActive ? 'Active' : 'Inactive'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 12.sp, color: AppTheme.textSecondaryLight),
        ),
        Text(
          value,
          style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
