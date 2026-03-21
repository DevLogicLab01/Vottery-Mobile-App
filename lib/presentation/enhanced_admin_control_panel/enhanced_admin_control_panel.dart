import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/admin_management_service.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_icon_widget.dart';
import '../../widgets/error_boundary_wrapper.dart';
import '../../widgets/shimmer_skeleton_loader.dart';
import '../real_time_system_monitoring_dashboard/widgets/emergency_controls_widget.dart';

class EnhancedAdminControlPanel extends StatefulWidget {
  const EnhancedAdminControlPanel({super.key});

  @override
  State<EnhancedAdminControlPanel> createState() =>
      _EnhancedAdminControlPanelState();
}

class _EnhancedAdminControlPanelState extends State<EnhancedAdminControlPanel> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final AdminManagementService _adminService = AdminManagementService.instance;

  int _selectedDrawerIndex = 0;
  bool _isLoading = false;
  Map<String, dynamic> _systemStats = {};

  Future<List<Map<String, dynamic>>>? _usersPanelFuture;
  Future<List<Map<String, dynamic>>>? _auditPanelFuture;
  Future<Map<String, dynamic>>? _compliancePanelFuture;

  final List<Map<String, dynamic>> _drawerSections = [
    {'title': 'Dashboard Overview', 'icon': 'dashboard', 'index': 0},
    {'title': 'User Management', 'icon': 'people', 'index': 1},
    {'title': 'Financial Management', 'icon': 'account_balance', 'index': 2},
    {'title': 'Analytics & Reports', 'icon': 'analytics', 'index': 3},
    {'title': 'Compliance Dashboard', 'icon': 'verified_user', 'index': 4},
    {'title': 'AI Fraud Forecasting', 'icon': 'psychology', 'index': 5},
  ];

  @override
  void initState() {
    super.initState();
    _loadSystemStats();
  }

  Future<void> _loadSystemStats() async {
    setState(() => _isLoading = true);
    try {
      final stats = await _adminService.getSystemStatistics();
      setState(() => _systemStats = stats);
    } catch (e) {
      debugPrint('Load system stats error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ErrorBoundaryWrapper(
      screenName: 'EnhancedAdminControlPanel',
      onRetry: _loadSystemStats,
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: Colors.white,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: CustomAppBar(
            title: 'Enhanced Admin Control Panel',
            variant: CustomAppBarVariant.standard,
            leading: IconButton(
              icon: CustomIconWidget(
                iconName: 'menu',
                color: Theme.of(context).appBarTheme.foregroundColor!,
                size: 24,
              ),
              onPressed: () => _scaffoldKey.currentState?.openDrawer(),
            ),
            actions: [
              IconButton(
                icon: CustomIconWidget(
                  iconName: 'refresh',
                  color: Theme.of(context).appBarTheme.foregroundColor!,
                  size: 24,
                ),
                onPressed: _loadSystemStats,
              ),
            ],
          ),
        ),
        drawer: _buildNavigationDrawer(context),
        body: _isLoading
            ? const SkeletonDashboard()
            : RefreshIndicator(
                onRefresh: () async {
                  await _loadSystemStats();
                  if (_selectedDrawerIndex == 1) {
                    _usersPanelFuture = _adminService.getUsers(limit: 50);
                  }
                  if (_selectedDrawerIndex == 3) {
                    _auditPanelFuture = _adminService.getAuditLogs(limit: 40);
                  }
                  if (_selectedDrawerIndex == 4) {
                    _compliancePanelFuture =
                        _adminService.getComplianceMetrics();
                  }
                  if (mounted) setState(() {});
                },
                child: _selectedDrawerIndex == 0
                    ? _buildDashboardScroll(context)
                    : _buildSelectedPanel(context),
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
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.primary.withAlpha(204),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
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
                          'Admin Control Panel',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.onPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Enterprise Governance',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onPrimary.withAlpha(204),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.symmetric(vertical: 2.h),
                itemCount: _drawerSections.length,
                itemBuilder: (context, index) {
                  final section = _drawerSections[index];
                  final isSelected = _selectedDrawerIndex == section['index'];

                  return ListTile(
                    leading: CustomIconWidget(
                      iconName: section['icon'],
                      color: isSelected
                          ? theme.colorScheme.primary
                          : theme.iconTheme.color!,
                      size: 24,
                    ),
                    title: Text(
                      section['title'],
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: isSelected
                            ? theme.colorScheme.primary
                            : theme.textTheme.bodyLarge?.color,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                    selected: isSelected,
                    selectedTileColor: theme.colorScheme.primary.withAlpha(26),
                    onTap: () {
                      final idx = section['index'] as int;
                      setState(() {
                        _selectedDrawerIndex = idx;
                        if (idx == 1) {
                          _usersPanelFuture = _adminService.getUsers(limit: 50);
                        }
                        if (idx == 3) {
                          _auditPanelFuture = _adminService.getAuditLogs(limit: 40);
                        }
                        if (idx == 4) {
                          _compliancePanelFuture =
                              _adminService.getComplianceMetrics();
                        }
                      });
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
            Divider(height: 1, color: theme.dividerColor),
            ListTile(
              leading: CustomIconWidget(
                iconName: 'emergency',
                color: Colors.red,
                size: 24,
              ),
              title: Text(
                'Emergency Controls',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onTap: () => _showEmergencyControls(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardScroll(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Platform Overview',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 2.h),
          _buildMetricsGrid(context),
          SizedBox(height: 3.h),
          Text(
            'Prize distribution & payouts',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 1.h),
          _buildPrizeDistributionLinks(context),
        ],
      ),
    );
  }

  Widget _buildPrizeDistributionLinks(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.dividerColor),
      ),
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Open operational hubs for payouts, prizes, and settlements.',
              style: theme.textTheme.bodyMedium,
            ),
            SizedBox(height: 2.h),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: () => Navigator.of(context, rootNavigator: true)
                      .pushNamed(AppRoutes.automatedPaymentProcessingHub),
                  icon: const Icon(Icons.payments, size: 18),
                  label: const Text('Payment hub'),
                ),
                OutlinedButton.icon(
                  onPressed: () => Navigator.of(context, rootNavigator: true)
                      .pushNamed(AppRoutes.digitalWalletScreen),
                  icon: const Icon(Icons.account_balance_wallet, size: 18),
                  label: const Text('Digital wallet'),
                ),
                OutlinedButton.icon(
                  onPressed: () => Navigator.of(context, rootNavigator: true)
                      .pushNamed(AppRoutes.walletPrizeDistributionCenter),
                  icon: const Icon(Icons.card_giftcard, size: 18),
                  label: const Text('Prize distribution'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedPanel(BuildContext context) {
    switch (_selectedDrawerIndex) {
      case 1:
        return _buildUserManagementBody(context);
      case 2:
        return _buildFinancialBody(context);
      case 3:
        return _buildAnalyticsBody(context);
      case 4:
        return _buildComplianceBody(context);
      case 5:
        return _buildFraudBody(context);
      default:
        return _buildDashboardScroll(context);
    }
  }

  Widget _buildUserManagementBody(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _usersPanelFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        final users = snapshot.data ?? [];
        if (users.isEmpty) {
          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: const [
              SizedBox(height: 48),
              Center(child: Text('No user profiles returned')),
            ],
          );
        }
        return ListView.separated(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(4.w),
          itemCount: users.length,
          separatorBuilder: (_, __) => SizedBox(height: 1.h),
          itemBuilder: (context, i) {
            final u = users[i];
            final email = u['email']?.toString() ?? '';
            final username = u['username']?.toString() ?? '';
            final role = u['role']?.toString() ?? '';
            final status = u['status']?.toString() ?? '';
            return ListTile(
              tileColor: Theme.of(context).cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Theme.of(context).dividerColor),
              ),
              title: Text(username.isNotEmpty ? username : email),
              subtitle: Text(
                [email, role, status].where((s) => s.isNotEmpty).join(' · '),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFinancialBody(BuildContext context) {
    final theme = Theme.of(context);
    final rev = _systemStats['total_revenue'];
    final revStr = rev is num
        ? rev.toStringAsFixed(2)
        : (rev?.toString() ?? '0.00');
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.all(4.w),
      children: [
        Text('Financial snapshot', style: theme.textTheme.titleLarge),
        SizedBox(height: 2.h),
        Text('Total revenue (platform): \$$revStr'),
        SizedBox(height: 1.h),
        Text('Active elections: ${_systemStats['active_elections'] ?? 0}'),
        SizedBox(height: 3.h),
        FilledButton.icon(
          onPressed: () => Navigator.of(context, rootNavigator: true)
              .pushNamed(AppRoutes.unifiedRevenueIntelligenceDashboard),
          icon: const Icon(Icons.insights, size: 18),
          label: const Text('Revenue intelligence'),
        ),
      ],
    );
  }

  Widget _buildAnalyticsBody(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _auditPanelFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        final logs = snapshot.data ?? [];
        if (logs.isEmpty) {
          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: const [
              SizedBox(height: 48),
              Center(child: Text('No audit log entries')),
            ],
          );
        }
        return ListView.separated(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(4.w),
          itemCount: logs.length,
          separatorBuilder: (_, __) => SizedBox(height: 0.5.h),
          itemBuilder: (context, i) {
            final row = logs[i];
            final action = row['action_type']?.toString() ?? '';
            final at = row['created_at']?.toString() ?? '';
            return ListTile(
              dense: true,
              title: Text(action),
              subtitle: Text(at),
            );
          },
        );
      },
    );
  }

  Widget _buildComplianceBody(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _compliancePanelFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final m = snapshot.data ?? {};
        if (m.isEmpty) {
          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: const [
              SizedBox(height: 48),
              Center(child: Text('No compliance metrics')),
            ],
          );
        }
        return ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(4.w),
          children: m.entries
              .map(
                (e) => ListTile(
                  title: Text(e.key),
                  subtitle: Text(e.value?.toString() ?? ''),
                ),
              )
              .toList(),
        );
      },
    );
  }

  Widget _buildFraudBody(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.all(4.w),
      children: [
        Text('Fraud & risk', style: theme.textTheme.titleLarge),
        SizedBox(height: 2.h),
        Text(
          'Open specialized fraud intelligence surfaces backed by your Supabase data and services.',
          style: theme.textTheme.bodyMedium,
        ),
        SizedBox(height: 3.h),
        FilledButton.icon(
          onPressed: () => Navigator.of(context, rootNavigator: true)
              .pushNamed(AppRoutes.advancedAiFraudPreventionCommandCenter),
          icon: const Icon(Icons.shield, size: 18),
          label: const Text('AI fraud prevention'),
        ),
        SizedBox(height: 1.h),
        OutlinedButton.icon(
          onPressed: () => Navigator.of(context, rootNavigator: true)
              .pushNamed(AppRoutes.fraudMonitoringDashboard),
          icon: const Icon(Icons.monitor_heart, size: 18),
          label: const Text('Fraud monitoring'),
        ),
      ],
    );
  }

  String _formatRevenueMetric(dynamic revenue) {
    final s = revenue is num
        ? revenue.toStringAsFixed(2)
        : (revenue?.toString() ?? '0.00');
    return '\$$s';
  }

  Widget _buildMetricsGrid(BuildContext context) {
    final theme = Theme.of(context);

    final metrics = [
      {
        'title': 'Total Users',
        'value': _systemStats['total_users']?.toString() ?? '0',
        'icon': 'people',
        'color': const Color(0xFF3B82F6),
      },
      {
        'title': 'Active Elections',
        'value': _systemStats['active_elections']?.toString() ?? '0',
        'icon': 'how_to_vote',
        'color': const Color(0xFF10B981),
      },
      {
        'title': 'Total Revenue',
        'value': _formatRevenueMetric(_systemStats['total_revenue']),
        'icon': 'account_balance',
        'color': const Color(0xFFF59E0B),
      },
      {
        'title': 'System Health',
        'value': '${_systemStats['system_health']?.toString() ?? '100'}%',
        'icon': 'check_circle',
        'color': const Color(0xFF10B981),
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 3.w,
        mainAxisSpacing: 2.h,
        childAspectRatio: 1.5,
      ),
      itemCount: metrics.length,
      itemBuilder: (context, index) {
        final metric = metrics[index];
        return Container(
          padding: EdgeInsets.all(3.w),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(12.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(13),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (metric['color'] as Color).withAlpha(26),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: CustomIconWidget(
                  iconName: metric['icon'] as String,
                  color: metric['color'] as Color,
                  size: 24,
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    metric['value'] as String,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 0.5.h),
                  Text(
                    metric['title'] as String,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.textTheme.bodySmall?.color?.withAlpha(179),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showEmergencyControls(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            CustomIconWidget(
              iconName: 'emergency',
              color: Colors.red,
              size: 24,
            ),
            const SizedBox(width: 8),
            const Text('Emergency Controls'),
          ],
        ),
        content: EmergencyControlsWidget(
          onTriggerAction:
              ({
                required String actionName,
                required String actionType,
                required String reason,
              }) async {
                await _loadSystemStats();
              },
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
