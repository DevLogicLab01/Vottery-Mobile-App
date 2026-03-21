import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../services/business_intelligence_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/error_boundary_wrapper.dart';

class AutomatedExecutiveReportingClaudeIntelligenceHub extends StatefulWidget {
  const AutomatedExecutiveReportingClaudeIntelligenceHub({super.key});

  @override
  State<AutomatedExecutiveReportingClaudeIntelligenceHub> createState() =>
      _AutomatedExecutiveReportingClaudeIntelligenceHubState();
}

class _AutomatedExecutiveReportingClaudeIntelligenceHubState
    extends State<AutomatedExecutiveReportingClaudeIntelligenceHub> {
  bool _isLoading = true;
  Map<String, dynamic> _predictiveInsights = {};
  Map<String, dynamic> _deliveryStats = {};
  String _selectedReportType = 'monthly';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        BusinessIntelligenceService.instance.getPredictiveInsights(),
        BusinessIntelligenceService.instance.getDeliveryStatistics(),
      ]);
      if (!mounted) return;
      setState(() {
        _predictiveInsights = results[0];
        _deliveryStats = results[1];
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ErrorBoundaryWrapper(
      screenName: 'AutomatedExecutiveReportingClaudeIntelligenceHub',
      onRetry: _loadData,
      child: Scaffold(
        backgroundColor: AppTheme.backgroundLight,
        appBar: CustomAppBar(
          title: 'Automated Executive Reporting',
          variant: CustomAppBarVariant.withBack,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadData,
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: EdgeInsets.all(4.w),
                children: [
                  _buildClaudeBriefCard(),
                  SizedBox(height: 2.h),
                  _buildDeliveryCard(),
                  SizedBox(height: 2.h),
                  _buildReportActionsCard(),
                ],
              ),
      ),
    );
  }

  Widget _buildClaudeBriefCard() {
    final growth = (_predictiveInsights['growth_forecast'] ?? 0.0).toDouble();
    final churn = (_predictiveInsights['churn_risk'] ?? 0.0).toDouble();
    final revenue = (_predictiveInsights['revenue_forecast'] ?? 0.0).toDouble();
    final brief =
        'Claude intelligence summary: forecast growth ${growth.toStringAsFixed(1)}%, '
        'churn risk ${churn.toStringAsFixed(1)}%, expected revenue \$${revenue.toStringAsFixed(0)}. '
        'Recommendation: prioritize churn interventions and high-engagement content cohorts this cycle.';

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, color: Colors.deepPurple),
              SizedBox(width: 2.w),
              Text(
                'Claude Intelligence Brief',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimaryLight,
                ),
              ),
            ],
          ),
          SizedBox(height: 1.5.h),
          Text(
            brief,
            style: TextStyle(
              fontSize: 11.sp,
              color: AppTheme.textSecondaryLight,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryCard() {
    final total = _deliveryStats['totalDeliveries'] ?? 0;
    final success = _deliveryStats['successfulDeliveries'] ?? 0;
    final failed = _deliveryStats['failedDeliveries'] ?? 0;
    final rate = _deliveryStats['deliveryRate']?.toString() ?? '0.00';

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Delivery Analytics',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          SizedBox(height: 1.h),
          Text('Total: $total'),
          Text('Delivered: $success'),
          Text('Failed: $failed'),
          Text('Success Rate: $rate%'),
        ],
      ),
    );
  }

  Widget _buildReportActionsCard() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Automated Report Actions',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          SizedBox(height: 1.h),
          DropdownButtonFormField<String>(
            initialValue: _selectedReportType,
            items: const [
              DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
              DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
              DropdownMenuItem(value: 'quarterly', child: Text('Quarterly')),
            ],
            onChanged: (value) {
              if (value == null) return;
              setState(() => _selectedReportType = value);
            },
          ),
          SizedBox(height: 1.5.h),
          ElevatedButton.icon(
            onPressed: _sendAutomatedReport,
            icon: const Icon(Icons.send),
            label: const Text('Generate & Deliver'),
          ),
        ],
      ),
    );
  }

  Future<void> _sendAutomatedReport() async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Sending $_selectedReportType intelligence report...')),
    );
    try {
      final groups = await BusinessIntelligenceService.instance.getStakeholderGroups();
      if (groups.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No active stakeholder groups found')),
        );
        return;
      }
      final result = await BusinessIntelligenceService.instance.sendExecutiveReport(
        reportType: _selectedReportType,
        stakeholderGroupId: groups.first['id'].toString(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result['success'] == true
                ? 'Report delivered successfully'
                : 'Delivery failed: ${result['error']}',
          ),
        ),
      );
      _loadData();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Delivery failed: $error')),
      );
    }
  }
}
