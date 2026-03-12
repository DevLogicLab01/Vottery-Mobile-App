import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../services/country_biometric_compliance_service.dart';
import '../../../theme/app_theme.dart';

class CountryBiometricCardWidget extends StatelessWidget {
  final Map<String, dynamic> country;
  final Function(bool) onToggle;
  final VoidCallback onOverride;

  const CountryBiometricCardWidget({
    super.key,
    required this.country,
    required this.onToggle,
    required this.onOverride,
  });

  @override
  Widget build(BuildContext context) {
    final countryCode = country['country_code'] as String;
    final countryName = country['country_name'] as String;
    final enabled = country['biometric_enabled'] as bool? ?? false;
    final isGdpr = country['is_gdpr_country'] as bool? ?? false;
    final complianceReason = country['compliance_reason'] as String?;

    final badge = CountryBiometricComplianceService.instance.getComplianceBadge(
      country,
    );

    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: isGdpr ? Colors.blue.shade200 : Colors.grey.shade300,
          width: isGdpr ? 2 : 1,
        ),
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
              Container(
                padding: EdgeInsets.all(2.w),
                decoration: BoxDecoration(
                  color: AppTheme.primaryLight.withAlpha(26),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Text(
                  countryCode,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryLight,
                  ),
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      countryName,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      badge,
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: _getBadgeColor(enabled, isGdpr),
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: enabled,
                onChanged: onToggle,
                activeThumbColor: Colors.green,
              ),
            ],
          ),
          if (complianceReason != null) ...[
            SizedBox(height: 2.h),
            Container(
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 5.w,
                    color: Colors.blue.shade700,
                  ),
                  SizedBox(width: 2.w),
                  Expanded(
                    child: Text(
                      complianceReason,
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (isGdpr && !enabled) ...[
            SizedBox(height: 2.h),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onOverride,
                icon: Icon(Icons.warning_amber, size: 5.w),
                label: Text('Override with Liability Waiver'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.orange,
                  side: BorderSide(color: Colors.orange),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getBadgeColor(bool enabled, bool isGdpr) {
    if (isGdpr && !enabled) return Colors.blue.shade700;
    if (enabled) return Colors.green;
    return Colors.orange.shade700;
  }
}
