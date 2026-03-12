import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
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

  // Mock data for metrics
  final List<Map<String, dynamic>> _metrics = [
    {
      'title': 'Active Votes',
      'value': '24',
      'subtitle': '+3 from yesterday',
      'iconName': 'how_to_vote',
      'color': Color(0xFF3B82F6),
    },
    {
      'title': 'User Engagement',
      'value': '89%',
      'subtitle': '+5% this week',
      'iconName': 'trending_up',
      'color': Color(0xFF10B981),
    },
    {
      'title': 'System Health',
      'value': '98%',
      'subtitle': 'All systems operational',
      'iconName': 'check_circle',
      'color': Color(0xFF10B981),
    },
    {
      'title': 'Total Users',
      'value': '1,247',
      'subtitle': '+42 new this week',
      'iconName': 'people',
      'color': Color(0xFF3B82F6),
    },
  ];

  // Mock data for recent votes requiring moderation
  final List<Map<String, dynamic>> _recentVotes = [
    {
      'id': 1,
      'title': 'Community Park Renovation Project',
      'creator': 'Sarah Johnson',
      'time': '2 hours ago',
      'votes': 156,
      'status': 'Pending',
    },
    {
      'id': 2,
      'title': 'New Library Hours Extension',
      'creator': 'Michael Chen',
      'time': '4 hours ago',
      'votes': 89,
      'status': 'Pending',
    },
    {
      'id': 3,
      'title': 'School Budget Allocation 2026',
      'creator': 'Emily Rodriguez',
      'time': '6 hours ago',
      'votes': 234,
      'status': 'Approved',
    },
  ];

  // Mock data for system status
  final List<Map<String, dynamic>> _systemStatus = [
    {
      'label': 'Server Health',
      'value': '99.8% Uptime',
      'isHealthy': true,
      'iconName': 'dns',
    },
    {
      'label': 'Database Sync',
      'value': 'Real-time',
      'isHealthy': true,
      'iconName': 'sync',
    },
    {
      'label': 'Notification Delivery',
      'value': '97.2% Success',
      'isHealthy': true,
      'iconName': 'notifications_active',
    },
  ];

  // Mock data for activity feed
  final List<Map<String, dynamic>> _activityFeed = [
    {
      'type': 'user',
      'title': 'New User Registration',
      'description': 'John Smith registered as a new voter',
      'time': '5 minutes ago',
    },
    {
      'type': 'vote',
      'title': 'Vote Submitted',
      'description': 'Community Park Renovation received 10 new votes',
      'time': '12 minutes ago',
    },
    {
      'type': 'alert',
      'title': 'System Alert',
      'description': 'High traffic detected on voting endpoint',
      'time': '25 minutes ago',
    },
    {
      'type': 'user',
      'title': 'User Verification',
      'description': 'Maria Garcia completed biometric verification',
      'time': '1 hour ago',
    },
    {
      'type': 'system',
      'title': 'Database Backup',
      'description': 'Automated backup completed successfully',
      'time': '2 hours ago',
    },
  ];

  // Mock data for quick actions
  List<Map<String, dynamic>> get _quickActions => [
    {
      'label': 'Churn Prediction',
      'iconName': 'warning_amber',
      'color': Color(0xFFEF4444),
      'route': '/creator-churn-prediction-dashboard',
    },
    {
      'label': 'Growth Analytics',
      'iconName': 'trending_up',
      'color': Color(0xFF10B981),
      'route': '/creator-growth-analytics-dashboard',
    },
    {
      'label': 'Performance Hub',
      'iconName': 'speed',
      'color': Color(0xFF3B82F6),
      'route': '/mobile-performance-optimization-hub',
    },
    {
      'label': 'Metrics Monitor',
      'iconName': 'monitor_heart',
      'color': Color(0xFF8B5CF6),
      'route': '/real-time-creator-metrics-monitor',
    },
    {
      'label': 'Launch Checklist',
      'iconName': 'rocket_launch',
      'color': Color(0xFFF59E0B),
      'route': '/mobile-launch-readiness-checklist',
    },
  ];

  // Add this method
  Future<void> _loadData() async {
    await _handleRefresh();
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
                    _showComingSoon(context, 'Users Management');
                  }),
                  _buildDrawerItem(context, 'Votes', 'how_to_vote', false, () {
                    Navigator.pop(context);
                    Navigator.of(
                      context,
                      rootNavigator: true,
                    ).pushNamed('/vote-dashboard');
                  }),
                  _buildDrawerItem(
                    context,
                    'Analytics',
                    'analytics',
                    false,
                    () {
                      Navigator.pop(context);
                      _showComingSoon(context, 'Analytics');
                    },
                  ),
                  _buildDrawerItem(context, 'Settings', 'settings', false, () {
                    Navigator.pop(context);
                    Navigator.of(
                      context,
                      rootNavigator: true,
                    ).pushNamed('/user-profile');
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
                      ).pushNamed('/vote-history');
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
                      ).pushNamed('/create-vote');
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
                      ).pushNamed('/offlineSyncDiagnostics');
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
                      ).pushNamed('/ai-quest-generation');
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
                      ).pushNamed('/ai-security-dashboard');
                    },
                  ),
                  ListTile(
                    leading: Icon(
                      Icons.analytics,
                      color: theme.colorScheme.primary,
                    ),
                    title: Text('AI Analytics Hub'),
                    onTap: () {
                      Navigator.pushNamed(context, '/ai-analytics-hub');
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
                        '/collaborative-voting-room',
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
                      Navigator.pushNamed(context, '/location-voting');
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.tune, color: theme.colorScheme.primary),
                    title: Text('Content Distribution'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(
                        context,
                        '/content-distribution-control-center',
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
                    title: Text('Dispute resolution'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, AppRoutes.claudeDisputeResolutionAdmin);
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
            onTap: () => _showComingSoon(context, 'Create Announcement'),
          ).build(context),
          QuickActionButtonWidget(
            label: 'Moderate',
            iconName: 'verified_user',
            color: const Color(0xFF10B981),
            onTap: () => _showComingSoon(context, 'Moderate Content'),
          ).build(context),
          QuickActionButtonWidget(
            label: 'Export Data',
            iconName: 'download',
            color: const Color(0xFF3B82F6),
            onTap: () => _showComingSoon(context, 'Export Data'),
          ).build(context),
          QuickActionButtonWidget(
            label: 'System Logs',
            iconName: 'article',
            color: const Color(0xFFEF4444),
            onTap: () =>
                Navigator.pushNamed(context, '/mobile-logging-dashboard'),
          ).build(context),
          QuickActionButtonWidget(
            label: 'Payout Settings',
            iconName: 'schedule',
            color: const Color(0xFF10B981),
            onTap: () => _showComingSoon(context, 'Payout Settings'),
          ).build(context),
          QuickActionButtonWidget(
            label: 'Fraud Monitor',
            iconName: 'security',
            color: const Color(0xFFEF4444),
            onTap: () => _showComingSoon(context, 'Fraud Monitor'),
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
                      Navigator.pushNamed(context, '/vote-casting'),
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
                    '/enhanced-vote-casting',
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
                      Navigator.pushNamed(context, '/create-vote'),
                ).build(context),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: QuickActionButtonWidget(
                  iconName: 'analytics',
                  label: 'Analytics',
                  color: theme.colorScheme.tertiary,
                  onTap: () =>
                      Navigator.pushNamed(context, '/vote-analytics'),
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
                ).pushNamed('/vote-dashboard'),
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
                ).pushNamed('/vote-results'),
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
    await Future.delayed(const Duration(seconds: 2));
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
                _showComingSoon(context, 'Create Announcement');
              },
            ),
            _buildQuickActionTile(
              context,
              'Moderate Content',
              'verified_user',
              () {
                Navigator.pop(context);
                _showComingSoon(context, 'Moderate Content');
              },
            ),
            _buildQuickActionTile(context, 'Export Data', 'download', () {
              Navigator.pop(context);
              _showComingSoon(context, 'Export Data');
            }),
            _buildQuickActionTile(context, 'System Settings', 'settings', () {
              Navigator.pop(context);
              Navigator.of(
                context,
                rootNavigator: true,
              ).pushNamed('/user-profile');
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

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature feature coming soon'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}