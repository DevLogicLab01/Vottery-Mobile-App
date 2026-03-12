import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/admin_management_service.dart';
import '../../services/creator_monetization_service.dart';
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
  final CreatorMonetizationService _monetizationService =
      CreatorMonetizationService.instance;

  int _selectedDrawerIndex = 0;
  bool _isLoading = false;
  Map<String, dynamic> _systemStats = {};

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
                onRefresh: _loadSystemStats,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.all(4.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Platform Overview',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      SizedBox(height: 2.h),
                      _buildMetricsGrid(context),
                      SizedBox(height: 3.h),
                      Text(
                        'Prize Distribution',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 1.h),
                      _buildPlaceholderPanel(
                        context,
                        'Prize Distribution Panel',
                      ),
                    ],
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
                      setState(() => _selectedDrawerIndex = section['index']);
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

  Widget _buildSelectedPanel(BuildContext context) {
    switch (_selectedDrawerIndex) {
      case 0:
        return _buildDashboardOverview(context);
      case 1:
        return _buildPlaceholderPanel(context, 'User Management Panel');
      case 2:
        return _buildPlaceholderPanel(context, 'Financial Management Panel');
      case 3:
        return _buildPlaceholderPanel(context, 'Analytics & Reports Panel');
      default:
        return _buildDashboardOverview(context);
    }
  }

  Widget _buildPlaceholderPanel(BuildContext context, String title) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CustomIconWidget(
            iconName: 'construction',
            color: theme.colorScheme.primary,
            size: 48,
          ),
          SizedBox(height: 2.h),
          Text(
            title,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            'This panel is under construction',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.textTheme.bodySmall?.color?.withAlpha(179),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardOverview(BuildContext context) {
    final theme = Theme.of(context);

    return RefreshIndicator(
      onRefresh: _loadSystemStats,
      child: SingleChildScrollView(
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
              'Prize Distribution',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 1.h),
            _buildPlaceholderPanel(context, 'Prize Distribution Panel'),
          ],
        ),
      ),
    );
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
        'value':
            '\$${_systemStats['total_revenue']?.toStringAsFixed(2) ?? '0.00'}',
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
