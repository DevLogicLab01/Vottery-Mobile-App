import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../user_profile/widgets/settings_section_widget.dart';
import './widgets/account_management_section_widget.dart';
import './widgets/privacy_controls_section_widget.dart';
import './widgets/security_settings_section_widget.dart';
import '../../widgets/error_boundary_wrapper.dart';

/// Comprehensive Settings Hub centralizing all user preferences
/// and account management options.
/// Implements grouped settings sections with expandable cards and quick toggles.
class ComprehensiveSettingsHub extends StatefulWidget {
  const ComprehensiveSettingsHub({super.key});

  @override
  State<ComprehensiveSettingsHub> createState() =>
      _ComprehensiveSettingsHubState();
}

class _ComprehensiveSettingsHubState extends State<ComprehensiveSettingsHub> {
  // Search query
  String searchQuery = '';

  // Notification preferences
  bool pushNotifications = true;
  bool emailAlerts = false;
  bool inAppNotifications = true;

  // Privacy settings
  bool dataSharing = false;
  bool anonymousVoting = true;

  // App preferences
  bool autoPlay = false;

  @override
  Widget build(BuildContext context) {
    return ErrorBoundaryWrapper(
      screenName: 'ComprehensiveSettingsHub',
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
          title: Text(
            'Settings',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Theme.of(context).colorScheme.onPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          centerTitle: true,
        ),
        body: Column(
          children: [
            // Search Bar
            Container(
              padding: EdgeInsets.all(4.w),
              color: Theme.of(context).colorScheme.surface,
              child: TextField(
                onChanged: (value) {
                  setState(() => searchQuery = value);
                },
                decoration: InputDecoration(
                  hintText: 'Search settings...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Theme.of(
                        context,
                      ).colorScheme.outline.withValues(alpha: 0.3),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Theme.of(
                        context,
                      ).colorScheme.outline.withValues(alpha: 0.3),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.primary,
                      width: 2,
                    ),
                  ),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surface,
                ),
              ),
            ),

            // Settings Sections
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    SizedBox(height: 2.h),

                    // Account Management
                    const AccountManagementSectionWidget(),

                    SizedBox(height: 2.h),

                    // Security Settings
                    const SecuritySettingsSectionWidget(),

                    SizedBox(height: 2.h),

                    // SMS & Security Management
                    SettingsSectionWidget(
                      title: 'SMS & Security Management',
                      items: [
                        {
                          'icon': 'sms',
                          'title': 'SMS Emergency Alerts Hub',
                          'subtitle':
                              'Manage emergency SMS notifications and contacts',
                          'onTap': () {
                            // ... Remove this block ...
                          },
                        },
                        {
                          'icon': 'security',
                          'title': 'User Security Center',
                          'subtitle':
                              'View fraud risk score and manage device security',
                          'onTap': () {
                            // ... Remove this block ...
                          },
                        },
                      ],
                    ),

                    SizedBox(height: 2.h),

                    // Privacy Controls
                    PrivacyControlsSectionWidget(
                      dataSharing: dataSharing,
                      anonymousVoting: anonymousVoting,
                      onDataSharingChanged: (value) {
                        setState(() => dataSharing = value);
                      },
                      onAnonymousVotingChanged: (value) {
                        setState(() => anonymousVoting = value);
                      },
                    ),

                    SizedBox(height: 2.h),

                    // Notification Preferences
                    SettingsSectionWidget(
                      title: 'Notification Preferences',
                      items: [
                        {
                          'icon': 'notifications',
                          'title': 'Push Notifications',
                          'subtitle':
                              'Receive push notifications on your device',
                          'value': pushNotifications,
                          'onToggle': (bool value) {
                            setState(() => pushNotifications = value);
                          },
                        },
                        {
                          'icon': 'email',
                          'title': 'Email Alerts',
                          'subtitle': 'Get important updates via email',
                          'value': emailAlerts,
                          'onToggle': (bool value) {
                            setState(() => emailAlerts = value);
                          },
                        },
                        {
                          'icon': 'notifications_active',
                          'title': 'In-App Notifications',
                          'subtitle': 'Show notifications within the app',
                          'value': inAppNotifications,
                          'onToggle': (bool value) {
                            setState(() => inAppNotifications = value);
                          },
                        },
                      ],
                    ),

                    SizedBox(height: 2.h),

                    // App Preferences
                    SettingsSectionWidget(
                      title: 'App Preferences',
                      items: [
                        {
                          'icon': 'language',
                          'title': 'Language',
                          'subtitle': 'English (US)',
                          'onTap': () {
                            _showLanguageDialog(context);
                          },
                        },
                        {
                          'icon': 'dark_mode',
                          'title': 'Theme',
                          'subtitle': 'Light mode',
                          'onTap': () {
                            _showThemeDialog(context);
                          },
                        },
                        {
                          'icon': 'play_circle',
                          'title': 'Auto-play Videos',
                          'subtitle': 'Automatically play videos in feed',
                          'value': autoPlay,
                          'onToggle': (bool value) {
                            setState(() => autoPlay = value);
                          },
                        },
                      ],
                    ),

                    SizedBox(height: 2.h),

                    // Batch 8 Features
                    SettingsSectionWidget(
                      title: 'Batch 8 Features',
                      items: [
                        {
                          'icon': 'account_balance',
                          'title': 'Settlement Reconciliation Hub',
                          'subtitle':
                              'View discrepancy alerts and automated retry timeline',
                          'onTap': () {
                            // ... Remove this block ...
                          },
                        },
                        {
                          'icon': 'accessibility',
                          'title': 'Accessibility Settings',
                          'subtitle':
                              'Font scaling, offline mode, and visual preferences',
                          'onTap': () {
                            // ... Remove this block ...
                          },
                        },
                      ],
                    ),

                    SizedBox(height: 2.h),

                    // Advanced Settings
                    SettingsSectionWidget(
                      title: 'Advanced',
                      items: [
                        {
                          'icon': 'download',
                          'title': 'Download Your Data',
                          'subtitle': 'Request a copy of your data',
                          'onTap': () {
                            _showDataExportDialog(context);
                          },
                        },
                        {
                          'icon': 'delete_forever',
                          'title': 'Delete Account',
                          'subtitle': 'Permanently delete your account',
                          'onTap': () {
                            _showDeleteAccountDialog(context);
                          },
                        },
                      ],
                    ),

                    SizedBox(height: 3.h),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLanguageDialog(BuildContext context) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Language'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Text('🇺🇸', style: TextStyle(fontSize: 24)),
              title: const Text('English (US)'),
              trailing: Icon(Icons.check, color: theme.colorScheme.primary),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Text('🇪🇸', style: TextStyle(fontSize: 24)),
              title: const Text('Español'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Text('🇫🇷', style: TextStyle(fontSize: 24)),
              title: const Text('Français'),
              onTap: () => Navigator.pop(context),
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

  void _showThemeDialog(BuildContext context) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Select Theme'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.light_mode),
              title: const Text('Light Mode'),
              trailing: Icon(Icons.check, color: theme.colorScheme.primary),
              onTap: () {
                _applyThemeMode(context, ThemeMode.light);
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              leading: const Icon(Icons.dark_mode),
              title: const Text('Dark Mode'),
              onTap: () {
                _applyThemeMode(context, ThemeMode.dark);
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              leading: const Icon(Icons.brightness_auto),
              title: const Text('System Default'),
              onTap: () {
                _applyThemeMode(context, ThemeMode.system);
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _applyThemeMode(BuildContext context, ThemeMode mode) {
    final app = context.findAncestorStateOfType<_VotteryAppState>();
    app?.setThemeMode(mode);
  }

  void _showDataExportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Download Your Data'),
        content: const Text(
          'We will prepare a copy of your data and send it to your email address within 48 hours.',
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
                const SnackBar(content: Text('Data export request submitted')),
              );
            },
            child: const Text('Request'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete Account',
          style: TextStyle(color: theme.colorScheme.error),
        ),
        content: const Text(
          'This action cannot be undone. All your data will be permanently deleted.',
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
                  content: Text('Account deletion requires verification'),
                ),
              );
            },
            style: TextButton.styleFrom(
              foregroundColor: theme.colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}