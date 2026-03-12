import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/enhanced_analytics_service.dart';
import '../../services/enhanced_compliance_service.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_icon_widget.dart';
import '../../widgets/error_boundary_wrapper.dart';
import '../../widgets/shimmer_skeleton_loader.dart';
import '../../widgets/enhanced_empty_state_widget.dart';
import './widgets/audit_trail_visualization_widget.dart';
import './widgets/data_retention_widget.dart';
import './widgets/jurisdiction_compliance_card_widget.dart';
import './widgets/report_generation_panel_widget.dart';
import './widgets/scheduled_delivery_widget.dart';

class EnhancedComplianceReportsDashboard extends StatefulWidget {
  const EnhancedComplianceReportsDashboard({super.key});

  @override
  State<EnhancedComplianceReportsDashboard> createState() =>
      _EnhancedComplianceReportsDashboardState();
}

class _EnhancedComplianceReportsDashboardState
    extends State<EnhancedComplianceReportsDashboard>
    with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final EnhancedComplianceService _complianceService =
      EnhancedComplianceService.instance;

  late TabController _tabController;
  bool _isLoading = false;
  double _complianceHealthScore = 0.0;
  Map<String, Map<String, dynamic>> _jurisdictionStatuses = {};
  List<Map<String, dynamic>> _recentReports = [];
  List<Map<String, dynamic>> _auditTrail = [];
  List<Map<String, dynamic>> _scheduledDeliveries = [];
  List<Map<String, dynamic>> _retentionPolicies = [];
  Timer? _refreshTimer;

  final List<Map<String, String>> _jurisdictions = [
    {'code': 'GDPR', 'name': 'EU General Data Protection Regulation'},
    {'code': 'CCPA', 'name': 'California Consumer Privacy Act'},
    {'code': 'CCRA', 'name': 'Canadian Consumer Rights Act'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadComplianceData();
    _setupAutoRefresh();
    EnhancedAnalyticsService.instance.trackScreenView(
      screenName: 'Enhanced Compliance Reports Dashboard',
      screenClass: 'EnhancedComplianceReportsDashboard',
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _setupAutoRefresh() {
    _refreshTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      if (mounted) {
        _loadComplianceData(silent: true);
      }
    });
  }

  Future<void> _loadComplianceData({bool silent = false}) async {
    if (!silent) {
      setState(() => _isLoading = true);
    }

    try {
      final results = await Future.wait([
        _complianceService.getComplianceHealthScore(),
        _complianceService.getComplianceReports(limit: 20),
        _complianceService.getDataAccessAuditTrail(limit: 50),
        _complianceService.getScheduledDeliveries(),
        _complianceService.getDataRetentionPolicies(),
      ]);

      final healthScore = results[0] as double;
      final reports = results[1] as List<Map<String, dynamic>>;
      final auditTrail = results[2] as List<Map<String, dynamic>>;
      final deliveries = results[3] as List<Map<String, dynamic>>;
      final policies = results[4] as List<Map<String, dynamic>>;

      // Load jurisdiction-specific statuses
      final Map<String, Map<String, dynamic>> jurisdictionStatuses = {};
      for (final jurisdiction in _jurisdictions) {
        final status = await _complianceService
            .getComplianceStatusByJurisdiction(jurisdiction['code']!);
        jurisdictionStatuses[jurisdiction['code']!] = status;
      }

      if (mounted) {
        setState(() {
          _complianceHealthScore = healthScore;
          _recentReports = reports;
          _auditTrail = auditTrail;
          _scheduledDeliveries = deliveries;
          _retentionPolicies = policies;
          _jurisdictionStatuses = jurisdictionStatuses;
        });
      }
    } catch (e) {
      debugPrint('Load compliance data error: $e');
    } finally {
      if (!silent && mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ErrorBoundaryWrapper(
      screenName: 'EnhancedComplianceReportsDashboard',
      onRetry: () => _loadComplianceData(),
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: CustomAppBar(
            title: 'Enhanced Compliance Reports',
            variant: CustomAppBarVariant.standard,
            leading: IconButton(
              icon: CustomIconWidget(
                iconName: 'arrow_back',
                color: theme.appBarTheme.foregroundColor!,
                size: 24,
              ),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: CustomIconWidget(
                  iconName: 'refresh',
                  color: theme.appBarTheme.foregroundColor!,
                  size: 24,
                ),
                onPressed: () => _loadComplianceData(),
              ),
            ],
          ),
        ),
        body: _isLoading
            ? const SkeletonDashboard()
            : _recentReports.isEmpty
            ? NoDataEmptyState(
                title: 'No Compliance Reports',
                description:
                    'Compliance reports will appear here once generated.',
                onRefresh: () => _loadComplianceData(),
              )
            : Column(
                children: [
                  _buildComplianceHealthHeader(theme),
                  _buildTabBar(theme),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildJurisdictionOverviewTab(),
                        _buildReportGenerationTab(),
                        _buildAuditTrailTab(),
                        _buildScheduledDeliveryTab(),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildComplianceHealthHeader(ThemeData theme) {
    final scoreColor = _complianceHealthScore >= 90
        ? Colors.green
        : _complianceHealthScore >= 70
        ? Colors.orange
        : Colors.red;

    return Container(
      padding: EdgeInsets.all(4.w),
      color: theme.cardColor,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Compliance Health Score',
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              SizedBox(height: 0.5.h),
              Text(
                '${_complianceHealthScore.toStringAsFixed(1)}%',
                style: GoogleFonts.inter(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                  color: scoreColor,
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Active Reports',
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              SizedBox(height: 0.5.h),
              Text(
                _recentReports
                    .where((r) => r['status'] == 'pending')
                    .length
                    .toString(),
                style: GoogleFonts.inter(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(ThemeData theme) {
    return Container(
      color: theme.cardColor,
      child: TabBar(
        controller: _tabController,
        labelColor: theme.colorScheme.primary,
        unselectedLabelColor: theme.colorScheme.onSurface.withAlpha(153),
        indicatorColor: theme.colorScheme.primary,
        labelStyle: GoogleFonts.inter(
          fontSize: 11.sp,
          fontWeight: FontWeight.w600,
        ),
        tabs: const [
          Tab(text: 'Jurisdictions'),
          Tab(text: 'Reports'),
          Tab(text: 'Audit Trail'),
          Tab(text: 'Delivery'),
        ],
      ),
    );
  }

  Widget _buildJurisdictionOverviewTab() {
    return RefreshIndicator(
      onRefresh: () => _loadComplianceData(),
      child: ListView(
        padding: EdgeInsets.all(4.w),
        children: [
          ..._jurisdictions.map((jurisdiction) {
            final status = _jurisdictionStatuses[jurisdiction['code']] ?? {};
            return JurisdictionComplianceCardWidget(
              jurisdiction: jurisdiction,
              status: status,
              onGenerateReport: () => _generateReport(jurisdiction['code']!),
            );
          }),
          SizedBox(height: 2.h),
          DataRetentionWidget(policies: _retentionPolicies),
        ],
      ),
    );
  }

  Widget _buildReportGenerationTab() {
    return RefreshIndicator(
      onRefresh: () => _loadComplianceData(),
      child: ListView(
        padding: EdgeInsets.all(4.w),
        children: [
          ReportGenerationPanelWidget(
            onGenerateReport: _generateReport,
            recentReports: _recentReports,
          ),
        ],
      ),
    );
  }

  Widget _buildAuditTrailTab() {
    return RefreshIndicator(
      onRefresh: () => _loadComplianceData(),
      child: AuditTrailVisualizationWidget(auditTrail: _auditTrail),
    );
  }

  Widget _buildScheduledDeliveryTab() {
    return RefreshIndicator(
      onRefresh: () => _loadComplianceData(),
      child: ListView(
        padding: EdgeInsets.all(4.w),
        children: [
          ScheduledDeliveryWidget(
            scheduledDeliveries: _scheduledDeliveries,
            onRefresh: _loadComplianceData,
          ),
        ],
      ),
    );
  }

  Future<void> _generateReport(String jurisdiction) async {
    try {
      final reportId = await _complianceService.generateComplianceReport(
        jurisdiction: jurisdiction,
        reportType: 'data_export',
      );

      if (reportId != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Report generation started for $jurisdiction'),
            backgroundColor: Colors.green,
          ),
        );
        _loadComplianceData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate report: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
