import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../services/unified_alert_service.dart';

class AlertPreferencesWidget extends StatefulWidget {
  const AlertPreferencesWidget({super.key});

  @override
  State<AlertPreferencesWidget> createState() => _AlertPreferencesWidgetState();
}

class _AlertPreferencesWidgetState extends State<AlertPreferencesWidget> {
  final UnifiedAlertService _alertService = UnifiedAlertService.instance;
  List<Map<String, dynamic>> _preferences = [];
  Map<String, dynamic>? _quietHours;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await _alertService.getAlertPreferences();
      final quiet = await _alertService.getQuietHours();
      setState(() {
        _preferences = prefs;
        _quietHours = quiet;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Load preferences error: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updatePreference(
    String category,
    String field,
    bool value,
  ) async {
    await _alertService.updateAlertPreference(
      category: category,
      enabled: field == 'enabled' ? value : null,
      pushEnabled: field == 'push_enabled' ? value : null,
      emailEnabled: field == 'email_enabled' ? value : null,
      smsEnabled: field == 'sms_enabled' ? value : null,
      soundEnabled: field == 'sound_enabled' ? value : null,
      vibrationEnabled: field == 'vibration_enabled' ? value : null,
    );
    _loadPreferences();
  }

  Future<void> _updateQuietHours(bool enabled) async {
    await _alertService.updateQuietHours(
      enabled: enabled,
      startTime: _quietHours?['start_time'] ?? '22:00:00',
      endTime: _quietHours?['end_time'] ?? '08:00:00',
    );
    _loadPreferences();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: 90.h,
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Alert Preferences',
                style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          SizedBox(height: 2.h),

          // Quiet Hours
          Card(
            child: Padding(
              padding: EdgeInsets.all(3.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.bedtime, color: Colors.indigo),
                      SizedBox(width: 2.w),
                      Text(
                        'Quiet Hours',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      Switch(
                        value: _quietHours?['enabled'] ?? false,
                        onChanged: _updateQuietHours,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (_quietHours?['enabled'] == true) ...[
            SizedBox(height: 1.h),
            Text(
              '${_quietHours?['start_time']} - ${_quietHours?['end_time']}',
              style: TextStyle(fontSize: 12.sp, color: Colors.grey),
            ),
          ],
          SizedBox(height: 2.h),

          // Category Preferences
          Text(
            'Category Settings',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 1.h),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: _preferences.length,
                    itemBuilder: (context, index) {
                      final pref = _preferences[index];
                      final category = pref['category'] as String;

                      return Card(
                        margin: EdgeInsets.only(bottom: 2.h),
                        child: ExpansionTile(
                          leading: Icon(_getCategoryIcon(category)),
                          title: Text(
                            category.toUpperCase(),
                            style: TextStyle(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          children: [
                            Padding(
                              padding: EdgeInsets.all(3.w),
                              child: Column(
                                children: [
                                  _buildToggle(
                                    'Enabled',
                                    pref['enabled'] ?? false,
                                    (value) => _updatePreference(
                                      category,
                                      'enabled',
                                      value,
                                    ),
                                  ),
                                  _buildToggle(
                                    'Push Notifications',
                                    pref['push_enabled'] ?? false,
                                    (value) => _updatePreference(
                                      category,
                                      'push_enabled',
                                      value,
                                    ),
                                  ),
                                  _buildToggle(
                                    'Email Notifications',
                                    pref['email_enabled'] ?? false,
                                    (value) => _updatePreference(
                                      category,
                                      'email_enabled',
                                      value,
                                    ),
                                  ),
                                  _buildToggle(
                                    'SMS Notifications',
                                    pref['sms_enabled'] ?? false,
                                    (value) => _updatePreference(
                                      category,
                                      'sms_enabled',
                                      value,
                                    ),
                                  ),
                                  _buildToggle(
                                    'Sound',
                                    pref['sound_enabled'] ?? false,
                                    (value) => _updatePreference(
                                      category,
                                      'sound_enabled',
                                      value,
                                    ),
                                  ),
                                  _buildToggle(
                                    'Vibration',
                                    pref['vibration_enabled'] ?? false,
                                    (value) => _updatePreference(
                                      category,
                                      'vibration_enabled',
                                      value,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggle(String label, bool value, Function(bool) onChanged) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 0.5.h),
      child: Row(
        children: [
          Text(label, style: TextStyle(fontSize: 12.sp)),
          const Spacer(),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'votes':
        return Icons.how_to_vote;
      case 'messages':
        return Icons.message;
      case 'achievements':
        return Icons.emoji_events;
      case 'elections':
        return Icons.campaign;
      case 'campaigns':
        return Icons.business;
      case 'security':
        return Icons.security;
      case 'payments':
        return Icons.payment;
      case 'system':
        return Icons.settings;
      default:
        return Icons.notifications;
    }
  }
}
