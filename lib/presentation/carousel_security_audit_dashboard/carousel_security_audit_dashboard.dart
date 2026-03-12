import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../services/carousel_security_audit_service.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/error_boundary_wrapper.dart';
import '../../theme/app_theme.dart';
import './widgets/system_compliance_card_widget.dart';
import './widgets/violation_card_widget.dart';
import './widgets/compliance_trends_chart_widget.dart';
import './widgets/policy_management_widget.dart';

/// Carousel Security Audit Dashboard
/// Comprehensive compliance monitoring across 12 carousel systems with
/// anomaly scoring, policy violation tracking, and automated remediation
class CarouselSecurityAuditDashboard extends StatefulWidget {
  const CarouselSecurityAuditDashboard({super.key});

  @override
  State<CarouselSecurityAuditDashboard> createState() =>
      _CarouselSecurityAuditDashboardState();
}

class _CarouselSecurityAuditDashboardState
    extends State<CarouselSecurityAuditDashboard>
    with SingleTickerProviderStateMixin {
  final CarouselSecurityAuditService _auditService =
      CarouselSecurityAuditService.instance;

  late TabController _tabController;
  StreamSubscription? _violationsSubscription;

  Map<String, dynamic> _dashboardSummary = {};
  Map<String, Map<String, dynamic>> _systemScores = {};
  List<Map<String, dynamic>> _activeViolations = [];
  List<Map<String, dynamic>> _policies = [];
  bool _isLoading = true;

  String? _selectedSystem;
  String? _severityFilter;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadDashboardData();
    _setupRealtimeSubscription();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _violationsSubscription?.cancel();
    super.dispose();
  }

  void _setupRealtimeSubscription() {
    _violationsSubscription = _auditService.streamViolations().listen((
      violations,
    ) {
      if (mounted) {
        setState(() {
          _activeViolations = violations;
        });
      }
    });
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);

    final summary = await _auditService.getComplianceDashboardSummary();
    final policies = await _auditService.getAllPolicies();

    if (mounted) {
      setState(() {
        _dashboardSummary = summary;
        _systemScores = summary['system_scores'] ?? {};
        _policies = policies;
        _isLoading = false;
      });
    }
  }

  Future<void> _handleViolationAction(String violationId, String action) async {
    String status;
    switch (action) {
      case 'investigate':
        status = 'investigating';
        break;
      case 'remediate':
        status = 'remediated';
        break;
      case 'dismiss':
        status = 'dismissed';
        break;
      default:
        return;
    }

    final success = await _auditService.updateViolationStatus(
      violationId: violationId,
      status: status,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Violation ${action}d successfully'
                : 'Failed to update violation',
          ),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );

      if (success) {
        _loadDashboardData();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ErrorBoundaryWrapper(
      screenName: 'Carousel Security Audit Dashboard',
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: CustomAppBar(
          title: 'Carousel Security Audit',
          actions: [
            IconButton(
              icon: Icon(Icons.refresh, color: Colors.white),
              onPressed: _loadDashboardData,
            ),
          ],
        ),
        body: _isLoading
            ? Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  _buildComplianceHeader(),
                  TabBar(
                    controller: _tabController,
                    labelColor: AppTheme.primaryColor,
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: AppTheme.primaryColor,
                    tabs: [
                      Tab(text: 'Systems'),
                      Tab(text: 'Violations'),
                      Tab(text: 'Policies'),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildSystemsTab(),
                        _buildViolationsTab(),
                        _buildPoliciesTab(),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildComplianceHeader() {
    final overallScore = _dashboardSummary['overall_score'] ?? 0.0;
    final totalViolations = _dashboardSummary['total_active_violations'] ?? 0;
    final complianceStatus =
        _dashboardSummary['compliance_status'] ?? 'Unknown';

    Color statusColor;
    if (overallScore >= 90) {
      statusColor = Colors.green;
    } else if (overallScore >= 70) {
      statusColor = Colors.orange;
    } else {
      statusColor = Colors.red;
    }

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryColor, AppTheme.secondaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildHeaderStat(
                'Platform Score',
                '${overallScore.toStringAsFixed(1)}',
                statusColor,
              ),
              _buildHeaderStat(
                'Active Violations',
                '$totalViolations',
                totalViolations > 0 ? Colors.red : Colors.green,
              ),
              _buildHeaderStat('Status', complianceStatus, statusColor),
            ],
          ),
          SizedBox(height: 2.h),
          _buildViolationsBySeverity(),
        ],
      ),
    );
  }

  Widget _buildHeaderStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.white70, fontSize: 12.sp),
        ),
        SizedBox(height: 0.5.h),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildViolationsBySeverity() {
    final violationsBySeverity =
        _dashboardSummary['violations_by_severity'] ?? {};

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildSeverityBadge(
          'Critical',
          violationsBySeverity['critical'] ?? 0,
          Colors.red,
        ),
        _buildSeverityBadge(
          'High',
          violationsBySeverity['high'] ?? 0,
          Colors.orange,
        ),
        _buildSeverityBadge(
          'Medium',
          violationsBySeverity['medium'] ?? 0,
          Colors.yellow,
        ),
        _buildSeverityBadge(
          'Low',
          violationsBySeverity['low'] ?? 0,
          Colors.blue,
        ),
      ],
    );
  }

  Widget _buildSeverityBadge(String label, int count, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
      decoration: BoxDecoration(
        color: color.withAlpha(51),
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: color),
      ),
      child: Column(
        children: [
          Text(
            '$count',
            style: TextStyle(
              color: color,
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: TextStyle(color: Colors.white, fontSize: 10.sp),
          ),
        ],
      ),
    );
  }

  Widget _buildSystemsTab() {
    return RefreshIndicator(
      onRefresh: _loadDashboardData,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'System Compliance Grid',
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 2.h),
            GridView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 3.w,
                mainAxisSpacing: 2.h,
                childAspectRatio: 1.2,
              ),
              itemCount: CarouselSecurityAuditService.carouselSystems.length,
              itemBuilder: (context, index) {
                final systemName =
                    CarouselSecurityAuditService.carouselSystems[index];
                final systemScore = _systemScores[systemName];

                return SystemComplianceCardWidget(
                  systemName: systemName,
                  complianceScore: systemScore?['compliance_score'] ?? 0,
                  violationCount: systemScore?['violation_count'] ?? 0,
                  riskLevel: systemScore?['risk_level'] ?? 'low',
                  onTap: () {
                    setState(() => _selectedSystem = systemName);
                    _tabController.animateTo(1);
                  },
                );
              },
            ),
            SizedBox(height: 3.h),
            ComplianceTrendsChartWidget(),
          ],
        ),
      ),
    );
  }

  Widget _buildViolationsTab() {
    final filteredViolations = _activeViolations.where((v) {
      if (_selectedSystem != null && v['system_name'] != _selectedSystem) {
        return false;
      }
      if (_severityFilter != null && v['severity'] != _severityFilter) {
        return false;
      }
      return true;
    }).toList();

    return Column(
      children: [
        _buildViolationsFilter(),
        Expanded(
          child: filteredViolations.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle, size: 60, color: Colors.green),
                      SizedBox(height: 2.h),
                      Text(
                        'No active violations',
                        style: TextStyle(fontSize: 14.sp),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.all(4.w),
                  itemCount: filteredViolations.length,
                  itemBuilder: (context, index) {
                    final violation = filteredViolations[index];
                    return ViolationCardWidget(
                      violation: violation,
                      onAction: (action) => _handleViolationAction(
                        violation['violation_id'],
                        action,
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildViolationsFilter() {
    return Container(
      padding: EdgeInsets.all(3.w),
      color: Colors.grey[100],
      child: Row(
        children: [
          Expanded(
            child: DropdownButton<String>(
              value: _selectedSystem,
              hint: Text('All Systems'),
              isExpanded: true,
              items: [
                DropdownMenuItem(value: null, child: Text('All Systems')),
                ...CarouselSecurityAuditService.carouselSystems
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    ,
              ],
              onChanged: (value) {
                setState(() => _selectedSystem = value);
              },
            ),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: DropdownButton<String>(
              value: _severityFilter,
              hint: Text('All Severities'),
              isExpanded: true,
              items: [
                DropdownMenuItem(value: null, child: Text('All Severities')),
                DropdownMenuItem(value: 'critical', child: Text('Critical')),
                DropdownMenuItem(value: 'high', child: Text('High')),
                DropdownMenuItem(value: 'medium', child: Text('Medium')),
                DropdownMenuItem(value: 'low', child: Text('Low')),
              ],
              onChanged: (value) {
                setState(() => _severityFilter = value);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPoliciesTab() {
    return PolicyManagementWidget(policies: _policies);
  }
}
