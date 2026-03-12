import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../services/sms_compliance_service.dart';
import '../../../theme/app_theme.dart';

class ConsentManagementWidget extends StatefulWidget {
  const ConsentManagementWidget({super.key});

  @override
  State<ConsentManagementWidget> createState() =>
      _ConsentManagementWidgetState();
}

class _ConsentManagementWidgetState extends State<ConsentManagementWidget> {
  final SMSComplianceService _service = SMSComplianceService.instance;

  List<Map<String, dynamic>> _consents = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadConsents();
  }

  Future<void> _loadConsents() async {
    setState(() => _isLoading = true);
    final consents = await _service.getUserConsents();
    if (mounted) {
      setState(() {
        _consents = consents;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_consents.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.privacy_tip, size: 48.sp, color: AppTheme.textSecondary),
            SizedBox(height: 2.h),
            Text(
              'No consent records found',
              style: TextStyle(fontSize: 14.sp, color: AppTheme.textSecondary),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(3.w),
      itemCount: _consents.length,
      itemBuilder: (context, index) {
        final consent = _consents[index];
        return _buildConsentCard(consent);
      },
    );
  }

  Widget _buildConsentCard(Map<String, dynamic> consent) {
    final consentType = consent['consent_type'] as String;
    final consentStatus = consent['consent_status'] as String;
    final isOptedIn = consentStatus == 'opted_in';

    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: AppThemeColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isOptedIn ? Icons.check_circle : Icons.cancel,
                color: isOptedIn ? Colors.green : Colors.red,
                size: 20.sp,
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: Text(
                  consentType.toUpperCase(),
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryLight,
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                decoration: BoxDecoration(
                  color: isOptedIn
                      ? Colors.green.withAlpha(26)
                      : Colors.red.withAlpha(26),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  consentStatus.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                    color: isOptedIn ? Colors.green : Colors.red,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Text(
            'Phone: ${consent['phone_number']}',
            style: TextStyle(fontSize: 12.sp, color: AppTheme.textSecondary),
          ),
          SizedBox(height: 0.5.h),
          Text(
            'Method: ${consent['consent_method'] ?? 'N/A'}',
            style: TextStyle(fontSize: 12.sp, color: AppTheme.textSecondary),
          ),
          if (isOptedIn)
            Padding(
              padding: EdgeInsets.only(top: 1.h),
              child: ElevatedButton(
                onPressed: () => _revokeConsent(consent['consent_id']),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  minimumSize: Size(double.infinity, 5.h),
                ),
                child: Text(
                  'Revoke Consent',
                  style: TextStyle(fontSize: 12.sp),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _revokeConsent(String consentId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Revoke Consent'),
        content: const Text(
          'Are you sure you want to opt-out of SMS communications?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Revoke'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _service.revokeConsent(consentId: consentId);
      _loadConsents();
    }
  }
}