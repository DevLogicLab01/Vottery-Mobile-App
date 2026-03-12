import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/age_verification_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/error_boundary_wrapper.dart';
import './widgets/yoti_integration_panel_widget.dart';
import './widgets/waterfall_verification_workflow_widget.dart';
import './widgets/election_creator_controls_widget.dart';
import './widgets/compliance_dashboard_widget.dart';
import './widgets/verification_analytics_widget.dart';
import './widgets/data_minimization_panel_widget.dart';

/// Age Verification Control Center
/// Implements Yoti SDK integration with AI-powered facial age estimation
class AgeVerificationControlCenter extends StatefulWidget {
  const AgeVerificationControlCenter({super.key});

  @override
  State<AgeVerificationControlCenter> createState() =>
      _AgeVerificationControlCenterState();
}

class _AgeVerificationControlCenterState
    extends State<AgeVerificationControlCenter>
    with SingleTickerProviderStateMixin {
  final AgeVerificationService _verificationService =
      AgeVerificationService.instance;
  late TabController _tabController;

  Map<String, dynamic> _complianceReport = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final report = await _verificationService.getComplianceReport();

    setState(() {
      _complianceReport = report;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ErrorBoundaryWrapper(
      screenName: 'Age Verification Control Center',
      child: Scaffold(
        backgroundColor: AppTheme.backgroundLight,
        appBar: CustomAppBar(
          title: 'Age Verification Control',
          variant: CustomAppBarVariant.withBack,
        ),
        body: Column(
          children: [
            // Verification Status Overview
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.purple.shade700, Colors.purple.shade900],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: _isLoading
                  ? Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    )
                  : Column(
                      children: [
                        Text(
                          'Yoti SDK Integration',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildMetricCard(
                              'Active Verifications',
                              '${_complianceReport['active_verifications'] ?? 0}',
                              Icons.verified_user,
                            ),
                            _buildMetricCard(
                              'Success Rate',
                              '${_complianceReport['success_rate'] ?? 0}%',
                              Icons.check_circle,
                            ),
                            _buildMetricCard(
                              'ISO Compliant',
                              _complianceReport['iso_compliant'] == true
                                  ? 'Yes'
                                  : 'No',
                              Icons.security,
                            ),
                          ],
                        ),
                      ],
                    ),
            ),

            // Tab Navigation
            Container(
              color: Colors.white,
              child: TabBar(
                controller: _tabController,
                isScrollable: true,
                labelColor: Colors.purple.shade700,
                unselectedLabelColor: Colors.grey,
                indicatorColor: Colors.purple.shade700,
                labelStyle: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                ),
                tabs: const [
                  Tab(text: 'Yoti Integration'),
                  Tab(text: 'Waterfall Workflow'),
                  Tab(text: 'Creator Controls'),
                  Tab(text: 'Compliance'),
                  Tab(text: 'Analytics'),
                  Tab(text: 'Data Minimization'),
                ],
              ),
            ),

            // Tab Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: const [
                  YotiIntegrationPanelWidget(),
                  WaterfallVerificationWorkflowWidget(),
                  ElectionCreatorControlsWidget(),
                  ComplianceDashboardWidget(),
                  VerificationAnalyticsWidget(),
                  DataMinimizationPanelWidget(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 20.sp),
        SizedBox(height: 1.h),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: 14.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(color: Colors.white70, fontSize: 10.sp),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
