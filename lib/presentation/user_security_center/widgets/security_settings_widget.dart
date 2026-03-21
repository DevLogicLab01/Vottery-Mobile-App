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
  final TextEditingController _twoFactorRecipientController =
      TextEditingController();
  final TextEditingController _twoFactorCodeController = TextEditingController();
  bool _isSendingTwoFactorCode = false;
  bool _isVerifyingTwoFactorCode = false;
  bool _isSettingUpAuthenticator = false;
  String? _authenticatorSecret;
  String? _authenticatorQrUri;

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

  @override
  void dispose() {
    _twoFactorRecipientController.dispose();
    _twoFactorCodeController.dispose();
    super.dispose();
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

  Future<void> _sendTwoFactorCode() async {
    if (_twoFactorMethod == 'authenticator') {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Use your authenticator app to generate the current code.',
          ),
        ),
      );
      return;
    }

    final recipient = _twoFactorRecipientController.text.trim();
    if (recipient.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter email or phone for 2FA')),
      );
      return;
    }

    setState(() => _isSendingTwoFactorCode = true);
    final success = await UserSecurityService.instance.sendTwoFactorCode(
      method: _twoFactorMethod,
      recipient: recipient,
    );
    if (!mounted) return;
    setState(() => _isSendingTwoFactorCode = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Verification code sent successfully'
              : 'Failed to send verification code',
        ),
      ),
    );
  }

  Future<void> _verifyTwoFactorCode() async {
    final recipient = _twoFactorRecipientController.text.trim();
    final code = _twoFactorCodeController.text.trim();
    if (code.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter the verification code')),
      );
      return;
    }

    if (_twoFactorMethod != 'authenticator' && recipient.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter email or phone for verification')),
      );
      return;
    }

    setState(() => _isVerifyingTwoFactorCode = true);
    final success = _twoFactorMethod == 'authenticator'
        ? await UserSecurityService.instance.verifyAuthenticatorCode(
            code: code,
          )
        : await UserSecurityService.instance.verifyTwoFactorCode(
            method: _twoFactorMethod,
            recipient: recipient,
            code: code,
          );
    if (!mounted) return;
    setState(() => _isVerifyingTwoFactorCode = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? '2FA code verified successfully'
              : 'Invalid or expired verification code',
        ),
      ),
    );
  }

  Future<void> _setupAuthenticator() async {
    setState(() => _isSettingUpAuthenticator = true);
    final setupData = await UserSecurityService.instance.setupAuthenticator();
    if (!mounted) return;
    setState(() {
      _isSettingUpAuthenticator = false;
      _authenticatorSecret = setupData?['secret']?.toString();
      _authenticatorQrUri =
          setupData?['qrCode']?.toString() ?? setupData?['otpauthUrl']?.toString();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          setupData == null
              ? 'Failed to setup authenticator'
              : 'Authenticator setup data generated',
        ),
      ),
    );
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
                    child: Column(
                      children: [
                        DropdownButtonFormField<String>(
                          initialValue: _twoFactorMethod,
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
                        SizedBox(height: 1.h),
                        if (_twoFactorMethod != 'authenticator')
                          TextFormField(
                            controller: _twoFactorRecipientController,
                            decoration: InputDecoration(
                              labelText: _twoFactorMethod == 'email'
                                  ? 'Email for OTP'
                                  : 'Phone for OTP',
                              border: const OutlineInputBorder(),
                            ),
                          ),
                        if (_twoFactorMethod == 'authenticator')
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'Generate setup secret, add it in your authenticator app, then enter the current code below.',
                                  style: TextStyle(
                                    fontSize: 11.sp,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ),
                              SizedBox(height: 1.h),
                              OutlinedButton(
                                onPressed: _isSettingUpAuthenticator
                                    ? null
                                    : _setupAuthenticator,
                                child: Text(
                                  _isSettingUpAuthenticator
                                      ? 'Preparing...'
                                      : 'Setup Authenticator',
                                ),
                              ),
                              if (_authenticatorSecret != null) ...[
                                SizedBox(height: 1.h),
                                Text(
                                  'Secret: $_authenticatorSecret',
                                  style: TextStyle(
                                    fontSize: 10.sp,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                              if (_authenticatorQrUri != null) ...[
                                SizedBox(height: 0.5.h),
                                Text(
                                  'QR/URI: $_authenticatorQrUri',
                                  style: TextStyle(
                                    fontSize: 9.sp,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        SizedBox(height: 1.h),
                        TextFormField(
                          controller: _twoFactorCodeController,
                          decoration: const InputDecoration(
                            labelText: 'Verification code',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        SizedBox(height: 1.h),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _isSendingTwoFactorCode
                                    ? null
                                    : _sendTwoFactorCode,
                                child: Text(
                                  _isSendingTwoFactorCode
                                      ? 'Sending...'
                                      : 'Send code',
                                ),
                              ),
                            ),
                            SizedBox(width: 2.w),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _isVerifyingTwoFactorCode
                                    ? null
                                    : _verifyTwoFactorCode,
                                child: Text(
                                  _isVerifyingTwoFactorCode
                                      ? 'Verifying...'
                                      : 'Verify',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
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
