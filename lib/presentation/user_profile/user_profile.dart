import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../config/batch1_route_allowlist.dart';
import '../../core/app_export.dart';
import '../../services/auth_service_new.dart';
import '../../services/gamification_service.dart';
import '../../services/vp_service.dart';
import '../../widgets/error_boundary_wrapper.dart';
import '../../widgets/gamification/platform_gamification_banner.dart';
import '../../widgets/shimmer_skeleton_loader.dart';
import './widgets/profile_header_widget.dart';
import './widgets/settings_section_widget.dart';
import './widgets/sign_out_button_widget.dart';

/// User Profile screen for account management and app preferences.
/// Implements Contemporary Civic Minimalism with security-focused mobile interface.
/// This is a content-only widget as it's part of bottom tab navigation (Profile tab active).
class UserProfile extends StatefulWidget {
  const UserProfile({super.key});

  @override
  State<UserProfile> createState() => _UserProfileState();
}

class _UserProfileState extends State<UserProfile> {
  // Mock user data
  final Map<String, dynamic> userData = {
    "name": "Sarah Johnson",
    "email": "sarah.johnson@email.com",
    "avatar":
        "https://img.rocket.new/generatedImages/rocket_gen_img_103b528db-1763293982935.png",
    "semanticLabel":
        "Professional headshot of a woman with long brown hair wearing a white blouse",
    "accountCreated": "January 15, 2024",
    "biometricEnabled": true,
    "pushNotifications": true,
    "voteAlerts": true,
    "resultUpdates": false,
    "dataSharing": false,
    "anonymousVoting": true,
    "twoFactorAuth": true,
    "activeSessions": 2,
  };

  // VP and Gamification data
  Map<String, dynamic>? vpBalance;
  Map<String, dynamic>? userLevel;
  Map<String, dynamic>? userStreak;
  bool isLoadingGamification = true;

  @override
  void initState() {
    super.initState();
    _loadGamificationData();
  }

