import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../services/user_security_service.dart';

class SecuritySettingsWidget extends StatefulWidget {
  final Map<String, dynamic>? settings;
  final VoidCallback onSettingsChanged;

  const SecuritySettingsWidget({
    super.key,
    required this.settings,
    required this.onSettingsChanged,
  });

  @override
  State<SecuritySettingsWidget> createState() => _SecuritySettingsWidgetState();
}

class _SecuritySettingsWidgetState extends State<SecuritySettingsWidget> {
  bool _twoFactorEnabled = false;
  String _twoFactorMethod = 'sms';
  bool _biometricEnabled = false;
  bool _breachNotifications = true;
  int _sessionTimeout = 60;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() {
    if (widget.settings != null) {
      setState(() {
        _twoFactorEnabled = widget.settings!['two_factor_enabled'] ?? false;
        _twoFactorMethod = widget.settings!['two_factor_method'] ?? 'sms';
        _biometricEnabled = widget.settings!['biometric_enabled'] ?? false;
        _breachNotifications =
            widget.settings!['breach_notifications_enabled'] ?? true;
        _sessionTimeout = widget.settings!['session_timeout_minutes'] ?? 60;
      });
    }
  }

  Future<void> _updateSettings() async {
    final success = await UserSecurityService.instance.updateSecuritySettings(
      twoFactorEnabled: _twoFactorEnabled,
      twoFactorMethod: _twoFactorMethod,
      biometricEnabled: _biometricEnabled,
      sessionTimeoutMinutes: _sessionTimeout,
      breachNotificationsEnabled: _breachNotifications,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Security settings updated'),
          backgroundColor: Colors.green,
        ),
      );
      widget.onSettingsChanged();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: EdgeInsets.all(3.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Two-Factor Authentication
          Text(
            'Two-Factor Authentication',
            style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 1.h),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  value: _twoFactorEnabled,
                  onChanged: (value) {
                    setState(() => _twoFactorEnabled = value);
                  },
                  title: Text(
                    'Enable Two-Factor Authentication',
                    style: TextStyle(fontSize: 13.sp),
                  ),
                  subtitle: Text(
                    'Add extra security layer to your account',
                    style: TextStyle(fontSize: 11.sp),
                  ),
                ),
                if (_twoFactorEnabled)
                  Padding(
                    padding: EdgeInsets.all(3.w),
                    child: DropdownButtonFormField<String>(
                      value: _twoFactorMethod,
                      decoration: const InputDecoration(
                        labelText: '2FA Method',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'sms', child: Text('SMS')),
                        DropdownMenuItem(
                          value: 'authenticator',
                          child: Text('Authenticator App'),
                        ),
                        DropdownMenuItem(value: 'email', child: Text('Email')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _twoFactorMethod = value);
                        }
                      },
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(height: 2.h),

          // Biometric Authentication
          Text(
            'Biometric Authentication',
            style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 1.h),
          Card(
            child: SwitchListTile(
              value: _biometricEnabled,
              onChanged: (value) {
                setState(() => _biometricEnabled = value);
              },
              title: Text(
                'Enable Biometric Login',
                style: TextStyle(fontSize: 13.sp),
              ),
              subtitle: Text(
                'Use Face ID, fingerprint, or pattern lock',
                style: TextStyle(fontSize: 11.sp),
              ),
            ),
          ),
          SizedBox(height: 2.h),

          // Session Management
          Text(
            'Session Management',
            style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 1.h),
          Card(
            child: Padding(
              padding: EdgeInsets.all(3.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Session Timeout: $_sessionTimeout minutes',
                    style: TextStyle(fontSize: 13.sp),
                  ),
                  SizedBox(height: 1.h),
                  Slider(
                    value: _sessionTimeout.toDouble(),
                    min: 15,
                    max: 240,
                    divisions: 15,
                    label: '$_sessionTimeout min',
                    onChanged: (value) {
                      setState(() => _sessionTimeout = value.toInt());
                    },
                  ),
                  Text(
                    'Automatically log out after inactivity',
                    style: TextStyle(fontSize: 11.sp, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 2.h),

          // Privacy Settings
          Text(
            'Privacy & Notifications',
            style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 1.h),
          Card(
            child: SwitchListTile(
              value: _breachNotifications,
              onChanged: (value) {
                setState(() => _breachNotifications = value);
              },
              title: Text(
                'Data Breach Notifications',
                style: TextStyle(fontSize: 13.sp),
              ),
              subtitle: Text(
                'Receive alerts about potential security breaches',
                style: TextStyle(fontSize: 11.sp),
              ),
            ),
          ),
          SizedBox(height: 3.h),

          // Save button
          SizedBox(
            width: double.infinity,
            height: 6.h,
            child: ElevatedButton(
              onPressed: _updateSettings,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
              ),
              child: Text(
                'Save Security Settings',
                style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
