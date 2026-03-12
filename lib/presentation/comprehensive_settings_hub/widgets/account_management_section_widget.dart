import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../user_profile/widgets/settings_section_widget.dart';

/// Account management section widget for profile and account settings.
class AccountManagementSectionWidget extends StatelessWidget {
  const AccountManagementSectionWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return SettingsSectionWidget(
      title: 'Account Management',
      items: [
        {
          'icon': 'person',
          'title': 'Edit Profile',
          'subtitle': 'Update your profile information',
          'onTap': () {
            Navigator.pushNamed(context, '/user_profile');
          },
        },
        {
          'icon': 'lock',
          'title': 'Change Password',
          'subtitle': 'Update your account password',
          'onTap': () {
            _showChangePasswordDialog(context);
          },
        },
        {
          'icon': 'email',
          'title': 'Email Verification',
          'subtitle': 'Verify your email address',
          'onTap': () {
            _showEmailVerificationDialog(context);
          },
        },
      ],
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    final theme = Theme.of(context);
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: currentPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Current Password',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 2.h),
            TextField(
              controller: newPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'New Password',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 2.h),
            TextField(
              controller: confirmPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Confirm New Password',
                border: OutlineInputBorder(),
              ),
            ),
          ],
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
                const SnackBar(content: Text('Password updated successfully')),
              );
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showEmailVerificationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Email Verification'),
        content: const Text(
          'A verification email has been sent to your email address. Please check your inbox.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}