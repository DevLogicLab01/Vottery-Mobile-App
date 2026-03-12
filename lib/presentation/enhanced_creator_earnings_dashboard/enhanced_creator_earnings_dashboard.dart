import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/creator_earnings_service.dart';
import '../../services/marketplace_service.dart';
import '../../services/stripe_tax_service.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/enhanced_empty_state_widget.dart';
import '../../widgets/error_boundary_wrapper.dart';
import '../../widgets/shimmer_skeleton_loader.dart';
import './widgets/combined_analytics_widget.dart';
import './widgets/comprehensive_transaction_feed_widget.dart';
import './widgets/marketplace_revenue_widget.dart';
import './widgets/settlement_preview_enhanced_widget.dart';
import './widgets/tax_integration_panel_widget.dart';
import './widgets/unified_earnings_header_widget.dart';

/// Enhanced Creator Earnings Dashboard
/// Comprehensive marketplace revenue integration and unified tax compliance management
class EnhancedCreatorEarningsDashboard extends StatefulWidget {
  const EnhancedCreatorEarningsDashboard({super.key});

  @override
  State<EnhancedCreatorEarningsDashboard> createState() =>
      _EnhancedCreatorEarningsDashboardState();
}

class _EnhancedCreatorEarningsDashboardState
    extends State<EnhancedCreatorEarningsDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final CreatorEarningsService _earningsService =
      CreatorEarningsService.instance;
  final MarketplaceService _marketplaceService = MarketplaceService.instance;
  final StripeTaxService _taxService = StripeTaxService.instance;

  bool _isLoading = true;
  Map<String, dynamic> _earningsSummary = {};
  Map<String, dynamic> _marketplaceAnalytics = {};
  List<Map<String, dynamic>> _taxCalculations = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadDashboardData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);

    try {
      final results = await Future.wait([
        _earningsService.getEarningsSummary(),
        _marketplaceService.getMarketplaceAnalytics(),
        _taxService.getTaxCalculations(),
      ]);

      if (mounted) {
        setState(() {
          _earningsSummary = results[0] as Map<String, dynamic>;
          _marketplaceAnalytics = results[1] as Map<String, dynamic>;
          _taxCalculations = results[2] as List<Map<String, dynamic>>;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Load dashboard data error: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _refreshData() async {
    await _loadDashboardData();
  }

  @override
  Widget build(BuildContext context) {
    return ErrorBoundaryWrapper(
      screenName: 'EnhancedCreatorEarningsDashboard',
      onRetry: _loadDashboardData,
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
          title: 'Enhanced Earnings',
          actions: [
            IconButton(
              icon: CustomIconWidget(
                iconName: 'refresh',
                size: 6.w,
                color: AppTheme.primaryLight,
              ),
              onPressed: _refreshData,
            ),
            IconButton(
              icon: CustomIconWidget(
                iconName: 'download',
                size: 6.w,
                color: AppTheme.primaryLight,
              ),
              onPressed: _exportComprehensiveReport,
            ),
          ],
        ),
        body: _isLoading
            ? const SkeletonDashboard()
            : _earningsSummary.isEmpty
            ? NoEarningsEmptyState(
                onLearnMore: () {
                  // Navigate to creator academy
                },
              )
            : RefreshIndicator(
                onRefresh: _refreshData,
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(4.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Unified Earnings Header
                      UnifiedEarningsHeaderWidget(
                        earningsSummary: _earningsSummary,
                        marketplaceAnalytics: _marketplaceAnalytics,
                      ),
                      SizedBox(height: 3.h),

                      // Marketplace Revenue Breakdown
                      MarketplaceRevenueWidget(
                        marketplaceAnalytics: _marketplaceAnalytics,
                      ),
                      SizedBox(height: 3.h),

                      // Tax Integration Panel
                      TaxIntegrationPanelWidget(
                        taxCalculations: _taxCalculations,
                      ),
                      SizedBox(height: 3.h),

                      // Combined Analytics Tabs
                      Container(
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceLight,
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        child: Column(
                          children: [
                            TabBar(
                              controller: _tabController,
                              labelColor: AppTheme.primaryLight,
                              unselectedLabelColor: AppTheme.textSecondaryLight,
                              indicatorColor: AppTheme.primaryLight,
                              tabs: [
                                Tab(text: 'Analytics'),
                                Tab(text: 'Transactions'),
                                Tab(text: 'Settlement'),
                              ],
                            ),
                            SizedBox(
                              height: 50.h,
                              child: TabBarView(
                                controller: _tabController,
                                children: [
                                  CombinedAnalyticsWidget(),
                                  ComprehensiveTransactionFeedWidget(),
                                  SettlementPreviewEnhancedWidget(
                                    earningsSummary: _earningsSummary,
                                    taxCalculations: _taxCalculations,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Future<void> _exportComprehensiveReport() async {
    // Export comprehensive tax package with earnings breakdowns
    debugPrint('Exporting comprehensive report...');
  }
}
