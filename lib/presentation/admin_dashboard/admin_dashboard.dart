import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../routes/app_routes.dart';
import '../../services/supabase_service.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/error_boundary_wrapper.dart';
import '../../widgets/shimmer_skeleton_loader.dart';
import './widgets/activity_feed_item_widget.dart';
import './widgets/metric_card_widget.dart';
import './widgets/quick_action_button_widget.dart';
import './widgets/recent_vote_card_widget.dart';
import './widgets/system_status_widget.dart';

/// Admin Dashboard screen providing system oversight and management tools
/// Implements Contemporary Civic Minimalism with mobile-optimized administration
class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isRefreshing = false;
  final _client = SupabaseService.instance.client;

  /// Populated from Supabase on load (no seeded mock rows).
  List<Map<String, dynamic>> _metrics = [];

  List<Map<String, dynamic>> _recentVotes = [];

  List<Map<String, dynamic>> _systemStatus = [];

  List<Map<String, dynamic>> _activityFeed = [];

  /// Quick actions navigate to production screens (parity with web admin flows).
  List<Map<String, dynamic>> get _quickActions => [
    {
      'label': 'Churn Prediction',
      'iconName': 'warning_amber',
      'color': Color(0xFFEF4444),
      'route': AppRoutes.creatorChurnPredictionDashboard,
    },
    {
      'label': 'Growth Analytics',
      'iconName': 'trending_up',
      'color': Color(0xFF10B981),
      'route': AppRoutes.creatorGrowthAnalyticsDashboard,
    },
    {
      'label': 'Performance Hub',
      'iconName': 'speed',
      'color': Color(0xFF3B82F6),
      'route': AppRoutes.mobilePerformanceOptimizationHub,
    },
    {
      'label': 'Metrics Monitor',
      'iconName': 'monitor_heart',
      'color': Color(0xFF8B5CF6),
      'route': AppRoutes.realTimeCreatorMetricsMonitor,
    },
    {
      'label': 'Launch Checklist',
      'iconName': 'rocket_launch',
      'color': Color(0xFFF59E0B),
      'route': AppRoutes.mobileLaunchReadinessChecklist,
    },
  ];

  // Add this method
  Future<void> _loadData() async {
    await _loadDashboardData();
  }

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    try {
      final elections = await _client
          .from('elections')
          .select('id, title, created_at, created_by, vote_count, status')
          .order('created_at', ascending: false)
          .limit(8);
      final users = await _client
          .from('user_profiles')
          .select('id, created_at, role, status');
      final flags = await _client
          .from('content_flags')
          .select('id, status, created_at')
          .order('created_at', ascending: false)
          .limit(10);

      final activeVotes = elections
          .where((e) => (e['status']?.toString() ?? '') == 'active')
          .length;
      final activeUsers = users
          .where((u) => (u['status']?.toString() ?? 'active') == 'active')
          .length;
      final pendingVotes = elections
          .where((e) => (e['status']?.toString() ?? '') == 'pending')
          .toList();
      final recentActivities = <Map<String, dynamic>>[];

      for (final election in elections.take(5)) {
        recentActivities.add({
          'type': 'vote',
          'title': 'Election update',
          'description': '${election['title'] ?? 'Election'} received activity',
          'time': _relativeTime(election['created_at']?.toString()),
        });
      }

      for (final flag in flags.take(3)) {
        recentActivities.add({
          'type': 'alert',
          'title': 'Moderation alert',
          'description':
              'Content flag status: ${flag['status']?.toString() ?? 'pending_review'}',
          'time': _relativeTime(flag['created_at']?.toString()),
        });
      }

      if (!mounted) return;
      setState(() {
        _metrics = [
          {
            'title': 'Active Votes',
            'value': '$activeVotes',
            'subtitle': '${pendingVotes.length} pending approvals',
            'iconName': 'how_to_vote',
            'color': const Color(0xFF3B82F6),
          },
          {
            'title': 'User Engagement',
            'value': users.isEmpty
                ? '0%'
                : '${((activeUsers / users.length) * 100).toStringAsFixed(0)}%',
            'subtitle': '$activeUsers active users',
            'iconName': 'trending_up',
            'color': const Color(0xFF10B981),
          },
          {
            'title': 'System Health',
            'value': 'Live',
            'subtitle': 'Supabase-connected',
            'iconName': 'check_circle',
            'color': const Color(0xFF10B981),
          },
          {
            'title': 'Total Users',
            'value': '${users.length}',
            'subtitle': 'Production records',
            'iconName': 'people',
            'color': const Color(0xFF3B82F6),
          },
        ];

        _recentVotes = pendingVotes
            .map(
              (vote) => {
                'id': vote['id'],
                'title': vote['title'] ?? 'Untitled Election',
                'creator': vote['created_by']?.toString() ?? 'Unknown',
                'time': _relativeTime(vote['created_at']?.toString()),
                'votes': vote['vote_count'] ?? 0,
                'status': (vote['status']?.toString() ?? 'Pending')
                    .replaceFirstMapped(RegExp(r'^[a-z]'),
                        (match) => match.group(0)!.toUpperCase()),
              },
            )
            .toList();

        _activityFeed = recentActivities;

        _systemStatus = [
          {
            'label': 'Database',
            'value': 'Connected',
            'isHealthy': true,
            'iconName': 'cloud_done',
          },
          {
            'label': 'Elections loaded',
            'value': '${elections.length} records',
            'isHealthy': true,
            'iconName': 'how_to_vote',
          },
          {
            'label': 'Moderation flags',
            'value': '${flags.length} recent',
            'isHealthy': true,
            'iconName': 'flag',
          },
        ];
      });
    } catch (e, st) {
      debugPrint('Admin dashboard load failed: $e\n$st');
      if (!mounted) return;
      setState(() {
        _metrics = [];
        _recentVotes = [];
        _activityFeed = [];
        _systemStatus = [
          {
            'label': 'Data source',
            'value': 'Unavailable',
            'isHealthy': false,
            'iconName': 'error_outline',
          },
        ];
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not load admin data: ${e.toString()}'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  String _relativeTime(String? iso) {
    if (iso == null) return 'just now';
    final timestamp = DateTime.tryParse(iso);
    if (timestamp == null) return 'just now';
    final diff = DateTime.now().difference(timestamp);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inHours < 1) return '${diff.inMinutes} minutes ago';
    if (diff.inDays < 1) return '${diff.inHours} hours ago';
    return '${diff.inDays} days ago';
  }

  @override
  Widget build(BuildContext context) {
    return ErrorBoundaryWrapper(
      screenName: 'AdminDashboard',
      onRetry: _loadData,
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: Colors.white,
        appBar: CustomAppBar(title: 'Admin Dashboard'),
        body: _isRefreshing
            ? const SkeletonDashboard()
            : RefreshIndicator(
                onRefresh: _handleRefresh,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildMetricsSection(context),
                      SizedBox(height: 3.h),
                      _buildQuickActionsSection(context),
                      SizedBox(height: 3.h),
                      _buildRecentVotesSection(context),
                      SizedBox(height: 3.h),
                      _buildActivityFeedSection(context),
                      SizedBox(height: 3.h),
                      _buildSystemStatusSection(context),
                      SizedBox(height: 3.h),
                    ],
                  ),
                ),
              ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showQuickActionsModal(context),
          icon: CustomIconWidget(
            iconName: 'add',
            color: Theme.of(context).floatingActionButtonTheme.foregroundColor!,
            size: 24,
          ),
          label: Text(
            'Quick Actions',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(
                context,
              ).floatingActionButtonTheme.foregroundColor,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationDrawer(BuildContext context) {
    final theme = Theme.of(context);

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(color: theme.colorScheme.primary),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: CustomIconWidget(
                        iconName: 'admin_panel_settings',
                        color: theme.colorScheme.primary,
                        size: 28,
                      ),
                    ),
                  ),
                  SizedBox(width: 3.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Admin Panel',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.onPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'System Management',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onPrimary.withValues(
                              alpha: 0.8,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _buildDrawerItem(
                    context,
                    'Dashboard',
                    'dashboard',
                    true,
                    () => Navigator.pop(context),
                  ),
                  _buildDrawerItem(context, 'Users', 'people', false, () {
                    Navigator.pop(context);
                    Navigator.of(context, rootNavigator: true)
                        .pushNamed(AppRoutes.bulkManagementScreen);
                  }),
                  _buildDrawerItem(context, 'Votes', 'how_to_vote', false, () {
                    Navigator.pop(context);
                    Navigator.of(
                      context,
                      rootNavigator: true,
                    ).pushNamed(AppRoutes.voteDashboard);
                  }),
                  _buildDrawerItem(
                    context,
                    'Analytics',
                    'analytics',
                    false,
                    () {
                      Navigator.pop(context);
                      Navigator.of(context, rootNavigator: true)
                          .pushNamed(AppRoutes.analyticsExportReportingHub);
                    },
                  ),
                  _buildDrawerItem(context, 'Settings', 'settings', false, () {
                    Navigator.pop(context);
                    Navigator.of(
                      context,
                      rootNavigator: true,
                    ).pushNamed(AppRoutes.userProfile);
                  }),
                  Divider(
                    height: 1,
                    color: theme.colorScheme.outline.withValues(alpha: 0.2),
                  ),
                  _buildDrawerItem(
                    context,
                    'Vote History',
                    'history',
                    false,
                    () {
                      Navigator.pop(context);
                      Navigator.of(
                        context,
                        rootNavigator: true,
                      ).pushNamed(AppRoutes.voteHistory);
                    },
                  ),
                  _buildDrawerItem(
                    context,
                    'Create Vote',
                    'add_circle',
                    false,
                    () {
                      Navigator.pop(context);
                      Navigator.of(
                        context,
                        rootNavigator: true,
                      ).pushNamed(AppRoutes.createVote);
                    },
                  ),
                  _buildDrawerItem(
                    context,
                    'Offline Sync Diagnostics',
                    'cloud_sync',
                    false,
                    () {
                      Navigator.pop(context);
                      Navigator.of(
                        context,
                        rootNavigator: true,
                      ).pushNamed(AppRoutes.offlineSyncDiagnostics);
                    },
                  ),
                  _buildDrawerItem(
                    context,
                    'Community Elections Hub',
                    'groups',
                    false,
                    () {
                      Navigator.pop(context);
                      Navigator.of(
                        context,
                        rootNavigator: true,
                      ).pushNamed(AppRoutes.communityElectionsHub);
                    },
                  ),
                  _buildDrawerItem(
                    context,
                    'AI Quest Generation',
                    'psychology',
                    false,
                    () {
                      Navigator.pop(context);
                      Navigator.of(
                        context,
                        rootNavigator: true,
                      ).pushNamed(AppRoutes.aiQuestGeneration);
                    },
                  ),
                  _buildDrawerItem(
                    context,
                    'AI Security Dashboard',
                    'security',
                    false,
                    () {
                      Navigator.pop(context);
                      Navigator.of(
                        context,
                        rootNavigator: true,
                      ).pushNamed(AppRoutes.aiSecurityDashboard);
                    },
                  ),
                  ListTile(
                    leading: Icon(
                      Icons.analytics,
                      color: theme.colorScheme.primary,
                    ),
                    title: Text('AI Analytics Hub'),
                    onTap: () {
                      Navigator.pushNamed(context, AppRoutes.aiAnalyticsHub);
                    },
                  ),
                  ListTile(
                    leading: Icon(
                      Icons.groups,
                      color: theme.colorScheme.primary,
                    ),
                    title: Text('Collaborative Voting'),
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        AppRoutes.collaborativeVotingRoom,
                      );
                    },
                  ),
                  ListTile(
                    leading: Icon(
                      Icons.location_on,
                      color: theme.colorScheme.primary,
                    ),
                    title: Text('Location Voting'),
                    onTap: () {
                      Navigator.pushNamed(context, AppRoutes.locationVoting);
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.tune, color: theme.colorScheme.primary),
                    title: Text('Content Distribution'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(
                        context,
                        AppRoutes.contentDistributionControlCenter,
                      );
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.public_off, color: theme.colorScheme.primary),
                    title: Text('Country restrictions'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, AppRoutes.countryRestrictionsAdmin);
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.integration_instructions, color: theme.colorScheme.primary),
                    title: Text('Platform integrations'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, AppRoutes.platformIntegrationsAdmin);
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.pie_chart_outline, color: theme.colorScheme.primary),
                    title: Text('Country revenue share'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, AppRoutes.countryRevenueShareAdmin);
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.analytics_outlined, color: theme.colorScheme.primary),
                    title: Text('Regional revenue analytics'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, AppRoutes.regionalRevenueAnalyticsAdmin);
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.gavel, color: theme.colorScheme.primary),
                    title: Text('International payment disputes'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, AppRoutes.claudeDisputeResolutionAdmin);
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.psychology_outlined, color: theme.colorScheme.primary),
                    title: Text('Claude dispute moderation (Web)'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, AppRoutes.claudeAiDisputeModerationAdmin);
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.currency_exchange, color: theme.colorScheme.primary),
                    title: Text('Multi-currency settlement'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, AppRoutes.multiCurrencySettlementAdmin);
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.subscriptions_outlined, color: theme.colorScheme.primary),
                    title: Text('Admin subscription analytics (Web)'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, AppRoutes.adminSubscriptionAnalyticsAdmin);
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.payment, color: theme.colorScheme.primary),
                    title: Text('Stripe subscriptions (Web)'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, AppRoutes.stripeSubscriptionManagementAdmin);
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.credit_card, color: theme.colorScheme.primary),
                    title: Text('Stripe payment hub (Web)'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, AppRoutes.stripePaymentIntegrationHubAdmin);
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.calculate_outlined, color: theme.colorScheme.primary),
                    title: Text('Automated payout calculation (Web)'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, AppRoutes.automatedPayoutCalculationEngineAdmin);
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.language, color: theme.colorScheme.primary),
                    title: Text('Country-based payout processing (Web)'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, AppRoutes.countryBasedPayoutProcessingEngineAdmin);
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.videogame_asset, color: theme.colorScheme.primary),
                    title: Text('Gamification admin (Web)'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, AppRoutes.comprehensiveGamificationAdminWeb);
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.settings_suggest, color: theme.colorScheme.primary),
                    title: Text('Platform gamification engine (Web)'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, AppRoutes.platformGamificationCoreEngineAdmin);
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.campaign, color: theme.colorScheme.primary),
                    title: Text('Gamification campaigns (Web)'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, AppRoutes.gamificationCampaignManagementAdmin);
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.emoji_events_outlined, color: theme.colorScheme.primary),
                    title: Text('Gamification rewards (Web)'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, AppRoutes.gamificationRewardsManagementAdmin);
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.verified_user, color: theme.colorScheme.primary),
                    title: Text('Security compliance automation (Web)'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, AppRoutes.securityComplianceAutomationAdmin);
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.public, color: theme.colorScheme.primary),
                    title: Text('Localization & tax reporting (Web)'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, AppRoutes.localizationTaxReportingAdmin);
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.policy, color: theme.colorScheme.primary),
                    title: Text('Compliance dashboard (Web)'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, AppRoutes.complianceDashboardWeb);
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.fact_check, color: theme.colorScheme.primary),
                    title: Text('Compliance audit (Web)'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, AppRoutes.complianceAuditDashboardWeb);
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.gavel_outlined, color: theme.colorScheme.primary),
                    title: Text('Regulatory automation (Web)'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, AppRoutes.regulatoryComplianceAutomationWeb);
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.article_outlined, color: theme.colorScheme.primary),
                    title: Text('Public bulletin board (Web)'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, AppRoutes.publicBulletinBoardWeb);
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.how_to_vote_outlined, color: theme.colorScheme.primary),
                    title: Text('Vote verification portal (Web)'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, AppRoutes.voteVerificationPortalWeb);
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.auto_awesome, color: theme.colorScheme.primary),
                    title: Text('Admin quest configuration (Web)'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, AppRoutes.adminQuestConfigurationControlCenterWeb);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context,
    String title,
    String iconName,
    bool isSelected,
    VoidCallback onTap,
  ) {
    final theme = Theme.of(context);

    return ListTile(
      leading: CustomIconWidget(
        iconName: iconName,
        color: isSelected
            ? theme.colorScheme.primary
            : theme.colorScheme.onSurfaceVariant,
        size: 24,
      ),
      title: Text(
        title,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: isSelected
              ? theme.colorScheme.primary
              : theme.colorScheme.onSurface,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
      selected: isSelected,
      selectedTileColor: theme.colorScheme.primary.withValues(alpha: 0.1),
      onTap: onTap,
    );
  }

  Widget _buildMetricsSection(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
          child: Text(
            'Key Metrics',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        SizedBox(
          height: 20.h,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            itemCount: _metrics.length,
            itemBuilder: (context, index) {
              final metric = _metrics[index];
              return Padding(
                padding: EdgeInsets.only(right: 3.w),
                child: MetricCardWidget(
                  title: metric['title'] as String,
                  value: metric['value'] as String,
                  subtitle: metric['subtitle'] as String,
                  iconName: metric['iconName'] as String,
                  iconColor: metric['color'] as Color,
                  onTap: () => _showMetricDetails(context, metric),
                ).build(context),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionsSection(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: Wrap(
        spacing: 2.w,
        runSpacing: 1.h,
        children: [
          QuickActionButtonWidget(
            label: 'Announcement',
            iconName: 'campaign',
            color: theme.colorScheme.primary,
            onTap: () => Navigator.of(context, rootNavigator: true)
                .pushNamed(AppRoutes.notificationCenterHub),
          ).build(context),
          QuickActionButtonWidget(
            label: 'Moderate',
            iconName: 'verified_user',
            color: const Color(0xFF10B981),
            onTap: () => Navigator.of(context, rootNavigator: true)
                .pushNamed(AppRoutes.contentModerationControlCenter),
          ).build(context),
          QuickActionButtonWidget(
            label: 'Export Data',
            iconName: 'download',
            color: const Color(0xFF3B82F6),
            onTap: () => Navigator.of(context, rootNavigator: true)
                .pushNamed(AppRoutes.analyticsExportReportingHub),
          ).build(context),
          QuickActionButtonWidget(
            label: 'System Logs',
            iconName: 'article',
            color: const Color(0xFFEF4444),
            onTap: () =>
                Navigator.pushNamed(context, AppRoutes.mobileLoggingDashboard),
          ).build(context),
          QuickActionButtonWidget(
            label: 'Payout Settings',
            iconName: 'schedule',
            color: const Color(0xFF10B981),
            onTap: () => Navigator.of(context, rootNavigator: true)
                .pushNamed(AppRoutes.payoutScheduleSettingsScreen),
          ).build(context),
          QuickActionButtonWidget(
            label: 'Fraud Monitor',
            iconName: 'security',
            color: const Color(0xFFEF4444),
            onTap: () => Navigator.of(context, rootNavigator: true)
                .pushNamed(AppRoutes.fraudMonitoringDashboard),
          ).build(context),
        ],
      ),
    );
  }

  Widget _buildQuickActions(ThemeData theme) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              Expanded(
                child: QuickActionButtonWidget(
                  iconName: 'how_to_vote',
                  label: 'Cast Vote',
                  color: theme.colorScheme.primary,
                  onTap: () =>
                      Navigator.pushNamed(context, AppRoutes.voteCasting),
                ).build(context),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: QuickActionButtonWidget(
                  iconName: 'ballot',
                  label: 'Enhanced Vote',
                  color: theme.colorScheme.tertiary,
                  onTap: () => Navigator.pushNamed(
                    context,
                    AppRoutes.enhancedVoteCasting,
                  ),
                ).build(context),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              Expanded(
                child: QuickActionButtonWidget(
                  iconName: 'add_circle',
                  label: 'Create Vote',
                  color: theme.colorScheme.secondary,
                  onTap: () =>
                      Navigator.pushNamed(context, AppRoutes.createVote),
                ).build(context),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: QuickActionButtonWidget(
                  iconName: 'analytics',
                  label: 'Analytics',
                  color: theme.colorScheme.tertiary,
                  onTap: () =>
                      Navigator.pushNamed(context, AppRoutes.voteAnalytics),
                ).build(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecentVotesSection(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Votes',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(
                  context,
                  rootNavigator: true,
                ).pushNamed(AppRoutes.voteDashboard),
                child: Text('View All'),
              ),
            ],
          ),
        ),
        SizedBox(height: 1.h),
        SizedBox(
          height: 22.h,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            itemCount: _recentVotes.length,
            itemBuilder: (context, index) {
              final vote = _recentVotes[index];
              return RecentVoteCardWidget(
                voteData: vote,
                onApprove: () => _handleVoteAction(context, vote, 'approve'),
                onReject: () => _handleVoteAction(context, vote, 'reject'),
                onTap: () => Navigator.of(
                  context,
                  rootNavigator: true,
                ).pushNamed(AppRoutes.voteResults),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildActivityFeedSection(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w),
          child: Text(
            'Recent Activity',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        SizedBox(height: 1.h),
        Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            border: Border(
              top: BorderSide(
                color: theme.colorScheme.outline.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
          ),
          child: ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _activityFeed.length,
            itemBuilder: (context, index) {
              return ActivityFeedItemWidget(
                activity: _activityFeed[index],
              ).build(context);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSystemStatusSection(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w),
          child: Text(
            'System Status',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        SizedBox(height: 1.h),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w),
          child: Column(
            children: _systemStatus.map((status) {
              return Padding(
                padding: EdgeInsets.only(bottom: 2.h),
                child: SystemStatusWidget(
                  label: status['label'] as String,
                  value: status['value'] as String,
                  isHealthy: status['isHealthy'] as bool,
                  iconName: status['iconName'] as String,
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Future<void> _handleRefresh() async {
    setState(() => _isRefreshing = true);
    await _loadDashboardData();
    setState(() => _isRefreshing = false);
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Dashboard refreshed')));
    }
  }

  void _showMetricDetails(BuildContext context, Map<String, dynamic> metric) {
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: 50.h,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          children: [
            Container(
              margin: EdgeInsets.only(top: 1.h),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurfaceVariant.withValues(
                  alpha: 0.3,
                ),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(4.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(3.w),
                        decoration: BoxDecoration(
                          color: (metric['color'] as Color).withValues(
                            alpha: 0.1,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: CustomIconWidget(
                          iconName: metric['iconName'] as String,
                          color: metric['color'] as Color,
                          size: 32,
                        ),
                      ),
                      SizedBox(width: 3.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              metric['title'] as String,
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              metric['subtitle'] as String,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 3.h),
                  Text(
                    'Current Value',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    metric['value'] as String,
                    style: theme.textTheme.displayMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: metric['color'] as Color,
                    ),
                  ),
                  SizedBox(height: 3.h),
                  Text(
                    'Detailed breakdown and historical trends would be displayed here with interactive charts and analytics.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleVoteAction(
    BuildContext context,
    Map<String, dynamic> vote,
    String action,
  ) {
    final theme = Theme.of(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${vote['title']} has been ${action}d',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onPrimary,
          ),
        ),
        backgroundColor: action == 'approve'
            ? const Color(0xFF10B981)
            : const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showQuickActionsModal(BuildContext context) {
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                margin: EdgeInsets.only(bottom: 2.h),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurfaceVariant.withValues(
                    alpha: 0.3,
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              'Quick Actions',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 2.h),
            _buildQuickActionTile(
              context,
              'Create Announcement',
              'campaign',
              () {
                Navigator.pop(context);
                Navigator.of(context, rootNavigator: true)
                    .pushNamed(AppRoutes.notificationCenterHub);
              },
            ),
            _buildQuickActionTile(
              context,
              'Moderate Content',
              'verified_user',
              () {
                Navigator.pop(context);
                Navigator.of(context, rootNavigator: true)
                    .pushNamed(AppRoutes.contentModerationControlCenter);
              },
            ),
            _buildQuickActionTile(context, 'Export Data', 'download', () {
              Navigator.pop(context);
              Navigator.of(context, rootNavigator: true)
                  .pushNamed(AppRoutes.analyticsExportReportingHub);
            }),
            _buildQuickActionTile(context, 'System Settings', 'settings', () {
              Navigator.pop(context);
              Navigator.of(
                context,
                rootNavigator: true,
              ).pushNamed(AppRoutes.userProfile);
            }),
            SizedBox(height: 2.h),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionTile(
    BuildContext context,
    String title,
    String iconName,
    VoidCallback onTap,
  ) {
    final theme = Theme.of(context);

    return ListTile(
      leading: Container(
        padding: EdgeInsets.all(2.w),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: CustomIconWidget(
          iconName: iconName,
          color: theme.colorScheme.primary,
          size: 24,
        ),
      ),
      title: Text(
        title,
        style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
      ),
      trailing: CustomIconWidget(
        iconName: 'arrow_forward_ios',
        color: theme.colorScheme.onSurfaceVariant,
        size: 16,
      ),
      onTap: onTap,
    );
  }

  void _showNotifications(BuildContext context) {
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: 60.h,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          children: [
            Container(
              margin: EdgeInsets.only(top: 1.h),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurfaceVariant.withValues(
                  alpha: 0.3,
                ),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(4.w),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Notifications',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Clear All'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: 5,
                itemBuilder: (context, index) {
                  return ListTile(
                    leading: Container(
                      padding: EdgeInsets.all(2.w),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: CustomIconWidget(
                        iconName: 'notifications',
                        color: theme.colorScheme.primary,
                        size: 24,
                      ),
                    ),
                    title: Text(
                      'System notification ${index + 1}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      'Notification details would appear here',
                      style: theme.textTheme.bodySmall,
                    ),
                    trailing: Text(
                      '${index + 1}h ago',
                      style: theme.textTheme.labelSmall,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

}