import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../constants/roles.dart';
import '../../constants/vottery_ads_constants.dart';
import '../../core/app_export.dart';
import '../../routes/app_routes.dart';
import '../../services/auth_service_new.dart';
import '../../widgets/error_boundary_wrapper.dart';
import './widgets/expandable_menu_section_widget.dart';
import './widgets/menu_item_widget.dart';
import './widgets/profile_menu_header_widget.dart';

/// Facebook-Style Profile Menu providing comprehensive account management
/// through hierarchical dropdown system accessible from profile icon.
/// Implements overlay modal presentation with smooth animations and backdrop blur.
class FacebookStyleProfileMenu extends StatefulWidget {
  const FacebookStyleProfileMenu({super.key});

  @override
  State<FacebookStyleProfileMenu> createState() =>
      _FacebookStyleProfileMenuState();
}

class _FacebookStyleProfileMenuState extends State<FacebookStyleProfileMenu> {
  String? expandedSection;
  bool isDarkMode = false;
  String? _userRole;

  final Map<String, dynamic> userData = {
    "name": "Sarah Johnson",
    "email": "sarah.johnson@email.com",
    "avatar":
        "https://img.rocket.new/generatedImages/rocket_gen_img_103b528db-1763293982935.png",
    "semanticLabel":
        "Professional headshot of a woman with long brown hair wearing a white blouse",
  };

  @override
  void initState() {
    super.initState();
    _loadThemePreference();
    _loadUserRole();
  }

  Future<void> _loadUserRole() async {
    final profile = await AuthService.instance.getUserProfile();
    if (mounted) {
      setState(() {
        _userRole = profile?['role'] as String?;
      });
    }
  }

  bool get _showAdminTools => AppRoles.isAdminRole(_userRole);
  bool get _showBatch2Sections => false;

  Future<void> _loadThemePreference() async {
    final brightness =
        WidgetsBinding.instance.platformDispatcher.platformBrightness;
    setState(() {
      isDarkMode = brightness == Brightness.dark;
    });
  }

