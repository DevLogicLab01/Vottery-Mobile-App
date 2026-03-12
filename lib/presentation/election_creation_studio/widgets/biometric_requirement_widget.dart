import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

/// Widget for biometric voting requirement toggle
class BiometricRequirementWidget extends StatelessWidget {
  final bool biometricRequired;
  final Function(bool) onChanged;

  const BiometricRequirementWidget({
    super.key,
    required this.biometricRequired,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.backgroundLight,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.fingerprint, color: AppTheme.primaryLight, size: 6.w),
              SizedBox(width: 2.w),
              Expanded(
                child: Text(
                  'Biometric Voting Requirement',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryLight,
                  ),
                ),
              ),
              Switch(
                value: biometricRequired,
                onChanged: onChanged,
                activeThumbColor: AppTheme.accentLight,
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Text(
            biometricRequired
                ? 'Voters must authenticate with their device\'s built-in biometrics (Face ID, Touch ID, fingerprint, Windows Hello, or a compatible security key) before voting'
                : 'Biometric authentication is optional for this election',
            style: TextStyle(fontSize: 11.sp, color: Colors.grey.shade600),
          ),
          if (biometricRequired) ...[
            SizedBox(height: 2.h),
            Container(
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.blue.shade700,
                        size: 5.w,
                      ),
                      SizedBox(width: 2.w),
                      Expanded(
                        child: Text(
                          'Platform Support',
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 1.h),
                  _buildPlatformInfo(
                    Icons.phone_iphone,
                    'iOS',
                    'Secure Face ID via system keychain',
                  ),
                  SizedBox(height: 0.5.h),
                  _buildPlatformInfo(
                    Icons.phone_android,
                    'Android',
                    'Device fingerprint / biometrics via OS',
                  ),
                  SizedBox(height: 0.5.h),
                  _buildPlatformInfo(
                    Icons.computer,
                    'Desktop',
                    'Windows Hello, Touch ID on Mac, or OS-level security key (no custom drivers)',
                  ),
                  SizedBox(height: 1.h),
                  Text(
                    'Fallback to PIN/password if biometrics are unavailable or the user opts out.',
                    style: TextStyle(
                      fontSize: 10.sp,
                      color: Colors.blue.shade600,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  SizedBox(height: 0.5.h),
                  Text(
                    'Vottery never stores facial images or fingerprint data – all biometric checks happen on-device and only a secure yes/no result is returned.',
                    style: TextStyle(
                      fontSize: 9.sp,
                      color: Colors.blue.shade700,
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

  Widget _buildPlatformInfo(IconData icon, String platform, String method) {
    return Row(
      children: [
        Icon(icon, size: 4.w, color: Colors.blue.shade600),
        SizedBox(width: 2.w),
        Text(
          '$platform: ',
          style: TextStyle(
            fontSize: 10.sp,
            fontWeight: FontWeight.w600,
            color: Colors.blue.shade700,
          ),
        ),
        Expanded(
          child: Text(
            method,
            style: TextStyle(fontSize: 10.sp, color: Colors.blue.shade600),
          ),
        ),
      ],
    );
  }
}
