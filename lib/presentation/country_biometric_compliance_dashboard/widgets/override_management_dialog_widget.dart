import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../services/country_biometric_compliance_service.dart';
import '../../../theme/app_theme.dart';

class OverrideManagementDialogWidget extends StatefulWidget {
  final Map<String, dynamic> country;

  const OverrideManagementDialogWidget({super.key, required this.country});

  @override
  State<OverrideManagementDialogWidget> createState() =>
      _OverrideManagementDialogWidgetState();
}

class _OverrideManagementDialogWidgetState
    extends State<OverrideManagementDialogWidget> {
  final _complianceService = CountryBiometricComplianceService.instance;
  final _justificationController = TextEditingController();
  bool _acknowledged = false;
  bool _isProcessing = false;

  @override
  void dispose() {
    _justificationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final countryCode = widget.country['country_code'] as String;
    final countryName = widget.country['country_name'] as String;

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.warning_amber, color: Colors.orange, size: 6.w),
          SizedBox(width: 2.w),
          Expanded(
            child: Text('GDPR Override', style: TextStyle(fontSize: 16.sp)),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Legal Warning',
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.red.shade900,
                    ),
                  ),
                  SizedBox(height: 1.h),
                  Text(
                    'Enabling biometric authentication for $countryName ($countryCode) violates GDPR Article 9 regulations regarding special category personal data.',
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: Colors.red.shade700,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              'Justification (Required)',
              style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 1.h),
            TextField(
              controller: _justificationController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText:
                    'Provide legal justification for this override (e.g., explicit user consent, legal basis)...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                filled: true,
                fillColor: AppTheme.backgroundLight,
              ),
            ),
            SizedBox(height: 2.h),
            Container(
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Liability Acknowledgment',
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.orange.shade900,
                    ),
                  ),
                  SizedBox(height: 1.h),
                  CheckboxListTile(
                    value: _acknowledged,
                    onChanged: (value) {
                      setState(() => _acknowledged = value ?? false);
                    },
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    title: Text(
                      'I acknowledge full legal liability for enabling biometric authentication in this GDPR-protected country and confirm that proper legal basis exists.',
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: Colors.orange.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isProcessing ? null : () => Navigator.pop(context, false),
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed:
              _isProcessing ||
                  !_acknowledged ||
                  _justificationController.text.trim().isEmpty
              ? null
              : _handleOverride,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
          child: _isProcessing
              ? SizedBox(
                  width: 4.w,
                  height: 4.w,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text('Override & Enable'),
        ),
      ],
    );
  }

  Future<void> _handleOverride() async {
    setState(() => _isProcessing = true);

    final countryCode = widget.country['country_code'] as String;
    final countryName = widget.country['country_name'] as String;

    final success = await _complianceService.overrideGDPRCountry(
      countryCode: countryCode,
      justification: _justificationController.text.trim(),
      acknowledged: _acknowledged,
    );

    setState(() => _isProcessing = false);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'GDPR override applied for $countryName. Biometric enabled with liability acknowledgment.',
            ),
            backgroundColor: Colors.orange,
          ),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to apply override'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