  Future<void> _loadGamificationData() async {
    setState(() => isLoadingGamification = true);

    try {
      final vp = await VPService.instance.getVPBalance();
      final level = await GamificationService.instance.getUserLevel();
      final streak = await GamificationService.instance.getUserStreak();

      if (mounted) {
        setState(() {
          vpBalance = vp;
          userLevel = level;
          userStreak = streak;
          isLoadingGamification = false;
        });
      }
    } catch (e) {
      debugPrint('Load gamification data error: $e');
      if (mounted) {
        setState(() => isLoadingGamification = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ErrorBoundaryWrapper(
      screenName: 'UserProfile',
      onRetry: _loadGamificationData,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Text('Profile'),
          actions: [
            if (Batch1RouteAllowlist.isAllowed(AppRoutes.facebookStyleProfileMenu))
              GestureDetector(
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    AppRoutes.facebookStyleProfileMenu,
                  );
                },
                child: CustomIconWidget(
                  iconName: 'settings',
                  color: theme.colorScheme.onPrimary,
                  size: 24,
                ),
              ),
          ],
        ),
        body: isLoadingGamification
            ? const SkeletonDashboard()
            : SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    SizedBox(height: 3.h),

                    // Profile Header
                    ProfileHeaderWidget(userData: userData),

                    SizedBox(height: 1.h),

                    // Platform Gamification Banner
                    const PlatformGamificationBanner(),

                    SizedBox(height: 2.h),

                    // VP and Gamification Stats
                    _buildGamificationStats(theme),
                    SizedBox(height: 3.h),

                    SizedBox(height: 1.h),

                    // Account Settings Section
                    SettingsSectionWidget(
                      title: 'Account',
                      items: [
                        {
                          'icon': 'person',
                          'title': 'Edit Profile',
                          'subtitle': 'Update your personal information',
                          'onTap': () => _navigateToEditProfile(context),
                        },
                        {
                          'icon': 'lock',
                          'title': 'Change Password',
                          'subtitle': 'Update your security credentials',
                          'onTap': () => _navigateToChangePassword(context),
                        },
                        {
                          'icon': 'fingerprint',
                          'title': 'Biometric Settings',
                          'subtitle': 'Fingerprint and face recognition',
                          'value': userData['biometricEnabled'],
                          'onToggle': (value) => _toggleBiometric(value),
                        },
                      ],
                    ),

                    SizedBox(height: 2.h),

                    // Notifications Settings Section
                    SettingsSectionWidget(
                      title: 'Notifications',
                      items: [
                        {
                          'icon': 'notifications',
                          'title': 'Push Notifications',
                          'subtitle': 'Receive app notifications',
                          'value': userData['pushNotifications'],
                          'onToggle': (value) =>
                              _togglePushNotifications(value),
                        },
                        {
                          'icon': 'campaign',
                          'title': 'Vote Alerts',
                          'subtitle': 'Get notified about new votes',
                          'value': userData['voteAlerts'],
                          'onToggle': (value) => _toggleVoteAlerts(value),
                        },
                        {
                          'icon': 'poll',
                          'title': 'Result Updates',
                          'subtitle': 'Notifications for vote results',
                          'value': userData['resultUpdates'],
                          'onToggle': (value) => _toggleResultUpdates(value),
                        },
                      ],
                    ),

                    SizedBox(height: 2.h),

                    // Privacy Settings Section
                    SettingsSectionWidget(
                      title: 'Privacy',
                      items: [
                        {
                          'icon': 'share',
                          'title': 'Data Sharing',
                          'subtitle': 'Share analytics data',
                          'value': userData['dataSharing'],
                          'onToggle': (value) => _toggleDataSharing(value),
                        },
                        {
                          'icon': 'visibility_off',
                          'title': 'Anonymous Voting',
                          'subtitle': 'Vote anonymously by default',
                          'value': userData['anonymousVoting'],
                          'onToggle': (value) => _toggleAnonymousVoting(value),
                        },
                      ],
                    ),

                    SizedBox(height: 2.h),

                    // Security Settings Section
                    SettingsSectionWidget(
                      title: 'Security',
                      items: [
                        {
                          'icon': 'security',
                          'title': 'Two-Factor Authentication',
                          'subtitle': 'Extra security for your account',
                          'value': userData['twoFactorAuth'],
                          'onToggle': (value) => _toggleTwoFactorAuth(value),
                        },
                        {
                          'icon': 'devices',
                          'title': 'Session Management',
                          'subtitle':
                              '${userData['activeSessions']} active sessions',
                          'onTap': () => _navigateToSessionManagement(context),
                        },
                        if (Batch1RouteAllowlist.isAllowed(
                          AppRoutes.userActivityLogViewer,
                        ))
                          {
                            'icon': 'article',
                            'title': 'My Activity Log',
                            'subtitle': 'View your activity history',
                            'onTap': () => Navigator.pushNamed(
                              context,
                              AppRoutes.userActivityLogViewer,
                            ),
                          },
                      ],
                    ),

                    SizedBox(height: 4.h),

                    // Sign Out Button
                    SignOutButtonWidget(onSignOut: _handleSignOut),

                    SizedBox(height: 4.h),
                  ],
                ),
              ),
      ),
    );
  }

  void _toggleBiometric(bool value) {
    setState(() {
      userData['biometricEnabled'] = value;
    });
    _showFeedbackSnackBar(
      'Biometric authentication ${value ? 'enabled' : 'disabled'}',
    );
  }

  void _togglePushNotifications(bool value) {
    setState(() {
      userData['pushNotifications'] = value;
    });
    _showFeedbackSnackBar(
      'Push notifications ${value ? 'enabled' : 'disabled'}',
    );
  }

  void _toggleVoteAlerts(bool value) {
    setState(() {
      userData['voteAlerts'] = value;
    });
    _showFeedbackSnackBar('Vote alerts ${value ? 'enabled' : 'disabled'}');
  }

  void _toggleResultUpdates(bool value) {
    setState(() {
      userData['resultUpdates'] = value;
    });
    _showFeedbackSnackBar('Result updates ${value ? 'enabled' : 'disabled'}');
  }

  void _toggleDataSharing(bool value) {
    setState(() {
      userData['dataSharing'] = value;
    });
    _showFeedbackSnackBar('Data sharing ${value ? 'enabled' : 'disabled'}');
  }

  void _toggleAnonymousVoting(bool value) {
    setState(() {
      userData['anonymousVoting'] = value;
    });
    _showFeedbackSnackBar('Anonymous voting ${value ? 'enabled' : 'disabled'}');
  }

  void _toggleTwoFactorAuth(bool value) {
    setState(() {
      userData['twoFactorAuth'] = value;
    });
    _showFeedbackSnackBar(
      'Two-factor authentication ${value ? 'enabled' : 'disabled'}',
    );
  }

  void _navigateToEditProfile(BuildContext context) {
    Navigator.of(
      context,
      rootNavigator: true,
    ).pushNamed(AppRoutes.settingsAccountDashboardWebCanonical);
  }

  void _navigateToChangePassword(BuildContext context) {
    Navigator.of(
      context,
      rootNavigator: true,
    ).pushNamed(AppRoutes.userSecurityCenterWebCanonical);
  }

  void _navigateToSessionManagement(BuildContext context) {
    Navigator.of(
      context,
      rootNavigator: true,
    ).pushNamed(AppRoutes.userSecurityCenterWebCanonical);
  }

  Future<void> _handleSignOut() async {
    try {
      await AuthService.instance.signOut();
      if (mounted) {
        Navigator.of(
          context,
          rootNavigator: true,
        ).pushReplacementNamed(AppRoutes.biometricAuthentication);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sign out failed: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _showFeedbackSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildGamificationStats(ThemeData theme) {
    final availableVP = vpBalance?['available_vp'] ?? 0;
    final currentLevel = userLevel?['current_level'] ?? 1;
    final levelTitle = userLevel?['level_title'] ?? 'Novice';
    final currentStreak = userStreak?['current_streak'] ?? 0;
    final vpMultiplier = (userLevel?['vp_multiplier'] ?? 1.0).toDouble();

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Gamification Stats',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 1.h),
          Row(
            children: [
              // VP Balance Card
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(3.w),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        theme.colorScheme.tertiary.withValues(alpha: 0.1),
                        theme.colorScheme.secondary.withValues(alpha: 0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12.0),
                    border: Border.all(
                      color: theme.colorScheme.tertiary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomIconWidget(
                        iconName: 'stars',
                        color: theme.colorScheme.tertiary,
                        size: 24,
                      ),
                      SizedBox(height: 1.h),
                      Text(
                        '$availableVP VP',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: theme.colorScheme.tertiary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'Vottery Points',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(width: 3.w),
              // Level Card
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(3.w),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        theme.colorScheme.primary.withValues(alpha: 0.1),
                        theme.colorScheme.secondary.withValues(alpha: 0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12.0),
                    border: Border.all(
                      color: theme.colorScheme.primary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomIconWidget(
                        iconName: 'military_tech',
                        color: theme.colorScheme.primary,
                        size: 24,
                      ),
                      SizedBox(height: 1.h),
                      Text(
                        'Level $currentLevel',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        levelTitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          // Streak and Multiplier
          Row(
            children: [
              // Streak Card
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(3.w),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(12.0),
                    border: Border.all(
                      color: theme.colorScheme.outline.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      CustomIconWidget(
                        iconName: 'local_fire_department',
                        color: theme.colorScheme.tertiary,
                        size: 20,
                      ),
                      SizedBox(width: 2.w),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$currentStreak days',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            'Streak',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(width: 3.w),
              // Multiplier Card
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(3.w),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(12.0),
                    border: Border.all(
                      color: theme.colorScheme.outline.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      CustomIconWidget(
                        iconName: 'trending_up',
                        color: theme.colorScheme.secondary,
                        size: 20,
                      ),
                      SizedBox(width: 2.w),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${vpMultiplier}x',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            'VP Multiplier',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
