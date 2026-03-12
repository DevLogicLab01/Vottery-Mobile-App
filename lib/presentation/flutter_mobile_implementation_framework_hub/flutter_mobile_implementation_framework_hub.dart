import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../framework/feature_templates/d10_comments_control_template.dart';
import '../../framework/feature_templates/d11_constants_sync_template.dart';
import '../../framework/feature_templates/d1_campaign_management_template.dart';
import '../../framework/feature_templates/d2_participatory_ads_template.dart';
import '../../framework/feature_templates/d3_ad_slot_manager_template.dart';
import '../../framework/feature_templates/d4_platform_gamification_template.dart';
import '../../framework/feature_templates/d5_community_engagement_template.dart';
import '../../framework/feature_templates/d6_incident_response_template.dart';
import '../../framework/feature_templates/d7_realtime_notifications_template.dart';
import '../../framework/feature_templates/d8_subscription_tiers_template.dart';
import '../../framework/feature_templates/d9_payment_orchestration_template.dart';
import '../../framework/shared_constants.dart';
import './widgets/feature_template_card_widget.dart';
import './widgets/shared_constants_panel_widget.dart';
import './widgets/sync_validator_panel_widget.dart';

/// Flutter Mobile Implementation Framework Hub
/// Provides comprehensive Web/Mobile synchronization infrastructure through
/// SharedConstants, feature templates for all 11 system components, and
/// WebMobileSyncValidator ensuring 100% cross-platform consistency.
class FlutterMobileImplementationFrameworkHub extends StatefulWidget {
  const FlutterMobileImplementationFrameworkHub({super.key});

  @override
  State<FlutterMobileImplementationFrameworkHub> createState() =>
      _FlutterMobileImplementationFrameworkHubState();
}

