import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../services/passkey_service.dart';
import '../../services/supabase_service.dart';
import '../../widgets/error_boundary_wrapper.dart';

class PasskeyAuthenticationCenter extends StatefulWidget {
  const PasskeyAuthenticationCenter({super.key});

  @override
  State<PasskeyAuthenticationCenter> createState() =>
      _PasskeyAuthenticationCenterState();
}

class _PasskeyAuthenticationCenterState
    extends State<PasskeyAuthenticationCenter> {
  final PasskeyService _passkeyService = PasskeyService.instance;

  bool _isSupported = false;
  bool _isLoading = true;
  bool _isRegistering = false;
  List<Map<String, dynamic>> _registeredPasskeys = [];
  List<Map<String, dynamic>> _authLogs = [];

  @override
  void initState() {
    super.initState();
    _checkSupport();
    _loadPasskeys();
    _loadAuthLogs();
  }

  Future<void> _checkSupport() async {
    final supported = await _passkeyService.isPasskeySupported();
    setState(() {
      _isSupported = supported;
      _isLoading = false;
    });
  }

  Future<void> _loadPasskeys() async {
    final passkeys = await _passkeyService.getUserPasskeys();
    setState(() => _registeredPasskeys = passkeys);
  }

  Future<void> _loadAuthLogs() async {
    final logs = await _passkeyService.getAuthenticationAuditLogs(limit: 20);
    setState(() => _authLogs = logs);
  }

  Future<void> _registerNewPasskey() async {
    setState(() => _isRegistering = true);

    final deviceName = await _showDeviceNameDialog();
    if (deviceName == null || deviceName.isEmpty) {
      setState(() => _isRegistering = false);
      return;
    }

    final userId = SupabaseService.instance.client.auth.currentUser?.id;
    if (userId == null) {
      setState(() => _isRegistering = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('User not authenticated')));
      }
      return;
    }

    final result = await _passkeyService.registerPasskey(
      userId: userId,
      deviceName: deviceName,
    );

    setState(() => _isRegistering = false);

    if (result != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passkey registered successfully')),
      );
      await _loadPasskeys();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to register passkey')),
      );
    }
  }

  Future<String?> _showDeviceNameDialog() async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Name Your Device'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'e.g., iPhone 15 Pro',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  Future<void> _revokePasskey(String passkeyId, String deviceName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Revoke Passkey'),
        content: Text(
          'Are you sure you want to revoke passkey for "$deviceName"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Revoke'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await _passkeyService.revokePasskey(passkeyId);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Passkey revoked successfully')),
        );
        await _loadPasskeys();
      }
    }
  }

  Future<void> _testAuthentication() async {
    final success = await _passkeyService.authenticateWithPasskey();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? 'Authentication successful' : 'Authentication failed',
          ),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
      if (success) {
        await _loadAuthLogs();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ErrorBoundaryWrapper(
      screenName: 'PasskeyAuthenticationCenter',
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: theme.colorScheme.onPrimary,
          title: Text(
            'Passkey Authentication',
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.onPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          centerTitle: true,
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : !_isSupported
            ? Center(
                child: Padding(
                  padding: EdgeInsets.all(4.w),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64.sp,
                        color: theme.colorScheme.error,
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        'Passkeys Not Supported',
                        style: theme.textTheme.headlineSmall,
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 1.h),
                      Text(
                        'Your device or browser does not support passkey authentication.',
                        style: theme.textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            : SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status Header
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(4.w),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            theme.colorScheme.primary,
                            theme.colorScheme.primary.withValues(alpha: 0.8),
                          ],
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.fingerprint,
                            size: 48.sp,
                            color: Colors.white,
                          ),
                          SizedBox(height: 1.h),
                          Text(
                            '${_registeredPasskeys.length} Devices Enrolled',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Biometric authentication enabled',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 2.h),

                    // Register New Passkey Button
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4.w),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isRegistering
                              ? null
                              : _registerNewPasskey,
                          icon: _isRegistering
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.add),
                          label: Text(
                            _isRegistering
                                ? 'Registering...'
                                : 'Register New Passkey',
                          ),
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 1.5.h),
                            backgroundColor: theme.colorScheme.primary,
                            foregroundColor: theme.colorScheme.onPrimary,
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: 2.h),

                    // Registered Devices
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4.w),
                      child: Text(
                        'Registered Devices',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SizedBox(height: 1.h),

                    if (_registeredPasskeys.isEmpty)
                      Padding(
                        padding: EdgeInsets.all(4.w),
                        child: Center(
                          child: Text(
                            'No passkeys registered yet',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.6,
                              ),
                            ),
                          ),
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _registeredPasskeys.length,
                        itemBuilder: (context, index) {
                          final passkey = _registeredPasskeys[index];
                          final deviceName =
                              passkey['device_name'] ?? 'Unknown Device';
                          final deviceType = passkey['device_type'] ?? 'mobile';
                          final lastUsed = passkey['last_used_at'];
                          final createdAt = DateTime.parse(
                            passkey['created_at'],
                          );

                          return Card(
                            margin: EdgeInsets.symmetric(
                              horizontal: 4.w,
                              vertical: 0.5.h,
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor:
                                    theme.colorScheme.primaryContainer,
                                child: Icon(
                                  deviceType == 'mobile'
                                      ? Icons.phone_android
                                      : deviceType == 'desktop'
                                      ? Icons.computer
                                      : Icons.security,
                                  color: theme.colorScheme.onPrimaryContainer,
                                ),
                              ),
                              title: Text(
                                deviceName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Added: ${_formatDate(createdAt)}'),
                                  if (lastUsed != null)
                                    Text(
                                      'Last used: ${_formatDate(DateTime.parse(lastUsed))}',
                                    ),
                                ],
                              ),
                              trailing: IconButton(
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: Colors.red,
                                ),
                                onPressed: () =>
                                    _revokePasskey(passkey['id'], deviceName),
                              ),
                            ),
                          );
                        },
                      ),

                    SizedBox(height: 2.h),

                    // Test Authentication Button
                    if (_registeredPasskeys.isNotEmpty)
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4.w),
                        child: OutlinedButton.icon(
                          onPressed: _testAuthentication,
                          icon: const Icon(Icons.verified_user),
                          label: const Text('Test Authentication'),
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 1.5.h),
                          ),
                        ),
                      ),

                    SizedBox(height: 2.h),

                    // Authentication History
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4.w),
                      child: Text(
                        'Authentication History',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SizedBox(height: 1.h),

                    if (_authLogs.isEmpty)
                      Padding(
                        padding: EdgeInsets.all(4.w),
                        child: Center(
                          child: Text(
                            'No authentication history',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.6,
                              ),
                            ),
                          ),
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _authLogs.length > 10
                            ? 10
                            : _authLogs.length,
                        itemBuilder: (context, index) {
                          final log = _authLogs[index];
                          final success = log['success'] ?? false;
                          final method = log['auth_method'] ?? 'unknown';
                          final timestamp = DateTime.parse(log['created_at']);

                          return Card(
                            margin: EdgeInsets.symmetric(
                              horizontal: 4.w,
                              vertical: 0.5.h,
                            ),
                            child: ListTile(
                              leading: Icon(
                                success ? Icons.check_circle : Icons.error,
                                color: success ? Colors.green : Colors.red,
                              ),
                              title: Text(
                                method.toUpperCase(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(_formatDateTime(timestamp)),
                              trailing: Chip(
                                label: Text(
                                  success ? 'Success' : 'Failed',
                                  style: TextStyle(
                                    color: success ? Colors.green : Colors.red,
                                    fontSize: 10.sp,
                                  ),
                                ),
                                backgroundColor: success
                                    ? Colors.green.withValues(alpha: 0.1)
                                    : Colors.red.withValues(alpha: 0.1),
                              ),
                            ),
                          );
                        },
                      ),

                    SizedBox(height: 4.h),
                  ],
                ),
              ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatDateTime(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
