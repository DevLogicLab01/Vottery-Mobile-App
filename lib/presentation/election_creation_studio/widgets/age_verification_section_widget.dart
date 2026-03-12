import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

/// Age Verification section for Election Creation.
/// Default: No Age Verification. Optional: AI Facial, Government ID, Digital Wallet.
class AgeVerificationSectionWidget extends StatelessWidget {
  const AgeVerificationSectionWidget({
    super.key,
    required this.requireAgeVerification,
    required this.selectedMethods,
    required this.onRequireChanged,
    required this.onMethodsChanged,
  });

  final bool requireAgeVerification;
  final List<String> selectedMethods;
  final ValueChanged<bool> onRequireChanged;
  final ValueChanged<List<String>> onMethodsChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Age Verification',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              'Optional. Default is "No Age Verification". When enabled, voters must verify age before voting.',
              style: TextStyle(
                fontSize: 11.sp,
                color: Colors.grey.shade700,
              ),
            ),
            SizedBox(height: 2.h),
            SwitchListTile(
              title: Text(
                'Require Age Verification',
                style: TextStyle(fontSize: 12.sp),
              ),
              value: requireAgeVerification,
              onChanged: onRequireChanged,
            ),
            if (requireAgeVerification) ...[
              SizedBox(height: 2.h),
              Text(
                'Verification Methods (select one or more)',
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              CheckboxListTile(
                title: Text(
                  'AI-Powered Facial Age Estimation',
                  style: TextStyle(fontSize: 11.sp),
                ),
                subtitle: Text(
                  'Privacy-first, no ID required',
                  style: TextStyle(fontSize: 10.sp, color: Colors.grey),
                ),
                value: selectedMethods.contains('facial'),
                onChanged: (v) {
                  final updated = List<String>.from(selectedMethods);
                  if (v == true) {
                    if (!updated.contains('facial')) updated.add('facial');
                  } else {
                    updated.remove('facial');
                  }
                  onMethodsChanged(updated);
                },
              ),
              CheckboxListTile(
                title: Text(
                  'Government ID & Biometric Matching',
                  style: TextStyle(fontSize: 11.sp),
                ),
                subtitle: Text(
                  'High-assurance (passport, driver\'s license)',
                  style: TextStyle(fontSize: 10.sp, color: Colors.grey),
                ),
                value: selectedMethods.contains('government_id'),
                onChanged: (v) {
                  final updated = List<String>.from(selectedMethods);
                  if (v == true) {
                    if (!updated.contains('government_id')) updated.add('government_id');
                  } else {
                    updated.remove('government_id');
                  }
                  onMethodsChanged(updated);
                },
              ),
              CheckboxListTile(
                title: Text(
                  'Reusable Digital Identity Wallets',
                  style: TextStyle(fontSize: 11.sp),
                ),
                subtitle: Text(
                  'Yoti Keys, AgeKey – verify once, reuse',
                  style: TextStyle(fontSize: 10.sp, color: Colors.grey),
                ),
                value: selectedMethods.contains('digital_wallet'),
                onChanged: (v) {
                  final updated = List<String>.from(selectedMethods);
                  if (v == true) {
                    if (!updated.contains('digital_wallet')) updated.add('digital_wallet');
                  } else {
                    updated.remove('digital_wallet');
                  }
                  onMethodsChanged(updated);
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
