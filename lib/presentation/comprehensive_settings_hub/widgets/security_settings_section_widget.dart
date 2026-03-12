import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../user_profile/widgets/settings_section_widget.dart';

/// Security settings section widget for authentication and session management.
class SecuritySettingsSectionWidget extends StatelessWidget {
  const SecuritySettingsSectionWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return SettingsSectionWidget(
      title: 'Security Settings',
      items: [
        {
          'icon': 'security',
          'title': 'Two-Factor Authentication',
          'subtitle': 'Add extra security to your account',
          'onTap': () {
            _showTwoFactorDialog(context);
          },
        },
        {
          'icon': 'fingerprint',
          'title': 'Biometric Authentication',
          'subtitle': 'Use fingerprint or face ID',
          'onTap': () {
            // Remove AppRoutes reference as it's not defined in app_routes.dart
            // Navigator.pushNamed(context, AppRoutes.biometricAuthentication);
          },
        },
        {
          'icon': 'devices',
          'title': 'Active Sessions',
          'subtitle': '2 active devices',
          'onTap': () {
            _showActiveSessionsDialog(context);
          },
        },
      ],
    );
  }

  void _showTwoFactorDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Two-Factor Authentication'),
        content: const Text(
          'Enable two-factor authentication to add an extra layer of security to your account.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Two-factor authentication enabled'),
                ),
              );
            },
            child: const Text('Enable'),
          ),
        ],
      ),
    );
  }

  void _showActiveSessionsDialog(BuildContext context) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Active Sessions'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.phone_android),
              title: const Text('iPhone 14 Pro'),
              subtitle: const Text('San Francisco, CA • Active now'),
              trailing: TextButton(
                onPressed: () {},
                child: Text(
                  'Current',
                  style: TextStyle(color: theme.colorScheme.primary),
                ),
              ),
            ),
            SizedBox(height: 1.h),
            ListTile(
              leading: const Icon(Icons.laptop_mac),
              title: const Text('MacBook Pro'),
              subtitle: const Text('San Francisco, CA • 2 hours ago'),
              trailing: TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Session signed out')),
                  );
                },
                child: Text(
                  'Sign Out',
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}