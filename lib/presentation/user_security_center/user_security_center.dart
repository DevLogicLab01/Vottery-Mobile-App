import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../services/user_security_service.dart';
import '../../widgets/custom_app_bar.dart';
import './widgets/fraud_risk_dashboard_widget.dart';
import './widgets/security_events_timeline_widget.dart';
import './widgets/trusted_devices_widget.dart';
import './widgets/security_settings_widget.dart';
import './widgets/active_sessions_widget.dart';
import './widgets/security_audit_export_widget.dart';
import '../../widgets/error_boundary_wrapper.dart';
import '../../widgets/shimmer_skeleton_loader.dart';

class UserSecurityCenter extends StatefulWidget {
  const UserSecurityCenter({super.key});

  @override
  State<UserSecurityCenter> createState() => _UserSecurityCenterState();
}

class _UserSecurityCenterState extends State<UserSecurityCenter>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  bool _showContextualHelp = false;
  Map<String, dynamic>? _fraudRiskScore;
  Map<String, dynamic> _eventsSummary = {};
  List<Map<String, dynamic>> _trustedDevices = [];
  Map<String, dynamic>? _securitySettings;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _tabController.addListener(() {
      if (mounted && _showContextualHelp) {
        setState(() {});
      }
    });
    _loadData();
  }

  String _currentHelpText() {
    const tabHelp = [
      'Risk Dashboard shows your current threat level, scan freshness, and top security signals.',
      'Events lists security incidents, unresolved threats, and response timeline actions.',
      'Devices lets you review trusted devices and remove unknown sessions quickly.',
      'Settings controls 2FA, session timeout, and account protection policies.',
      'Sessions shows active logins and supports session revocation for suspicious access.',
      'Audit Trail exports security evidence and compliance-grade activity history.',
    ];
    final idx = _tabController.index.clamp(0, tabHelp.length - 1);
    return tabHelp[idx];
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final results = await Future.wait([
        UserSecurityService.instance.getFraudRiskScore(),
        UserSecurityService.instance.getSecurityEventsSummary(),
        UserSecurityService.instance.getTrustedDevices(),
        UserSecurityService.instance.getSecuritySettings(),
      ]);

      if (mounted) {
        setState(() {
          _fraudRiskScore = results[0] as Map<String, dynamic>?;
          _eventsSummary = results[1] as Map<String, dynamic>;
          _trustedDevices = results[2] as List<Map<String, dynamic>>;
          _securitySettings = results[3] as Map<String, dynamic>?;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading data: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final riskScore = _fraudRiskScore?['risk_score'] ?? 0;
    final threatLevel = _fraudRiskScore?['threat_level'] ?? 'low';

    Color threatColor;
    switch (threatLevel) {
      case 'critical':
        threatColor = Colors.red;
        break;
      case 'high':
        threatColor = Colors.orange;
        break;
      case 'medium':
        threatColor = Colors.yellow[700]!;
        break;
      default:
        threatColor = Colors.green;
    }

    return ErrorBoundaryWrapper(
      screenName: 'UserSecurityCenter',
      onRetry: _loadData,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: CustomAppBar(
            title: 'User Security Center',
            variant: CustomAppBarVariant.withBack,
          ),
        ),
        body: _isLoading
            ? const SkeletonDashboard()
            : Column(
                children: [
                  // Security score header
                  Container(
                    padding: EdgeInsets.all(3.w),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [threatColor, threatColor.withAlpha(179)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(26),
                          blurRadius: 4.0,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        // Risk score circle
                        Container(
                          width: 20.w,
                          height: 20.w,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                          ),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '$riskScore',
                                  style: TextStyle(
                                    fontSize: 20.sp,
                                    fontWeight: FontWeight.bold,
                                    color: threatColor,
                                  ),
                                ),
                                Text(
                                  'Risk Score',
                                  style: TextStyle(
                                    fontSize: 9.sp,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(width: 4.w),

                        // Threat info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Threat Level: ${threatLevel.toUpperCase()}',
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(height: 0.5.h),
                              Text(
                                'Last scan: ${_fraudRiskScore?['last_scan_at'] != null ? DateTime.parse(_fraudRiskScore!['last_scan_at']).toString().substring(0, 16) : 'Never'}',
                                style: TextStyle(
                                  fontSize: 11.sp,
                                  color: Colors.white.withAlpha(230),
                                ),
                              ),
                              SizedBox(height: 1.h),
                              Row(
                                children: [
                                  _buildQuickStat(
                                    'Events',
                                    '${_eventsSummary['total'] ?? 0}',
                                  ),
                                  SizedBox(width: 3.w),
                                  _buildQuickStat(
                                    'Unresolved',
                                    '${_eventsSummary['unresolved'] ?? 0}',
                                  ),
                                  SizedBox(width: 3.w),
                                  _buildQuickStat(
                                    'Devices',
                                    '${_trustedDevices.length}',
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Tab bar
                  Container(
                    color: theme.colorScheme.surface,
                    child: TabBar(
                      controller: _tabController,
                      isScrollable: true,
                      labelColor: theme.colorScheme.primary,
                      unselectedLabelColor: theme.colorScheme.onSurface
                          .withAlpha(153),
                      indicatorColor: theme.colorScheme.primary,
                      labelStyle: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                      ),
                      unselectedLabelStyle: TextStyle(fontSize: 12.sp),
                      tabs: const [
                        Tab(text: 'Risk Dashboard'),
                        Tab(text: 'Events'),
                        Tab(text: 'Devices'),
                        Tab(text: 'Settings'),
                        Tab(text: 'Sessions'),
                        Tab(text: 'Audit Trail'),
                      ],
                    ),
                  ),

                  // Tab views
                  Expanded(
                    child: _isLoading
                        ? Center(child: CircularProgressIndicator())
                        : TabBarView(
                            controller: _tabController,
                            children: [
                              FraudRiskDashboardWidget(
                                fraudRiskScore: _fraudRiskScore,
                                onRefresh: _loadData,
                              ),
                              SecurityEventsTimelineWidget(
                                eventsSummary: _eventsSummary,
                                onEventsChanged: _loadData,
                              ),
                              TrustedDevicesWidget(
                                devices: _trustedDevices,
                                onDevicesChanged: _loadData,
                              ),
                              SecuritySettingsWidget(
                                settings: _securitySettings,
                                onSettingsChanged: _loadData,
                              ),
                              ActiveSessionsWidget(
                                onSessionsChanged: _loadData,
                              ),
                              SecurityAuditExportWidget(),
                            ],
                          ),
                  ),
                ],
              ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            setState(() => _showContextualHelp = !_showContextualHelp);
          },
          icon: const Icon(Icons.help_outline),
          label: Text(_showContextualHelp ? 'Hide Help' : 'What is this?'),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        bottomSheet: _showContextualHelp
            ? Container(
                width: double.infinity,
                padding: EdgeInsets.fromLTRB(4.w, 2.h, 4.w, 2.h),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  border: Border(
                    top: BorderSide(
                      color: theme.colorScheme.outline.withValues(alpha: 0.25),
                    ),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.help_outline, color: theme.colorScheme.primary),
                    SizedBox(width: 2.w),
                    Expanded(
                      child: Text(
                        _currentHelpText(),
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              )
            : null,
      ),
    );
  }

  Widget _buildQuickStat(String label, String value) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(51),
        borderRadius: BorderRadius.circular(4.0),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 9.sp,
              color: Colors.white.withAlpha(230),
            ),
          ),
        ],
      ),
    );
  }
}
