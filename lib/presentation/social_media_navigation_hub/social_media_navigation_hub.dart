import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../config/batch1_route_allowlist.dart';
import '../../services/auth_service.dart';
import '../../widgets/dual_header_bottom_bar.dart';
import '../../widgets/dual_header_top_bar.dart';
import '../../widgets/error_boundary_wrapper.dart';

/// Social Media Navigation Hub - Comprehensive menu system
/// Facebook-style menu with all platform features and services
class SocialMediaNavigationHub extends StatefulWidget {
  const SocialMediaNavigationHub({super.key});

  @override
  State<SocialMediaNavigationHub> createState() =>
      _SocialMediaNavigationHubState();
}

class _SocialMediaNavigationHubState extends State<SocialMediaNavigationHub> {
  final AuthService _authService = AuthService.instance;

  @override
  Widget build(BuildContext context) {
    return ErrorBoundaryWrapper(
      screenName: 'SocialMediaNavigationHub',
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: DualHeaderTopBar(
          currentRoute: AppRoutes.socialMediaNavigationHub,
        ),
        body: ListView(
          padding: EdgeInsets.symmetric(vertical: 2.h),
          children: [
            _buildSection('Social', [
              _buildMenuItem(
                Icons.home,
                'Home Feed',
                'Your personalized social feed',
                AppRoutes.socialMediaHomeFeed,
              ),
              _buildMenuItem(
                Icons.auto_stories,
                'Moments',
                'Share ephemeral stories',
                AppRoutes.momentsStoriesHub,
              ),
              _buildMenuItem(
                Icons.video_library,
                'Jolts',
                'Short-form video content',
                AppRoutes.joltsVideoFeed,
              ),
              _buildMenuItem(
                Icons.groups,
                'Groups',
                'Connect with communities',
                AppRoutes.groupsHub,
              ),
              _buildMenuItem(
                Icons.how_to_vote,
                'Community Elections',
                'Topic-based community elections',
                AppRoutes.communityElectionsHub,
              ),
              _buildMenuItem(
                Icons.chat_bubble,
                'Messages',
                'Direct messaging',
                AppRoutes.directMessagingScreen,
              ),
            ]),
            _buildSection('Elections & Voting', [
              _buildMenuItem(
                Icons.add_circle,
                'Create Elections',
                'Start a new election',
                AppRoutes.electionCreationStudio,
              ),
              _buildMenuItem(
                Icons.how_to_vote,
                'Vote in Elections',
                'Find and participate in elections',
                AppRoutes.voteDiscovery,
              ),
              _buildMenuItem(
                Icons.verified_user,
                'Verify Elections',
                'Verify your vote on the blockchain',
                AppRoutes.blockchainVoteVerificationHub,
              ),
              _buildMenuItem(
                Icons.search,
                'Audit Elections',
                'Blockchain audit portal',
                AppRoutes.blockchainAuditPortal,
              ),
              _buildMenuItem(
                Icons.analytics,
                'Vote Analytics',
                'Election insights',
                AppRoutes.voteAnalytics,
              ),
              _buildMenuItem(
                Icons.history,
                'Vote History',
                'Your voting record',
                AppRoutes.voteHistory,
              ),
            ]),
            _buildSection('Friends & Activity', [
              _buildMenuItem(
                Icons.people,
                'Friends',
                'Friend requests and followers',
                AppRoutes.friendRequestsHub,
              ),
              _buildMenuItem(
                Icons.timeline,
                'Activity Feed',
                'Friend voting, achievements, interactions',
                AppRoutes.socialActivityTimeline,
              ),
            ]),
            _buildSection('Gamification', [
              _buildMenuItem(
                Icons.stars,
                'VP Economy',
                'Manage your Vottery Points',
                AppRoutes.vpEconomyDashboard,
              ),
              _buildMenuItem(
                Icons.emoji_events,
                'Gamification Hub',
                'Achievements and quests',
                AppRoutes.gamificationHub,
              ),
            ]),
            _buildSection('Analytics & Monetization', [
              _buildMenuItem(
                Icons.bar_chart,
                'Real-Time Analytics',
                'Live KPIs, engagement, revenue, ad ROI',
                AppRoutes.realTimeAnalyticsDashboard,
              ),
              _buildMenuItem(
                Icons.monitor_heart,
                'Live Platform Monitoring',
                'Active users, elections, revenue, 30s refresh',
                AppRoutes.livePlatformMonitoringDashboard,
              ),
              _buildMenuItem(
                Icons.trending_up,
                'Personal Analytics',
                'Voting performance, earnings, achievements',
                AppRoutes.personalAnalyticsDashboard,
              ),
              _buildMenuItem(
                Icons.analytics,
                'User & Election Analytics',
                'Participation, virality, watch time',
                AppRoutes.ga4EnhancedAnalyticsDashboard,
              ),
              _buildMenuItem(
                Icons.analytics,
                'GA4 Monetization Tracking',
                'Creator earnings analytics',
                AppRoutes.googleAnalyticsMonetizationTrackingHub,
              ),
              _buildMenuItem(
                Icons.account_balance_wallet,
                'Multi-Currency Settlement',
                'Global payout management',
                AppRoutes.multiCurrencySettlementDashboardWebCanonical,
              ),
              _buildMenuItem(
                Icons.casino,
                'Lottery System',
                'Prize distribution tracking',
                AppRoutes.walletPrizeDistributionCenter,
              ),
            ]),
            _buildSection('Advertising', [
              _buildMenuItem(
                Icons.campaign,
                'Campaign Management',
                'Sponsored elections hub',
                AppRoutes.campaignManagementDashboardWebCanonical,
              ),
              _buildMenuItem(
                Icons.trending_up,
                'Dynamic CPE Engine',
                'Zone pricing & demand matrix',
                AppRoutes.dynamicCpePricingEngineDashboardWebCanonical,
              ),
              _buildMenuItem(
                Icons.ads_click,
                'Vottery Ads Studio',
                'Unified campaign builder',
                AppRoutes.votteryAdsStudioWebCanonical,
              ),
            ]),
            _buildSection('Creator Monetization', [
              _buildMenuItem(
                Icons.attach_money,
                'Creator Earnings',
                'Track your revenue',
                AppRoutes.realTimeCreatorEarningsWidget,
              ),
              _buildMenuItem(
                Icons.handshake,
                'Brand Partnerships',
                'Collaboration opportunities',
                AppRoutes.brandPartnershipHub,
              ),
            ]),
            _buildSection('Notifications', [
              _buildMenuItem(
                Icons.notifications_active,
                'Alert Center',
                'Unified notification management',
                AppRoutes.unifiedAlertManagementCenter,
              ),
              _buildMenuItem(
                Icons.notifications,
                'Notification Hub',
                'All notifications',
                AppRoutes.notificationCenterHub,
              ),
            ]),
            _buildSection('Settings & Support', [
              _buildMenuItem(
                Icons.person,
                'Profile',
                'View and edit profile',
                AppRoutes.userProfile,
              ),
              _buildMenuItem(
                Icons.settings,
                'Settings',
                'Account preferences',
                AppRoutes.comprehensiveSettingsHub,
              ),
              _buildMenuItem(
                Icons.interests,
                'Topic Preferences',
                'Customize your interests',
                AppRoutes.topicPreferenceCollectionHub,
              ),
              _buildMenuItem(
                Icons.support_agent,
                'Support Tickets',
                'Get technical support',
                AppRoutes.supportTicketingSystem,
              ),
              _buildMenuItem(
                Icons.help,
                'Help & Support',
                'Get assistance',
                AppRoutes.helpSupportCenter,
              ),
            ]),
          ],
        ),
        bottomNavigationBar: DualHeaderBottomBar(
          currentRoute: AppRoutes.socialMediaNavigationHub,
          onNavigate: (route) {
            Navigator.pushNamed(context, route);
          },
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> items) {
    final visibleItems = items.where((item) => item is! SizedBox).toList();
    if (visibleItems.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
          child: Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
              color: AppTheme.textSecondaryLight,
            ),
          ),
        ),
        ...visibleItems,
        Divider(height: 2.h),
      ],
    );
  }

  Widget _buildMenuItem(
    IconData icon,
    String title,
    String subtitle,
    String route,
  ) {
    if (!Batch1RouteAllowlist.isAllowed(route)) {
      return const SizedBox.shrink();
    }
    return ListTile(
      leading: Container(
        padding: EdgeInsets.all(2.w),
        decoration: BoxDecoration(
          color: AppTheme.primaryLight.withAlpha(26),
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Icon(icon, color: AppTheme.primaryLight, size: 6.w),
      ),
      title: Text(
        title,
        style: GoogleFonts.inter(fontSize: 14.sp, fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.inter(
          fontSize: 12.sp,
          color: AppTheme.textSecondaryLight,
        ),
      ),
      trailing: Icon(Icons.chevron_right, size: 6.w),
      onTap: () {
        Navigator.pushNamed(context, route);
      },
    );
  }
}