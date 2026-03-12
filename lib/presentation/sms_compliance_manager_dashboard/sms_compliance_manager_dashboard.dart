import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../services/sms_compliance_service.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/error_boundary_wrapper.dart';
import '../../theme/app_theme.dart';
import './widgets/consent_management_widget.dart';
import './widgets/suppression_list_widget.dart';
import './widgets/compliance_reports_widget.dart';
import './widgets/audit_log_widget.dart';

/// SMS Compliance Manager Dashboard
/// Comprehensive GDPR/TCPA compliance tracking with consent management,
/// opt-out lists, retention policies, and automated compliance reporting
class SMSComplianceManagerDashboard extends StatefulWidget {
  const SMSComplianceManagerDashboard({super.key});

  @override
  State<SMSComplianceManagerDashboard> createState() =>
      _SMSComplianceManagerDashboardState();
}

class _SMSComplianceManagerDashboardState
    extends State<SMSComplianceManagerDashboard>
    with SingleTickerProviderStateMixin {
  final SMSComplianceService _complianceService = SMSComplianceService.instance;

  late TabController _tabController;

  Map<String, dynamic> _complianceMetrics = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadComplianceMetrics();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadComplianceMetrics() async {
    setState(() => _isLoading = true);

    final report = await _complianceService.generateComplianceReport();

    if (mounted) {
      setState(() {
        _complianceMetrics = report;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ErrorBoundaryWrapper(
      screenName: 'SMS Compliance Manager',
      child: Scaffold(
        backgroundColor: AppTheme.backgroundLight,
        appBar: CustomAppBar(
          title: 'SMS Compliance Manager',
          variant: CustomAppBarVariant.withBack,
        ),
        body: Column(
          children: [
            _buildMetricsHeader(),
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: const [
                  ConsentManagementWidget(),
                  SuppressionListWidget(),
                  ComplianceReportsWidget(),
                  AuditLogWidget(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricsHeader() {
    if (_isLoading) {
      return Container(
        padding: EdgeInsets.all(3.w),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    final consentMetrics = _complianceMetrics['consent_metrics'] ?? {};
    final complianceScore = _complianceMetrics['compliance_score'] ?? 0;

    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: AppTheme.cardLight,
        border: Border(bottom: BorderSide(color: AppTheme.borderLight, width: 1)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'Compliance Score',
                  '$complianceScore/100',
                  _getScoreColor(complianceScore),
                  Icons.verified_user,
                ),
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: _buildMetricCard(
                  'Opt-In Rate',
                  '${consentMetrics['opt_in_rate'] ?? '0'}%',
                  Colors.green,
                  Icons.check_circle,
                ),
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: _buildMetricCard(
                  'Opt-Out Rate',
                  '${consentMetrics['opt_out_rate'] ?? '0'}%',
                  Colors.orange,
                  Icons.cancel,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(
    String label,
    String value,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: EdgeInsets.all(2.w),
      decoration: BoxDecoration(
        color: AppTheme.backgroundLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20.sp),
          SizedBox(height: 1.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(height: 0.5.h),
          Text(
            label,
            style: TextStyle(fontSize: 11.sp, color: AppTheme.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardLight,
        border: Border(bottom: BorderSide(color: AppTheme.borderLight, width: 1)),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: AppTheme.primaryLight,
        unselectedLabelColor: AppTheme.textSecondary,
        indicatorColor: AppTheme.primaryLight,
        labelStyle: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600),
        unselectedLabelStyle: TextStyle(fontSize: 12.sp),
        tabs: const [
          Tab(text: 'Consent'),
          Tab(text: 'Suppression'),
          Tab(text: 'Reports'),
          Tab(text: 'Audit Log'),
        ],
      ),
    );
  }

  Color _getScoreColor(int score) {
    if (score >= 90) return Colors.green;
    if (score >= 70) return Colors.orange;
    return Colors.red;
  }
}