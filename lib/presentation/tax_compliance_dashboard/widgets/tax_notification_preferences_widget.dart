import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../services/tax_compliance_service.dart';
import '../../../theme/app_theme.dart';

/// Tax Notification Preferences Widget
/// Configure email, push, and SMS alerts for tax compliance notifications
class TaxNotificationPreferencesWidget extends StatefulWidget {
  const TaxNotificationPreferencesWidget({super.key});

  @override
  State<TaxNotificationPreferencesWidget> createState() =>
      _TaxNotificationPreferencesWidgetState();
}

class _TaxNotificationPreferencesWidgetState
    extends State<TaxNotificationPreferencesWidget> {
  final TaxComplianceService _taxService = TaxComplianceService.instance;

  bool _isLoading = true;
  List<Map<String, dynamic>> _preferences = [];
  Map<String, dynamic> _deliveryStats = {};

  final Map<String, String> _notificationTypeLabels = {
    'expiration_90_days': '90 Days Before Expiration',
    'expiration_60_days': '60 Days Before Expiration',
    'expiration_30_days': '30 Days Before Expiration',
    'expiration_7_days': '7 Days Before Expiration (Critical)',
    'document_expired': 'Document Expired',
    'compliance_violation': 'Compliance Violation',
    'jurisdiction_status_change': 'Jurisdiction Status Change',
    'weekly_compliance_digest': 'Weekly Compliance Digest',
    'monthly_compliance_report': 'Monthly Compliance Report',
    'filing_deadline_reminder': 'Filing Deadline Reminder',
  };

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    setState(() => _isLoading = true);

    try {
      final results = await Future.wait([
        _taxService.getTaxNotificationPreferences(),
        _taxService.getNotificationDeliveryStats(),
      ]);

      if (mounted) {
        setState(() {
          _preferences = results[0] as List<Map<String, dynamic>>;
          _deliveryStats = results[1] as Map<String, dynamic>;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Load preferences error: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDeliveryStatsHeader(),
          SizedBox(height: 3.h),
          _buildPreferencesList(),
        ],
      ),
    );
  }

  Widget _buildDeliveryStatsHeader() {
    final totalSent = _deliveryStats['total_sent'] ?? 0;
    final totalDelivered = _deliveryStats['total_delivered'] ?? 0;
    final totalOpened = _deliveryStats['total_opened'] ?? 0;

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue, Colors.blue.withAlpha(179)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Notification Delivery Statistics',
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.white.withAlpha(204),
            ),
          ),
          SizedBox(height: 2.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('Sent', totalSent.toString()),
              _buildStatItem('Delivered', totalDelivered.toString()),
              _buildStatItem('Opened', totalOpened.toString()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 11.sp, color: Colors.white.withAlpha(204)),
        ),
      ],
    );
  }

  Widget _buildPreferencesList() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Notification Preferences',
            style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 2.h),
          ..._notificationTypeLabels.entries.map((entry) {
            final notificationType = entry.key;
            final label = entry.value;
            final preference = _preferences.firstWhere(
              (p) => p['notification_type'] == notificationType,
              orElse: () => {
                'notification_type': notificationType,
                'email_enabled': true,
                'push_enabled': true,
                'sms_enabled': false,
              },
            );

            return _buildPreferenceItem(notificationType, label, preference);
          }),
        ],
      ),
    );
  }

  Widget _buildPreferenceItem(
    String notificationType,
    String label,
    Map<String, dynamic> preference,
  ) {
    final emailEnabled = preference['email_enabled'] ?? true;
    final pushEnabled = preference['push_enabled'] ?? true;
    final smsEnabled = preference['sms_enabled'] ?? false;

    return Padding(
      padding: EdgeInsets.only(bottom: 2.h),
      child: Container(
        padding: EdgeInsets.all(3.w),
        decoration: BoxDecoration(
          color: Colors.grey.withAlpha(26),
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 1.h),
            Row(
              children: [
                Expanded(
                  child: _buildChannelToggle(
                    'Email',
                    Icons.email,
                    emailEnabled,
                    (value) => _updatePreference(
                      notificationType,
                      emailEnabled: value,
                    ),
                  ),
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: _buildChannelToggle(
                    'Push',
                    Icons.notifications,
                    pushEnabled,
                    (value) =>
                        _updatePreference(notificationType, pushEnabled: value),
                  ),
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: _buildChannelToggle(
                    'SMS',
                    Icons.sms,
                    smsEnabled,
                    (value) =>
                        _updatePreference(notificationType, smsEnabled: value),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChannelToggle(
    String label,
    IconData icon,
    bool enabled,
    Function(bool) onChanged,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 1.h),
      decoration: BoxDecoration(
        color: enabled
            ? AppTheme.primaryLight.withAlpha(26)
            : Colors.grey.withAlpha(26),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 4.w,
                color: enabled ? AppTheme.primaryLight : Colors.grey,
              ),
              SizedBox(width: 1.w),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10.sp,
                  color: enabled ? AppTheme.primaryLight : Colors.grey,
                ),
              ),
            ],
          ),
          Transform.scale(
            scale: 0.8,
            child: Switch(
              value: enabled,
              onChanged: onChanged,
              activeThumbColor: AppTheme.primaryLight,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _updatePreference(
    String notificationType, {
    bool? emailEnabled,
    bool? pushEnabled,
    bool? smsEnabled,
  }) async {
    final success = await _taxService.updateTaxNotificationPreference(
      notificationType: notificationType,
      emailEnabled: emailEnabled,
      pushEnabled: pushEnabled,
      smsEnabled: smsEnabled,
    );

    if (success) {
      _loadPreferences();
    }
  }
}
