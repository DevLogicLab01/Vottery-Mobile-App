import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/compliance_service.dart';
import '../../services/enhanced_analytics_service.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_icon_widget.dart';
import '../../widgets/error_boundary_wrapper.dart';
import '../../widgets/shimmer_skeleton_loader.dart';
import './widgets/audit_trail_timeline_widget.dart';
import './widgets/automated_regulatory_filings_widget.dart';
import './widgets/compliance_health_header_widget.dart';
import './widgets/multi_jurisdiction_matrix_widget.dart';
import './widgets/policy_violation_export_widget.dart';

class EnhancedComplianceDashboard extends StatefulWidget {
  const EnhancedComplianceDashboard({super.key});

  @override
  State<EnhancedComplianceDashboard> createState() =>
      _EnhancedComplianceDashboardState();
}

class _EnhancedComplianceDashboardState
    extends State<EnhancedComplianceDashboard>
    with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final ComplianceService _complianceService = ComplianceService.instance;

  late TabController _tabController;
  bool _isLoading = false;
  Map<String, dynamic> _complianceStatus = {};
  List<Map<String, dynamic>> _activeJurisdictions = [];
  int _pendingFilings = 0;
  double _complianceHealthScore = 0.0;

  final List<Map<String, String>> _jurisdictions = [
    {'code': 'US', 'name': 'United States', 'icon': 'flag'},
    {'code': 'EU', 'name': 'European Union', 'icon': 'flag'},
    {'code': 'UK', 'name': 'United Kingdom', 'icon': 'flag'},
    {'code': 'APAC', 'name': 'Asia-Pacific', 'icon': 'flag'},
    {'code': 'LATAM', 'name': 'Latin America', 'icon': 'flag'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadComplianceData();
    EnhancedAnalyticsService.instance.trackScreenView(
      screenName: 'Enhanced Compliance Dashboard',
      screenClass: 'EnhancedComplianceDashboard',
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadComplianceData() async {
    setState(() => _isLoading = true);
    try {
      final status = await _complianceService.getComplianceStatus();
      setState(() {
        _complianceStatus = status;
        _activeJurisdictions = _jurisdictions;
        _pendingFilings = (status['pending_filings'] ?? 0) as int;
        _complianceHealthScore = (status['health_score'] ?? 85.0) as double;
      });
    } catch (e) {
      debugPrint('Load compliance data error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ErrorBoundaryWrapper(
      screenName: 'EnhancedComplianceDashboard',
      onRetry: _loadComplianceData,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: CustomAppBar(
            title: 'Enhanced Compliance Dashboard',
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
                onPressed: _loadComplianceData,
              ),
            ],
          ),
        ),
        drawer: _buildNavigationDrawer(context),
        body: _isLoading
            ? const SkeletonDashboard()
            : SingleChildScrollView(
                child: Column(
                  children: [
                    ComplianceHealthHeaderWidget(
                      activeJurisdictions: _activeJurisdictions,
                      pendingFilings: _pendingFilings,
                      healthScore: _complianceHealthScore,
                    ),
                    Container(
                      color: Theme.of(context).cardColor,
                      child: TabBar(
                        controller: _tabController,
                        labelColor: Theme.of(context).colorScheme.primary,
                        unselectedLabelColor: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.color,
                        indicatorColor: Theme.of(context).colorScheme.primary,
                        labelStyle: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                        ),
                        unselectedLabelStyle: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w400,
                        ),
                        tabs: const [
                          Tab(text: 'Filings'),
                          Tab(text: 'Audit Trail'),
                          Tab(text: 'Violations'),
                          Tab(text: 'Jurisdictions'),
                        ],
                      ),
                    ),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          AutomatedRegulatoryFilingsWidget(),
                          AuditTrailTimelineWidget(),
                          PolicyViolationExportWidget(),
                          MultiJurisdictionMatrixWidget(
                            jurisdictions: _activeJurisdictions,
                          ),
                        ],
                      ),
                    ),
                  ],
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
                        iconName: 'verified_user',
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
                          'Compliance Dashboard',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.onPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Regulatory Oversight',
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
              child: ListView(
                padding: EdgeInsets.symmetric(vertical: 2.h),
                children: [
                  _buildDrawerItem(
                    context,
                    'GDPR/CCPA Automation',
                    'policy',
                    () => _tabController.animateTo(0),
                  ),
                  _buildDrawerItem(
                    context,
                    'Audit Trail Timeline',
                    'timeline',
                    () => _tabController.animateTo(1),
                  ),
                  _buildDrawerItem(
                    context,
                    'Policy Violations',
                    'warning',
                    () => _tabController.animateTo(2),
                  ),
                  _buildDrawerItem(
                    context,
                    'Multi-Jurisdiction Matrix',
                    'public',
                    () => _tabController.animateTo(3),
                  ),
                  Divider(height: 1, color: theme.dividerColor),
                  _buildDrawerItem(
                    context,
                    'Emergency Compliance Controls',
                    'emergency',
                    () => _showEmergencyControls(context),
                    isEmergency: true,
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
    VoidCallback onTap, {
    bool isEmergency = false,
  }) {
    final theme = Theme.of(context);
    final color = isEmergency ? Colors.red : theme.iconTheme.color!;

    return ListTile(
      leading: CustomIconWidget(iconName: iconName, color: color, size: 24),
      title: Text(
        title,
        style: theme.textTheme.bodyLarge?.copyWith(
          color: isEmergency ? Colors.red : theme.textTheme.bodyLarge?.color,
          fontWeight: isEmergency ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      onTap: () {
        Navigator.pop(context);
        onTap();
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
            SizedBox(width: 2.w),
            Text('Emergency Compliance Controls'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton.icon(
              onPressed: () => _handleEmergencyAction('suspend_processing'),
              icon: Icon(Icons.pause_circle),
              label: Text('Suspend Data Processing'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
            ),
            SizedBox(height: 1.h),
            ElevatedButton.icon(
              onPressed: () => _handleEmergencyAction('notify_regulators'),
              icon: Icon(Icons.notification_important),
              label: Text('Notify Regulatory Bodies'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
            ),
            SizedBox(height: 1.h),
            ElevatedButton.icon(
              onPressed: () => _handleEmergencyAction('crisis_management'),
              icon: Icon(Icons.crisis_alert),
              label: Text('Activate Crisis Management'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade900,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleEmergencyAction(String action) async {
    Navigator.pop(context);
    await _complianceService.logComplianceAction(
      complianceType: 'EMERGENCY',
      actionType: action,
      details: {'timestamp': DateTime.now().toIso8601String()},
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Emergency action "$action" initiated'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