  void _toggleSection(String sectionId) {
    setState(() {
      if (expandedSection == sectionId) {
        expandedSection = null;
      } else {
        expandedSection = sectionId;
      }
    });
  }

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await AuthService.instance.signOut();
                if (mounted) {
                  Navigator.of(
                    context,
                  ).pushNamedAndRemoveUntil('/splash', (route) => false);
                }
              } catch (e) {
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Logout failed: $e')));
                }
              }
            },
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
  }

  void _handleDarkModeToggle(bool value) {
    setState(() {
      isDarkMode = value;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              value ? Icons.dark_mode : Icons.light_mode,
              color: Colors.white,
            ),
            SizedBox(width: 2.w),
            Text(value ? 'Dark mode enabled' : 'Light mode enabled'),
          ],
        ),
        backgroundColor: AppTheme.vibrantYellow.withAlpha(204),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ErrorBoundaryWrapper(
      screenName: 'FacebookStyleProfileMenu',
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: theme.colorScheme.onPrimary,
          title: Text(
            'Menu',
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.onPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              SizedBox(height: 2.h),

              ProfileMenuHeaderWidget(userData: userData),

              SizedBox(height: 3.h),

              ExpandableMenuSectionWidget(
                title: 'Account',
                icon: 'person',
                isExpanded: expandedSection == 'account',
                onToggle: () => _toggleSection('account'),
                children: [
                  MenuItemWidget(
                    icon: 'card_membership',
                    title: 'Subscription',
                    subtitle: 'Manage your plan & billing',
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        AppRoutes.subscriptionArchitecture,
                      );
                    },
                  ),
                  MenuItemWidget(
                    icon: 'account_circle',
                    title: 'Profile',
                    onTap: () {
                      Navigator.pushNamed(context, AppRoutes.userProfile);
                    },
                  ),
                ],
              ),

              SizedBox(height: 2.h),

              // Switch or Upgrade section (role switching / upgrade prompts)
              ExpandableMenuSectionWidget(
                title: 'Switch or Upgrade',
                icon: 'swap_horiz',
                isExpanded: expandedSection == 'switch_upgrade',
                onToggle: () => _toggleSection('switch_upgrade'),
                children: [
                  MenuItemWidget(
                    icon: 'add_circle_outline',
                    title: AppRoles.isCreatorRole(_userRole)
                        ? 'Creator view'
                        : 'Upgrade to Creator',
                    subtitle: AppRoles.isCreatorRole(_userRole)
                        ? 'Create elections, analytics'
                        : 'Create elections and monetize',
                    onTap: () {
                      if (AppRoles.isCreatorRole(_userRole)) {
                        Navigator.pushNamed(
                          context,
                          AppRoutes.electionCreationStudio,
                        );
                      } else {
                        Navigator.pushNamed(
                          context,
                          AppRoutes.roleUpgrade,
                          arguments: <String, String>{'role': 'creator'},
                        );
                      }
                    },
                  ),
                  if (AppRoles.isCreatorRole(_userRole))
                    MenuItemWidget(
                      icon: 'school',
                      title: 'Creator onboarding',
                      subtitle: 'Get set up for monetization',
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          AppRoutes.creatorOnboardingWizard,
                        );
                      },
                    ),
                  MenuItemWidget(
                    icon: 'campaign',
                    title: AppRoles.isAdvertiserRole(_userRole)
                        ? 'Advertiser view'
                        : 'Upgrade to Advertiser',
                    subtitle: AppRoles.isAdvertiserRole(_userRole)
                        ? 'Campaigns, ROI dashboards'
                        : 'Run campaigns and ads',
                    onTap: () {
                      if (AppRoles.isAdvertiserRole(_userRole)) {
                        Navigator.pushNamed(
                          context,
                          VotteryAdsConstants.votteryAdsStudioRoute,
                        );
                      } else {
                        Navigator.pushNamed(
                          context,
                          AppRoutes.roleUpgrade,
                          arguments: <String, String>{'role': 'advertiser'},
                        );
                      }
                    },
                  ),
                ],
              ),

              SizedBox(height: 2.h),

              // Monitoring & DevOps Section
              if (_showBatch2Sections)
                ExpandableMenuSectionWidget(
                  title: 'Monitoring & DevOps',
                  icon: 'analytics',
                  isExpanded: expandedSection == 'monitoring',
                  onToggle: () => _toggleSection('monitoring'),
                  children: [
                  MenuItemWidget(
                    icon: 'analytics',
                    title: 'Incident Analytics',
                    subtitle: 'Incident response & correlation',
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        AppRoutes.incidentResponseAnalytics,
                      );
                    },
                  ),
                  MenuItemWidget(
                    icon: 'monitor_heart',
                    title: 'Production Monitoring',
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        AppRoutes.unifiedProductionMonitoringHub,
                      );
                    },
                  ),
                  MenuItemWidget(
                    icon: 'speed',
                    title: 'API Rate Limiting',
                    subtitle: 'Quota monitoring & throttling',
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        AppRoutes.apiRateLimitingDashboard,
                      );
                    },
                  ),
                  MenuItemWidget(
                    icon: 'phone_android',
                    title: 'Mobile Framework Hub',
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        AppRoutes.flutterMobileImplementationFrameworkHub,
                      );
                    },
                  ),
                ],
                ),

              SizedBox(height: 2.h),

              ExpandableMenuSectionWidget(
                title: 'Settings & Privacy',
                icon: 'settings',
                isExpanded: expandedSection == 'settings',
                onToggle: () => _toggleSection('settings'),
                children: [
                  MenuItemWidget(
                    icon: 'settings',
                    title: 'Settings',
                    onTap: () {
                      Navigator.pushNamed(context, AppRoutes.comprehensiveSettingsHub);
                    },
                  ),
                  MenuItemWidget(
                    icon: 'lock',
                    title: 'Privacy Shortcuts',
                    onTap: () {
                      Navigator.pushNamed(context, AppRoutes.comprehensiveSettingsHub);
                    },
                  ),
                  MenuItemWidget(
                    icon: 'history',
                    title: 'Activity Log',
                    onTap: () {
                      Navigator.pushNamed(context, AppRoutes.voteHistory);
                    },
                  ),
                  MenuItemWidget(
                    icon: 'notifications_active',
                    title: 'Log Notification Center',
                    subtitle: 'Critical alerts & security',
                    onTap: () {
                      Navigator.pushNamed(context, AppRoutes.logNotificationCenter);
                    },
                  ),
                  MenuItemWidget(
                    icon: 'security',
                    title: 'Content removed & appeals',
                    subtitle: 'Appeal removed content',
                    onTap: () {
                      Navigator.pushNamed(context, AppRoutes.contentRemovedAppeal);
                    },
                  ),
                  MenuItemWidget(
                    icon: 'accessibility_new',
                    title: 'Accessibility',
                    onTap: () => Navigator.pushNamed(
                      context,
                      AppRoutes.accessibilitySettingsHub,
                    ),
                  ),
                  MenuItemWidget(
                    icon: 'language',
                    title: 'Language',
                    onTap: () => Navigator.pushNamed(
                      context,
                      AppRoutes.globalLanguageSettingsHub,
                    ),
                  ),
                  MenuItemWidget(
                    icon: 'fingerprint',
                    title: 'Passkey Authentication',
                    onTap: () => Navigator.pushNamed(
                      context,
                      AppRoutes.passkeyAuthenticationCenter,
                    ),
                  ),
                  MenuItemWidget(
                    icon: 'science',
                    title: 'Incident Testing Suite',
                    subtitle: 'Stress testing & benchmarks',
                    onTap: () => Navigator.pushNamed(
                      context,
                      AppRoutes.incidentTestingSuiteDashboard,
                    ),
                  ),
                  MenuItemWidget(
                    icon: 'psychology',
                    title: 'Multi-AI Threat Intelligence',
                    subtitle: 'Unified AI threat analysis',
                    onTap: () => Navigator.pushNamed(
                      context,
                      AppRoutes.multiAiThreatOrchestrationHub,
                    ),
                  ),
                  // TIER 3 Features
                  MenuItemWidget(
                    icon: 'security',
                    title: 'Team Incident War Room',
                    subtitle: 'Collaborative incident response',
                    onTap: () {
                      Navigator.pushNamed(context, AppRoutes.teamIncidentWarRoom);
                    },
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 4.w,
                      vertical: 1.h,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 10.w,
                          height: 10.w,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                isDarkMode
                                    ? AppTheme.primaryDark
                                    : AppTheme.primaryLight,
                                isDarkMode
                                    ? AppTheme.secondaryDark
                                    : AppTheme.secondaryLight,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          child: Center(
                            child: Icon(
                              isDarkMode ? Icons.dark_mode : Icons.light_mode,
                              color: Colors.white,
                              size: 5.w,
                            ),
                          ),
                        ),
                        SizedBox(width: 3.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Dark Mode',
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                isDarkMode ? 'On' : 'Off',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: AppTheme.textSecondaryLight,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: isDarkMode
                                ? AppTheme.vibrantYellow
                                : Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(20.0),
                          ),
                          child: Switch(
                            value: isDarkMode,
                            onChanged: _handleDarkModeToggle,
                            activeThumbColor: Colors.black,
                            activeTrackColor: AppTheme.vibrantYellow,
                            inactiveThumbColor: Colors.white,
                            inactiveTrackColor: Colors.grey.shade300,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              SizedBox(height: 2.h),

              ExpandableMenuSectionWidget(
                title: 'Help & Support',
                icon: 'help',
                isExpanded: expandedSection == 'help',
                onToggle: () => _toggleSection('help'),
                children: [
                  MenuItemWidget(
                    icon: 'help_center',
                    title: 'Help Center',
                    onTap: () {
                      Navigator.pushNamed(context, AppRoutes.helpSupportCenter);
                    },
                  ),
                  MenuItemWidget(
                    icon: 'confirmation_number',
                    title: 'Help & support',
                    subtitle: 'Tickets & FAQ (same as Web profile menu)',
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        AppRoutes.centralizedSupportTicketingSystemWebCanonical,
                      );
                    },
                  ),
                  MenuItemWidget(
                    icon: 'support_agent',
                    title: 'Creator Support Hub',
                    subtitle: 'Tickets, Guides, AI FAQ',
                    onTap: () {
                      Navigator.pushNamed(context, AppRoutes.creatorSupportHub);
                    },
                  ),
                  ListTile(
                    leading: const Icon(
                      Icons.swap_horiz,
                      color: Colors.deepPurple,
                    ),
                    title: const Text('AI Failover Dashboard'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(
                        context,
                        AppRoutes.aiServiceFailoverControlCenter,
                      );
                    },
                  ),
                  MenuItemWidget(
                    icon: 'inbox',
                    title: 'Support Inbox',
                    badge: '2',
                    onTap: () {
                      Navigator.pushNamed(context, AppRoutes.directMessagingScreen);
                    },
                  ),
                  MenuItemWidget(
                    icon: 'report',
                    title: 'Report a Problem',
                    onTap: () {
                      Navigator.pushNamed(context, AppRoutes.userFeedbackPortal);
                    },
                  ),
                  MenuItemWidget(
                    icon: 'description',
                    title: 'Terms & Policies',
                    onTap: () {
                      _showTermsDialog(context);
                    },
                  ),
                ],
              ),

              SizedBox(height: 2.h),

              // Security & Fraud Detection Section
              if (_showBatch2Sections)
                ExpandableMenuSectionWidget(
                  title: 'Security & Fraud Detection',
                  icon: 'security',
                  isExpanded: expandedSection == 'security',
                  onToggle: () => _toggleSection('security'),
                  children: [
                  MenuItemWidget(
                    icon: 'security',
                    title: 'Advanced Fraud Detection',
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        AppRoutes.advancedFraudDetectionCenter,
                      );
                    },
                  ),
                  MenuItemWidget(
                    icon: 'analytics',
                    title: 'Perplexity Fraud Analysis',
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        AppRoutes.perplexityFraudDashboardScreen,
                      );
                    },
                  ),
                  MenuItemWidget(
                    icon: 'security',
                    title: 'Fraud Investigation',
                    onTap: () => Navigator.pushNamed(
                      context,
                      AppRoutes.enhancedFraudInvestigationWorkflowsHub,
                    ),
                  ),
                  MenuItemWidget(
                    icon: 'sms',
                    title: 'SMS Emergency Alerts',
                    onTap: () => Navigator.pushNamed(
                      context,
                      AppRoutes.twilioSmsEmergencyAlertManagementCenter,
                    ),
                  ),
                  MenuItemWidget(
                    icon: 'warning',
                    title: 'Incident Management',
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        AppRoutes.unifiedIncidentManagementDashboard,
                      );
                    },
                  ),
                  MenuItemWidget(
                    icon: 'shield',
                    title: 'User Security Center',
                    onTap: () {
                      Navigator.pushNamed(context, AppRoutes.userSecurityCenter);
                    },
                  ),
                ],
                ),

              SizedBox(height: 2.h),

              ExpandableMenuSectionWidget(
                title: 'Account',
                icon: 'account_circle',
                isExpanded: expandedSection == 'account',
                onToggle: () => _toggleSection('account'),
                children: [
                  MenuItemWidget(
                    icon: 'person',
                    title: 'Profile',
                    onTap: () {
                      Navigator.pushNamed(context, AppRoutes.userProfile);
                    },
                  ),
                  MenuItemWidget(
                    icon: 'notifications',
                    title: 'Notifications',
                    onTap: () {
                      Navigator.pushNamed(context, AppRoutes.aiNotificationCenter);
                    },
                  ),
                  MenuItemWidget(
                    icon: 'campaign',
                    title: 'Prediction Pool Notifications',
                    subtitle: 'Pool creation, countdowns, resolution, leaderboard',
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        AppRoutes.predictionPoolNotificationsHubWebCanonical,
                      );
                    },
                  ),
                  MenuItemWidget(
                    icon: 'account_balance_wallet',
                    title: 'Multi-Currency Settlement',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(
                        context,
                        AppRoutes.multiCurrencySettlementDashboardWebCanonical,
                      );
                    },
                  ),
                  MenuItemWidget(
                    icon: 'payments',
                    title: 'Payout Management Hub',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(
                        context,
                        AppRoutes.stripeConnectPayoutManagementHub,
                      );
                    },
                  ),
                  MenuItemWidget(
                    icon: 'analytics',
                    title: 'Creator Analytics',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(
                        context,
                        AppRoutes.creatorAnalyticsDashboard,
                      );
                    },
                  ),
                  MenuItemWidget(
                    icon: 'insights',
                    title: 'Cross-Domain Intelligence',
                    onTap: () => Navigator.pushNamed(
                      context,
                      AppRoutes.crossDomainIntelligenceHub,
                    ),
                  ),
                  MenuItemWidget(
                    icon: 'smart_toy',
                    title: 'Claude Autonomous Actions',
                    onTap: () => Navigator.pushNamed(
                      context,
                      AppRoutes.claudeAutonomousActionsHub,
                    ),
                  ),
                  MenuItemWidget(
                    icon: 'logout',
                    title: 'Log Out',
                    onTap: _handleLogout,
                  ),
                ],
              ),

              // Admin Tools Section (admin role only)
              if (_showAdminTools && _showBatch2Sections) ...[
                SizedBox(height: 2.h),
                ExpandableMenuSectionWidget(
                  title: 'Admin Tools',
                  icon: 'admin_panel_settings',
                  isExpanded: expandedSection == 'admin_tools',
                  onToggle: () => _toggleSection('admin_tools'),
                  children: [
                  MenuItemWidget(
                    icon: 'dashboard',
                    title: 'Admin Dashboard',
                    subtitle: 'System overview and management',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, AppRoutes.adminDashboard);
                    },
                  ),
                  MenuItemWidget(
                    icon: 'flag',
                    title: 'Feature Toggle Panel',
                    subtitle: 'Enable/disable platform features',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, AppRoutes.adminFeatureTogglePanel);
                    },
                  ),
                  MenuItemWidget(
                    icon: 'integration_instructions',
                    title: 'Integration Management',
                    subtitle: 'Manage third-party services',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(
                        context,
                        '/integrationManagementPanel',
                      );
                    },
                  ),
                  MenuItemWidget(
                    icon: 'people',
                    title: 'Multi-Role Admin',
                    subtitle: 'Role-based access control',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(
                        context,
                        AppRoutes.multiRoleAdminControlCenter,
                      );
                    },
                  ),
                  MenuItemWidget(
                    icon: 'shield',
                    title: 'Country Biometric Compliance',
                    onTap: () => Navigator.pushNamed(
                      context,
                      AppRoutes.countryBiometricComplianceDashboard,
                    ),
                  ),
                ],
              ),
              ],
              // Monitoring & DevOps Section (admin role only)
              if (_showAdminTools && _showBatch2Sections) ...[
                SizedBox(height: 2.h),
                ExpandableMenuSectionWidget(
                  title: 'Monitoring & DevOps',
                  icon: 'monitor_heart',
                  isExpanded: expandedSection == 'monitoring',
                  onToggle: () => _toggleSection('monitoring'),
                  children: [
                  MenuItemWidget(
                    icon: 'psychology',
                    title: 'Claude Decision Hub',
                    subtitle: 'AI-powered dispute & fraud decisions',
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        '/claude-decision-reasoning-hub',
                      );
                    },
                  ),
                  MenuItemWidget(
                    icon: 'smart_toy',
                    title: 'Automation Control Panel',
                    subtitle: 'Festival mode, fraud pause, retention',
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        '/admin-automation-control-panel',
                      );
                    },
                  ),
                  MenuItemWidget(
                    icon: 'monitor_heart',
                    title: 'Production Monitoring Hub',
                    subtitle: 'Unified command center',
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        '/unified-production-monitoring-hub',
                      );
                    },
                  ),
                  MenuItemWidget(
                    icon: 'psychology',
                    title: 'Performance Optimization AI',
                    subtitle: 'Claude-powered recommendations',
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        '/performance-optimization-recommendations-engine-dashboard',
                      );
                    },
                  ),
                  MenuItemWidget(
                    icon: 'phone_android',
                    title: 'Mobile Framework Hub',
                    subtitle: 'Web/Mobile sync & constants',
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        '/flutter-mobile-implementation-framework-hub',
                      );
                    },
                  ),
                  MenuItemWidget(
                    icon: 'wifi_off',
                    title: 'Error Recovery Hub',
                    subtitle: 'Realtime gamification error handling',
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        '/realtime-gamification-error-recovery-hub',
                      );
                    },
                  ),
                  MenuItemWidget(
                    icon: 'bolt',
                    title: 'Datadog Response Center',
                    subtitle: 'Automated threshold breach response',
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        '/automated-datadog-response-command-center',
                      );
                    },
                  ),
                  MenuItemWidget(
                    icon: 'psychology',
                    title: 'Performance Tuning AI',
                    subtitle: 'Perplexity-powered optimization',
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        '/predictive-performance-tuning',
                      );
                    },
                  ),
                  MenuItemWidget(
                    icon: 'attach_money',
                    title: 'Cost Analytics & ROI',
                    subtitle: 'Infrastructure cost tracking',
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        '/cost-analytics-roi-dashboard',
                      );
                    },
                  ),
                ],
              ),
              ],
              SizedBox(height: 2.h),
              if (_showBatch2Sections)
                ExpandableMenuSectionWidget(
                  title: 'Advertising',
                  icon: 'campaign',
                  isExpanded: expandedSection == 'advertising',
                  onToggle: () => _toggleSection('advertising'),
                  children: [
                  MenuItemWidget(
                    icon: 'campaign',
                    title: 'Campaign Management',
                    subtitle: 'Manage sponsored elections',
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        AppRoutes.campaignManagementDashboardWebCanonical,
                      );
                    },
                  ),
                  MenuItemWidget(
                    icon: 'trending_up',
                    title: 'Dynamic CPE Engine',
                    subtitle: 'Zone pricing, demand, 24h drift',
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        AppRoutes.dynamicCpePricingEngineDashboardWebCanonical,
                      );
                    },
                  ),
                  MenuItemWidget(
                    icon: 'create',
                    title: 'Ads Studio',
                    subtitle: 'Create participatory ads',
                    onTap: () {
                      Navigator.pushNamed(context, AppRoutes.participatoryAdsStudio);
                    },
                  ),
                  MenuItemWidget(
                    icon: 'bar_chart',
                    title: 'Advertiser Analytics',
                    subtitle: 'ROI & performance metrics',
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        AppRoutes.advertiserAnalyticsDashboardWebCanonical,
                      );
                    },
                  ),
                ],
                ),
              SizedBox(height: 2.h),
              if (_showBatch2Sections)
                ExpandableMenuSectionWidget(
                  title: 'Payments',
                  icon: 'payments',
                  isExpanded: expandedSection == 'payments',
                  onToggle: () => _toggleSection('payments'),
                  children: [
                  MenuItemWidget(
                    icon: 'hub',
                    title: 'Payment Orchestration Hub',
                    subtitle: 'Centralized payment management',
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        AppRoutes.unifiedPaymentOrchestrationHub,
                      );
                    },
                  ),
                  MenuItemWidget(
                    icon: 'account_balance_wallet',
                    title: 'Multi-Currency Settlement',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(
                        context,
                        AppRoutes.multiCurrencySettlementDashboardWebCanonical,
                      );
                    },
                  ),
                  MenuItemWidget(
                    icon: 'payments',
                    title: 'Payout Management',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(
                        context,
                        AppRoutes.stripeConnectPayoutManagementHub,
                      );
                    },
                  ),
                ],
                ),

              SizedBox(height: 4.h),
            ],
          ),
        ),
      ),
    );
  }

  void _showLanguageSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(4.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Select Language',
              style: GoogleFonts.inter(
                fontSize: 16.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 2.h),
            ListTile(
              title: Text('English (US)'),
              trailing: Icon(Icons.check, color: AppTheme.vibrantYellow),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              title: Text('Spanish'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              title: Text('French'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              title: Text('German'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  void _showTermsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Terms & Policies'),
        content: SingleChildScrollView(
          child: Text(
            'Terms of Service and Privacy Policy content would be displayed here.',
            style: GoogleFonts.inter(fontSize: 13.sp),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }
}