class _FlutterMobileImplementationFrameworkHubState
    extends State<FlutterMobileImplementationFrameworkHub>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<_FeatureTemplateData> _featureTemplates = [
    _FeatureTemplateData(
      id: 'D1',
      name: 'Campaign Management Dashboard',
      description:
          'Live campaign status, engagement metrics, zone breakdown with 30s auto-refresh',
      tableName: SharedConstants.sponsoredElections,
      routePath: SharedConstants.campaignManagementDashboard,
      guide: CampaignManagementTemplate.getImplementationGuide(),
      color: Colors.blue,
      icon: Icons.campaign,
    ),
    _FeatureTemplateData(
      id: 'D2',
      name: 'Participatory Ads Studio',
      description:
          '5-step wizard: basic info → ad format → targeting → budget → review',
      tableName: SharedConstants.sponsoredElections,
      routePath: SharedConstants.participatoryAdsStudio,
      guide: ParticipatoryAdsTemplate.getImplementationGuide(),
      color: Colors.purple,
      icon: Icons.auto_awesome,
    ),
    _FeatureTemplateData(
      id: 'D3',
      name: 'Ad Slot Manager',
      description:
          'Internal ads priority with AdSense fallback for unfilled slots',
      tableName: SharedConstants.sponsoredElections,
      routePath: '/ad-slot-manager',
      guide: AdSlotManagerTemplate.getImplementationGuide(),
      color: Colors.orange,
      icon: Icons.ad_units,
    ),
    _FeatureTemplateData(
      id: 'D4',
      name: 'Platform Gamification',
      description:
          'Monthly platform-wide gamification with prize pools and RNG winner selection',
      tableName: SharedConstants.platformGamificationCampaigns,
      routePath: '/platform-gamification',
      guide: PlatformGamificationTemplate.getImplementationGuide(),
      color: Colors.amber,
      icon: Icons.emoji_events,
    ),
    _FeatureTemplateData(
      id: 'D5',
      name: 'Community Engagement Dashboard',
      description:
          'Leaderboards by feedback, voting participation, and feature adoption',
      tableName: SharedConstants.featureRequests,
      routePath: SharedConstants.communityEngagementDashboard,
      guide: CommunityEngagementTemplate.getImplementationGuide(),
      color: Colors.teal,
      icon: Icons.people,
    ),
    _FeatureTemplateData(
      id: 'D6',
      name: 'Incident Response Analytics',
      description:
          'Correlates monitoring alerts with feature deployments for root-cause analysis',
      tableName: SharedConstants.systemAlerts,
      routePath: SharedConstants.incidentResponseAnalytics,
      guide: IncidentResponseTemplate.getImplementationGuide(),
      color: Colors.red,
      icon: Icons.warning_amber,
    ),
    _FeatureTemplateData(
      id: 'D7',
      name: 'Real-time Gamification Notifications',
      description:
          'Supabase Realtime subscriptions for VP, achievements, streaks, leaderboard',
      tableName: SharedConstants.userVpTransactions,
      routePath: '/realtime-gamification-notifications',
      guide: RealtimeNotificationsTemplate.getImplementationGuide(),
      color: Colors.green,
      icon: Icons.notifications_active,
    ),
    _FeatureTemplateData(
      id: 'D8',
      name: 'Subscription Tiers with VP Multipliers',
      description:
          'Basic 2x, Pro 3x, Elite 5x VP multipliers with Stripe billing integration',
      tableName: SharedConstants.userSubscriptions,
      routePath: SharedConstants.subscriptionArchitecture,
      guide: SubscriptionTiersTemplate.getImplementationGuide(),
      color: Colors.indigo,
      icon: Icons.workspace_premium,
    ),
    _FeatureTemplateData(
      id: 'D9',
      name: 'Unified Payment Orchestration Hub',
      description:
          'Centralized management for subscriptions, participation fees, and creator payouts',
      tableName: SharedConstants.payoutSettings,
      routePath: SharedConstants.unifiedPaymentOrchestration,
      guide: PaymentOrchestrationTemplate.getImplementationGuide(),
      color: Colors.cyan,
      icon: Icons.account_balance_wallet,
    ),
    _FeatureTemplateData(
      id: 'D10',
      name: 'Comments On/Off Creator Control',
      description:
          'Per-election comment toggle synced via elections.allow_comments column',
      tableName: SharedConstants.electionsTable,
      routePath: '/election-creation',
      guide: CommentsControlTemplate.getImplementationGuide(),
      color: Colors.brown,
      icon: Icons.comment,
    ),
    _FeatureTemplateData(
      id: 'D11',
      name: 'Constants Sync Validation',
      description:
          '50+ shared constants validated between Web and Mobile at build time',
      tableName: 'N/A',
      routePath: SharedConstants.flutterMobileFrameworkHub,
      guide: ConstantsSyncTemplate.getImplementationGuide(),
      color: Colors.deepPurple,
      icon: Icons.sync,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Mobile Framework Hub',
          style: GoogleFonts.inter(
            fontSize: 16.sp,
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelStyle: GoogleFonts.inter(
            fontSize: 11.sp,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: GoogleFonts.inter(fontSize: 11.sp),
          tabs: const [
            Tab(icon: Icon(Icons.grid_view, size: 18), text: 'Features'),
            Tab(icon: Icon(Icons.code, size: 18), text: 'Constants'),
            Tab(icon: Icon(Icons.sync, size: 18), text: 'Sync Validator'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFeaturesTab(context),
          _buildConstantsTab(context),
          _buildSyncValidatorTab(context),
        ],
      ),
    );
  }

  Widget _buildFeaturesTab(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: EdgeInsets.all(3.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header stats
          _buildStatsRow(context),
          SizedBox(height: 2.h),
          // Section title
          Text(
            '11 Feature Templates',
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
            ),
          ),
          Text(
            'Tap any template to view implementation guide',
            style: GoogleFonts.inter(
              fontSize: 11.sp,
              color: theme.colorScheme.onSurface.withAlpha(128),
            ),
          ),
          SizedBox(height: 1.5.h),
          // Feature template cards
          ..._featureTemplates.map(
            (f) => FeatureTemplateCardWidget(
              featureId: f.id,
              featureName: f.name,
              description: f.description,
              tableName: f.tableName,
              routePath: f.routePath,
              implementationGuide: f.guide,
              accentColor: f.color,
              icon: f.icon,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(BuildContext context) {
    final theme = Theme.of(context);
    final stats = [
      {
        'label': 'Features',
        'value': '11',
        'icon': Icons.grid_view,
        'color': Colors.blue,
      },
      {
        'label': 'Constants',
        'value': '50+',
        'icon': Icons.code,
        'color': Colors.purple,
      },
      {
        'label': 'Tables',
        'value': '8',
        'icon': Icons.table_chart,
        'color': Colors.green,
      },
      {
        'label': 'Sync',
        'value': '100%',
        'icon': Icons.sync,
        'color': Colors.orange,
      },
    ];
    return Row(
      children: stats.map((s) {
        final color = s['color'] as Color;
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: s != stats.last ? 2.w : 0),
            padding: EdgeInsets.symmetric(vertical: 1.5.h, horizontal: 2.w),
            decoration: BoxDecoration(
              color: color.withAlpha(26),
              borderRadius: BorderRadius.circular(10.0),
              border: Border.all(color: color.withAlpha(77)),
            ),
            child: Column(
              children: [
                Icon(s['icon'] as IconData, color: color, size: 20),
                SizedBox(height: 0.5.h),
                Text(
                  s['value'] as String,
                  style: GoogleFonts.inter(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
                Text(
                  s['label'] as String,
                  style: GoogleFonts.inter(
                    fontSize: 9.sp,
                    color: theme.colorScheme.onSurface.withAlpha(153),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildConstantsTab(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(3.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Shared Constants Reference',
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          Text(
            'All constants shared between Web and Mobile. Tap to copy.',
            style: GoogleFonts.inter(
              fontSize: 11.sp,
              color: Theme.of(context).colorScheme.onSurface.withAlpha(128),
            ),
          ),
          SizedBox(height: 2.h),
          const SharedConstantsPanelWidget(),
        ],
      ),
    );
  }

  Widget _buildSyncValidatorTab(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(3.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // CI/CD integration info
          _buildCiCdInfoCard(context),
          SizedBox(height: 2.h),
          const SyncValidatorPanelWidget(),
        ],
      ),
    );
  }

  Widget _buildCiCdInfoCard(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.deepPurple.withAlpha(26),
            Colors.indigo.withAlpha(26),
          ],
        ),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.deepPurple.withAlpha(77)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.integration_instructions,
                color: Colors.deepPurple,
                size: 20,
              ),
              SizedBox(width: 2.w),
              Text(
                'CI/CD Integration',
                style: GoogleFonts.inter(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w700,
                  color: Colors.deepPurple,
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          _CiCdItem(
            icon: Icons.terminal,
            label: 'Pre-commit hook',
            value: 'scripts/validate_web_mobile_sync.sh',
          ),
          _CiCdItem(
            icon: Icons.settings,
            label: 'CI/CD workflow',
            value: '.github/workflows/flutter-ci-enhanced.yml',
          ),
          _CiCdItem(
            icon: Icons.block,
            label: 'Blocks commits with',
            value: 'Divergent constants between Web/Mobile',
          ),
          _CiCdItem(
            icon: Icons.auto_fix_high,
            label: 'Auto-generate feature',
            value: 'scripts/generate_mobile_feature.sh <name>',
          ),
        ],
      ),
    );
  }
}

class _CiCdItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _CiCdItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: Colors.deepPurple.withAlpha(179)),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface.withAlpha(179),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 10,
                color: Colors.deepPurple,
                fontFamily: 'monospace',
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureTemplateData {
  final String id;
  final String name;
  final String description;
  final String tableName;
  final String routePath;
  final String guide;
  final Color color;
  final IconData icon;

  const _FeatureTemplateData({
    required this.id,
    required this.name,
    required this.description,
    required this.tableName,
    required this.routePath,
    required this.guide,
    required this.color,
    required this.icon,
  });
}
