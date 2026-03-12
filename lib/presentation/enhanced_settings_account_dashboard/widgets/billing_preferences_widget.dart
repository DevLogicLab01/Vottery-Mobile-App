import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class BillingPreferencesWidget extends StatefulWidget {
  final Map<String, dynamic>? preferences;
  final Function(Map<String, dynamic>) onUpdate;

  const BillingPreferencesWidget({
    super.key,
    this.preferences,
    required this.onUpdate,
  });

  @override
  State<BillingPreferencesWidget> createState() =>
      _BillingPreferencesWidgetState();
}

class _BillingPreferencesWidgetState extends State<BillingPreferencesWidget> {
  late bool emailAlertsEnabled;
  late bool failedPaymentAlerts;
  late bool renewalReminders;
  late bool autoRenewalEnabled;

  @override
  void initState() {
    super.initState();
    emailAlertsEnabled = widget.preferences?['email_alerts_enabled'] ?? true;
    failedPaymentAlerts = widget.preferences?['failed_payment_alerts'] ?? true;
    renewalReminders = widget.preferences?['renewal_reminders'] ?? true;
    autoRenewalEnabled = widget.preferences?['auto_renewal_enabled'] ?? true;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Billing Preferences',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          SizedBox(height: 3.h),
          _buildPreferenceCard(
            'Email Alerts',
            'Receive billing notifications via email',
            emailAlertsEnabled,
            (value) => setState(() => emailAlertsEnabled = value),
          ),
          _buildPreferenceCard(
            'Failed Payment Alerts',
            'Get notified when payments fail',
            failedPaymentAlerts,
            (value) => setState(() => failedPaymentAlerts = value),
          ),
          _buildPreferenceCard(
            'Renewal Reminders',
            'Receive reminders before subscription renewal',
            renewalReminders,
            (value) => setState(() => renewalReminders = value),
          ),
          _buildPreferenceCard(
            'Auto-Renewal',
            'Automatically renew subscription',
            autoRenewalEnabled,
            (value) => setState(() => autoRenewalEnabled = value),
          ),
          SizedBox(height: 3.h),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _savePreferences,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryLight,
                padding: EdgeInsets.symmetric(vertical: 1.5.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              child: Text(
                'Save Preferences',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreferenceCard(
    String title,
    String subtitle,
    bool value,
    Function(bool) onChanged,
  ) {
    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimaryLight,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: AppTheme.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppTheme.primaryLight,
          ),
        ],
      ),
    );
  }

  void _savePreferences() {
    widget.onUpdate({
      'email_alerts_enabled': emailAlertsEnabled,
      'failed_payment_alerts': failedPaymentAlerts,
      'renewal_reminders': renewalReminders,
      'auto_renewal_enabled': autoRenewalEnabled,
    });
  }
}
