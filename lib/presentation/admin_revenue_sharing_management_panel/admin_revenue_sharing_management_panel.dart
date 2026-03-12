import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../services/revenue_share_service.dart';
import '../../widgets/custom_app_bar.dart';
import './widgets/country_configuration_matrix_widget.dart';
import './widgets/bulk_update_tools_widget.dart';
import './widgets/preset_templates_widget.dart';
import './widgets/split_history_audit_widget.dart';
import './widgets/revenue_overview_header_widget.dart';
import './widgets/ai_split_recommendation_widget.dart';
import '../../widgets/error_boundary_wrapper.dart';
import '../../widgets/shimmer_skeleton_loader.dart';

/// Admin Revenue Sharing Management Panel
/// Comprehensive country-based revenue split configuration with real-time validation
/// and bulk management capabilities for global creator monetization optimization.
class AdminRevenueSharingManagementPanel extends StatefulWidget {
  const AdminRevenueSharingManagementPanel({super.key});

  @override
  State<AdminRevenueSharingManagementPanel> createState() =>
      _AdminRevenueSharingManagementPanelState();
}

class _AdminRevenueSharingManagementPanelState
    extends State<AdminRevenueSharingManagementPanel>
    with SingleTickerProviderStateMixin {
  final RevenueShareService _revenueService = RevenueShareService.instance;

  late TabController _tabController;
  StreamSubscription? _revenueSplitsSubscription;
  List<Map<String, dynamic>> _revenueSplits = [];
  Map<String, dynamic> _overviewMetrics = {};
  bool _isLoading = true;
  final String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _setupRealtimeSubscription();
    _loadOverviewMetrics();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _revenueSplitsSubscription?.cancel();
    super.dispose();
  }

  void _setupRealtimeSubscription() {
    _revenueSplitsSubscription = _revenueService.streamRevenueSplits().listen((
      splits,
    ) {
      if (mounted) {
        setState(() {
          _revenueSplits = splits;
          _isLoading = false;
        });
      }
    });
  }

  Future<void> _loadOverviewMetrics() async {
    final metrics = await _revenueService.getSplitEffectivenessMetrics();
    if (mounted) {
      setState(() => _overviewMetrics = metrics);
    }
  }

  Future<void> _refreshData() async {
    setState(() => _isLoading = true);
    await _loadOverviewMetrics();
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return ErrorBoundaryWrapper(
      screenName: 'AdminRevenueSharingManagementPanel',
      onRetry: _refreshData,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: CustomAppBar(
          title: 'Revenue Sharing Management',
          actions: [
            IconButton(
              icon: Icon(Icons.refresh, size: 20.sp),
              onPressed: _refreshData,
            ),
          ],
        ),
        body: _isLoading
            ? const SkeletonDashboard()
            : SingleChildScrollView(
                child: Column(
                  children: [
                    RevenueOverviewHeaderWidget(metrics: _overviewMetrics),
                    SizedBox(height: 2.h),
                    Container(
                      color: Colors.white,
                      child: TabBar(
                        controller: _tabController,
                        isScrollable: true,
                        labelColor: Theme.of(context).primaryColor,
                        unselectedLabelColor: Colors.grey[600],
                        indicatorColor: Theme.of(context).primaryColor,
                        labelStyle: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                        ),
                        tabs: const [
                          Tab(text: 'Country Configuration'),
                          Tab(text: 'Bulk Update Tools'),
                          Tab(text: 'Preset Templates'),
                          Tab(text: 'Split History'),
                          Tab(text: 'AI Recommendations'),
                        ],
                      ),
                    ),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          CountryConfigurationMatrixWidget(
                            revenueSplits: _revenueSplits,
                            onUpdate: _refreshData,
                          ),
                          BulkUpdateToolsWidget(onUpdate: _refreshData),
                          PresetTemplatesWidget(onUpdate: _refreshData),
                          SplitHistoryAuditWidget(),
                          AISplitRecommendationWidget(
                            revenueSplits: _revenueSplits,
                            onApply: _refreshData,
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
}
