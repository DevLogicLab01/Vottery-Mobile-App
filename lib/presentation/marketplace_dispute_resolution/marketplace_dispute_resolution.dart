import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/marketplace_dispute_service.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/error_boundary_wrapper.dart';
import '../../widgets/shimmer_skeleton_loader.dart';
import './widgets/active_disputes_widget.dart';
import './widgets/ai_mediation_widget.dart';
import './widgets/refund_processing_widget.dart';
import './widgets/transaction_hold_widget.dart';

class MarketplaceDisputeResolution extends StatefulWidget {
  const MarketplaceDisputeResolution({super.key});

  @override
  State<MarketplaceDisputeResolution> createState() =>
      _MarketplaceDisputeResolutionState();
}

class _MarketplaceDisputeResolutionState
    extends State<MarketplaceDisputeResolution>
    with SingleTickerProviderStateMixin {
  final MarketplaceDisputeService _disputeService =
      MarketplaceDisputeService.instance;

  late TabController _tabController;
  bool _isLoading = true;

  List<Map<String, dynamic>> _activeDisputes = [];
  List<Map<String, dynamic>> _pendingRefunds = [];
  List<Map<String, dynamic>> _heldTransactions = [];
  Map<String, dynamic> _disputeStats = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadDisputeData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadDisputeData() async {
    setState(() => _isLoading = true);

    try {
      final results = await Future.wait([
        _disputeService.getActiveDisputes(),
        _disputeService.getPendingRefunds(),
        _disputeService.getHeldTransactions(),
        _disputeService.getDisputeStatistics(),
      ]);

      if (mounted) {
        setState(() {
          _activeDisputes = results[0] as List<Map<String, dynamic>>;
          _pendingRefunds = results[1] as List<Map<String, dynamic>>;
          _heldTransactions = results[2] as List<Map<String, dynamic>>;
          _disputeStats = results[3] as Map<String, dynamic>;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Load dispute data error: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ErrorBoundaryWrapper(
      screenName: 'MarketplaceDisputeResolution',
      onRetry: _loadDisputeData,
      child: Scaffold(
        backgroundColor: AppTheme.backgroundLight,
        appBar: CustomAppBar(
          leading: Padding(
            padding: EdgeInsets.only(left: 4.w),
            child: IconButton(
              icon: CustomIconWidget(
                iconName: 'arrow_back',
                size: 6.w,
                color: AppTheme.textPrimaryLight,
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          title: 'Dispute Resolution',
          actions: [
            IconButton(
              icon: CustomIconWidget(
                iconName: 'refresh',
                size: 6.w,
                color: AppTheme.textPrimaryLight,
              ),
              onPressed: _loadDisputeData,
            ),
            SizedBox(width: 2.w),
          ],
        ),
        body: _isLoading
            ? const SkeletonDashboard()
            : Column(
                children: [
                  _buildStatsHeader(),
                  _buildTabBar(),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        ActiveDisputesWidget(
                          disputes: _activeDisputes,
                          onRefresh: _loadDisputeData,
                        ),
                        AIMediationWidget(
                          disputes: _activeDisputes,
                          onRefresh: _loadDisputeData,
                        ),
                        TransactionHoldWidget(
                          heldTransactions: _heldTransactions,
                          onRefresh: _loadDisputeData,
                        ),
                        RefundProcessingWidget(
                          pendingRefunds: _pendingRefunds,
                          onRefresh: _loadDisputeData,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildStatsHeader() {
    final activeCount = _disputeStats['active_disputes'] ?? 0;
    final resolvedCount = _disputeStats['resolved_today'] ?? 0;
    final avgResolutionTime = _disputeStats['avg_resolution_hours'] ?? 0.0;

    return Container(
      padding: EdgeInsets.all(4.w),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'Active Disputes',
              activeCount.toString(),
              Icons.gavel,
              Colors.orange,
            ),
          ),
          SizedBox(width: 2.w),
          Expanded(
            child: _buildStatCard(
              'Resolved Today',
              resolvedCount.toString(),
              Icons.check_circle,
              Colors.green,
            ),
          ),
          SizedBox(width: 2.w),
          Expanded(
            child: _buildStatCard(
              'Avg Resolution',
              '${avgResolutionTime.toStringAsFixed(1)}h',
              Icons.timer,
              Colors.blue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(2.w),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 6.w),
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
            style: TextStyle(
              fontSize: 10.sp,
              color: AppTheme.textSecondaryLight,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        labelColor: AppTheme.primaryLight,
        unselectedLabelColor: AppTheme.textSecondaryLight,
        indicatorColor: AppTheme.primaryLight,
        labelStyle: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w600),
        isScrollable: true,
        tabs: const [
          Tab(text: 'Active Disputes'),
          Tab(text: 'AI Mediation'),
          Tab(text: 'Transaction Holds'),
          Tab(text: 'Refund Processing'),
        ],
      ),
    );
  }
}
