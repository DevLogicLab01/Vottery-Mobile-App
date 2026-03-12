import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/integration_management_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/error_boundary_wrapper.dart';
import '../../widgets/shimmer_skeleton_loader.dart';
import './widgets/budget_config_dialog_widget.dart';
import './widgets/cost_tracking_chart_widget.dart';
import './widgets/integration_service_card_widget.dart';

class IntegrationManagementPanel extends StatefulWidget {
  const IntegrationManagementPanel({super.key});

  @override
  State<IntegrationManagementPanel> createState() =>
      _IntegrationManagementPanelState();
}

class _IntegrationManagementPanelState
    extends State<IntegrationManagementPanel> {
  final IntegrationManagementService _integrationService =
      IntegrationManagementService.instance;

  StreamSubscription? _integrationsSubscription;
  List<Map<String, dynamic>> _allIntegrations = [];
  final Map<String, List<Map<String, dynamic>>> _integrationsByType = {};
  final Map<String, Map<String, dynamic>> _usageAnalytics = {};
  bool _isLoading = true;

  final List<String> _integrationTypes = [
    'ai_service',
    'payment',
    'communication',
    'advertising',
  ];

  @override
  void initState() {
    super.initState();
    _setupRealtimeSubscription();
  }

  @override
  void dispose() {
    _integrationsSubscription?.cancel();
    super.dispose();
  }

  void _setupRealtimeSubscription() {
    _integrationsSubscription = _integrationService.streamIntegrations().listen(
      (integrations) async {
        if (mounted) {
          setState(() {
            _allIntegrations = integrations;
            _organizeIntegrationsByType();
          });

          for (final integration in integrations) {
            final analytics = await _integrationService.getUsageAnalytics(
              integration['id'] as String,
            );
            if (mounted) {
              setState(() {
                _usageAnalytics[integration['id'] as String] = analytics;
              });
            }
          }

          if (mounted) {
            setState(() => _isLoading = false);
          }
        }
      },
    );
  }

  void _organizeIntegrationsByType() {
    _integrationsByType.clear();
    for (final type in _integrationTypes) {
      _integrationsByType[type] = _allIntegrations
          .where((i) => i['integration_type'] == type)
          .toList();
    }
  }

  Future<void> _handleIntegrationToggle({
    required String integrationId,
    required String integrationName,
    required bool currentStatus,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${currentStatus ? "Disable" : "Enable"} Integration'),
        content: Text(
          'Are you sure you want to ${currentStatus ? "disable" : "enable"} $integrationName?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: currentStatus ? Colors.red : Colors.green,
            ),
            child: Text(currentStatus ? 'Disable' : 'Enable'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final success = await _integrationService.updateIntegrationStatus(
      integrationId: integrationId,
      isEnabled: !currentStatus,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Integration ${!currentStatus ? "enabled" : "disabled"} successfully'
                : 'Failed to update integration',
          ),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  Future<void> _handleBudgetConfig(Map<String, dynamic> integration) async {
    final result = await showDialog<Map<String, double>>(
      context: context,
      builder: (context) => BudgetConfigDialogWidget(
        integrationName: integration['integration_name'] as String,
        currentWeeklyBudget:
            (integration['weekly_budget_cap'] as num?)?.toDouble() ?? 0.0,
        currentMonthlyBudget:
            (integration['monthly_budget_cap'] as num?)?.toDouble() ?? 0.0,
      ),
    );

    if (result == null) return;

    final success = await _integrationService.updateBudgetCaps(
      integrationId: integration['id'] as String,
      weeklyBudgetCap: result['weekly']!,
      monthlyBudgetCap: result['monthly']!,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Budget caps updated successfully'
                : 'Failed to update budget caps',
          ),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  void _showUsageDetails(Map<String, dynamic> integration) {
    final integrationId = integration['id'] as String;
    final analytics = _usageAnalytics[integrationId];

    if (analytics == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: 70.h,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${integration['integration_name']} Usage',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(4.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildAnalyticsStats(analytics),
                    SizedBox(height: 3.h),
                    CostTrackingChartWidget(
                      dailyBreakdown: List<Map<String, dynamic>>.from(
                        analytics['daily_breakdown'] ?? [],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticsStats(Map<String, dynamic> analytics) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Total Calls',
            analytics['total_calls'].toString(),
            Icons.api,
            Colors.blue,
          ),
        ),
        SizedBox(width: 2.w),
        Expanded(
          child: _buildStatCard(
            'Total Cost',
            '\$${(analytics['total_cost'] as num).toStringAsFixed(2)}',
            Icons.attach_money,
            Colors.green,
          ),
        ),
        SizedBox(width: 2.w),
        Expanded(
          child: _buildStatCard(
            'Avg Time',
            '${analytics['avg_response_time']}ms',
            Icons.speed,
            Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24.sp),
          SizedBox(height: 1.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 10.sp, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ErrorBoundaryWrapper(
      screenName: 'IntegrationManagementPanel',
      onRetry: () {
        setState(() => _isLoading = true);
        _setupRealtimeSubscription();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Text('Integration Management'),
          actions: [
            IconButton(
              icon: Icon(Icons.refresh, size: 24.sp),
              onPressed: () {
                setState(() => _isLoading = true);
                _setupRealtimeSubscription();
              },
            ),
          ],
        ),
        body: _isLoading
            ? const SkeletonDashboard()
            : SingleChildScrollView(
                padding: EdgeInsets.all(4.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildOverviewStats(),
                    SizedBox(height: 3.h),
                    ..._integrationTypes.map((type) {
                      final integrations = _integrationsByType[type] ?? [];
                      if (integrations.isEmpty) return const SizedBox.shrink();

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildTypeHeader(type),
                          SizedBox(height: 2.h),
                          ...integrations.map(
                            (integration) => IntegrationServiceCardWidget(
                              integration: integration,
                              analytics:
                                  _usageAnalytics[integration['id'] as String],
                              onToggle: _handleIntegrationToggle,
                              onBudgetConfig: _handleBudgetConfig,
                              onViewDetails: _showUsageDetails,
                            ),
                          ),
                          SizedBox(height: 3.h),
                        ],
                      );
                    }),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildOverviewStats() {
    final activeIntegrations = _allIntegrations
        .where((i) => i['is_enabled'] == true)
        .length;
    final totalCost = _allIntegrations.fold<double>(
      0,
      (sum, i) =>
          sum + ((i['current_monthly_usage'] as num?)?.toDouble() ?? 0.0),
    );
    final avgUptime = _allIntegrations.isEmpty
        ? 0.0
        : _allIntegrations.fold<double>(
                0,
                (sum, i) =>
                    sum + ((i['uptime_percentage'] as num?)?.toDouble() ?? 0.0),
              ) /
              _allIntegrations.length;

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.vibrantYellow,
            AppTheme.vibrantYellow.withAlpha(204),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(26),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildOverviewItem(
            'Active',
            '$activeIntegrations/${_allIntegrations.length}',
            Icons.power_settings_new,
          ),
          _buildOverviewItem(
            'Monthly Cost',
            '\$${totalCost.toStringAsFixed(2)}',
            Icons.attach_money,
          ),
          _buildOverviewItem(
            'Avg Uptime',
            '${avgUptime.toStringAsFixed(1)}%',
            Icons.trending_up,
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 28.sp),
        SizedBox(height: 0.5.h),
        Text(
          value,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 11.sp, color: Colors.white),
        ),
      ],
    );
  }

  Widget _buildTypeHeader(String type) {
    final displayName = type
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');

    IconData icon;
    Color color;

    switch (type) {
      case 'ai_service':
        icon = Icons.psychology;
        color = Colors.purple;
        break;
      case 'payment':
        icon = Icons.payment;
        color = Colors.green;
        break;
      case 'communication':
        icon = Icons.message;
        color = Colors.blue;
        break;
      case 'advertising':
        icon = Icons.ads_click;
        color = Colors.orange;
        break;
      default:
        icon = Icons.category;
        color = Colors.grey;
    }

    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(2.w),
          decoration: BoxDecoration(
            color: color.withAlpha(26),
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Icon(icon, color: color, size: 20.sp),
        ),
        SizedBox(width: 3.w),
        Text(
          displayName,
          style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}
