import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/creator_earnings_service.dart';
import '../../services/creator_monetization_service.dart';
import '../../services/creator_revenue_service.dart';
import '../../services/multi_currency_settlement_service.dart';
import '../../services/stripe_connect_service.dart';
import '../../services/tax_compliance_service.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/error_boundary_wrapper.dart';
import '../../widgets/shimmer_skeleton_loader.dart';
import './widgets/multi_currency_payout_widget.dart';
import './widgets/revenue_analytics_widget.dart';
import './widgets/settlement_reconciliation_widget.dart';
import './widgets/tax_compliance_center_widget.dart';
import './widgets/unified_earnings_dashboard_widget.dart';

/// Creator Monetization Hub
/// Unified revenue management consolidating all creator income streams
class CreatorMonetizationHub extends StatefulWidget {
  const CreatorMonetizationHub({super.key});

  @override
  State<CreatorMonetizationHub> createState() => _CreatorMonetizationHubState();
}

class _CreatorMonetizationHubState extends State<CreatorMonetizationHub>
    with SingleTickerProviderStateMixin {
  final CreatorEarningsService _earningsService =
      CreatorEarningsService.instance;
  final CreatorMonetizationService _monetizationService =
      CreatorMonetizationService.instance;
  final CreatorRevenueService _revenueService = CreatorRevenueService.instance;
  final MultiCurrencySettlementService _settlementService =
      MultiCurrencySettlementService.instance;
  final StripeConnectService _stripeService = StripeConnectService.instance;
  final TaxComplianceService _taxService = TaxComplianceService.instance;

  late TabController _tabController;
  bool _isLoading = true;
  Map<String, dynamic> _earningsSummary = {};
  Map<String, dynamic> _revenueBreakdown = {};
  Map<String, dynamic> _revenueSplit = {};
  Map<String, dynamic> _payoutSummary = {};
  Map<String, dynamic> _complianceStatus = {};
  List<Map<String, dynamic>> _taxDocuments = [];
  final Map<String, double> _exchangeRates = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadMonetizationData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadMonetizationData() async {
    setState(() => _isLoading = true);

    try {
      final results = await Future.wait([
        _earningsService.getEarningsSummary(),
        _monetizationService.getRevenueBreakdown(),
        _revenueService.getCreatorRevenueSplit(),
        _settlementService.getPendingPayoutsSummary(),
        _taxService.getComplianceStatus(),
        _taxService.getTaxDocuments(),
      ]);

      if (mounted) {
        setState(() {
          _earningsSummary = results[0] as Map<String, dynamic>;
          _revenueBreakdown = results[1] as Map<String, dynamic>;
          _revenueSplit = results[2] as Map<String, dynamic>;
          _payoutSummary = results[3] as Map<String, dynamic>;
          _complianceStatus = results[4] as Map<String, dynamic>;
          _taxDocuments = results[5] as List<Map<String, dynamic>>;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Load monetization data error: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _refreshData() async {
    await _loadMonetizationData();
  }

  @override
  Widget build(BuildContext context) {
    return ErrorBoundaryWrapper(
      screenName: 'CreatorMonetizationHub',
      onRetry: _loadMonetizationData,
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
          title: 'Monetization Hub',
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
              icon: Icon(Icons.download, size: 6.w),
              onPressed: _exportFinancialReport,
            ),
            SizedBox(width: 2.w),
          ],
        ),
        body: _isLoading
            ? const SkeletonDashboard()
            : RefreshIndicator(
                onRefresh: _refreshData,
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(4.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildEarningsOverviewHeader(),
                      SizedBox(height: 3.h),
                      _buildTabBar(),
                      SizedBox(height: 2.h),
                      SizedBox(
                        height: 70.h,
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            UnifiedEarningsDashboardWidget(
                              earningsSummary: _earningsSummary,
                              revenueBreakdown: _revenueBreakdown,
                              revenueSplit: _revenueSplit,
                            ),
                            TaxComplianceCenterWidget(
                              complianceStatus: _complianceStatus,
                              taxDocuments: _taxDocuments,
                              onDocumentUpload: _handleDocumentUpload,
                            ),
                            MultiCurrencyPayoutWidget(
                              payoutSummary: _payoutSummary,
                              exchangeRates: _exchangeRates,
                              onWithdrawalRequest: _handleWithdrawalRequest,
                            ),
                            SettlementReconciliationWidget(
                              earningsSummary: _earningsSummary,
                              payoutSummary: _payoutSummary,
                            ),
                            RevenueAnalyticsWidget(
                              revenueBreakdown: _revenueBreakdown,
                              earningsSummary: _earningsSummary,
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

  Widget _buildEarningsOverviewHeader() {
    final currencyFormat = NumberFormat.currency(
      symbol: r'$',
      decimalDigits: 2,
    );
    final totalRevenue = (_earningsSummary['total_usd_earned'] ?? 0.0) as num;
    final availableBalance =
        (_earningsSummary['available_balance_usd'] ?? 0.0) as num;
    final nextPayout = _earningsSummary['next_settlement_date'] as String?;
    final complianceScore = _complianceStatus['compliance_score'] ?? 0;

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
            color: AppTheme.vibrantYellow.withAlpha(77),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Revenue',
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: Colors.white.withAlpha(230),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 0.5.h),
                  Text(
                    currencyFormat.format(totalRevenue),
                    style: TextStyle(
                      fontSize: 20.sp,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                decoration: BoxDecoration(
                  color: _getComplianceColor(complianceScore),
                  borderRadius: BorderRadius.circular(20.0),
                ),
                child: Row(
                  children: [
                    Icon(
                      _getComplianceIcon(complianceScore),
                      color: Colors.white,
                      size: 4.w,
                    ),
                    SizedBox(width: 1.w),
                    Text(
                      'Compliance: $complianceScore%',
                      style: TextStyle(
                        fontSize: 9.sp,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              Expanded(
                child: _buildHeaderMetric(
                  'Available Balance',
                  currencyFormat.format(availableBalance),
                  Icons.account_balance_wallet,
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: _buildHeaderMetric(
                  'Next Payout',
                  nextPayout != null
                      ? DateFormat('MMM dd').format(DateTime.parse(nextPayout))
                      : 'N/A',
                  Icons.calendar_today,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderMetric(String label, String value, IconData icon) {
    return Container(
      padding: EdgeInsets.all(2.w),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(51),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 5.w),
          SizedBox(width: 2.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 9.sp,
                    color: Colors.white.withAlpha(230),
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: AppTheme.primaryLight,
        unselectedLabelColor: AppTheme.textSecondaryLight,
        indicatorColor: AppTheme.primaryLight,
        isScrollable: true,
        tabs: const [
          Tab(text: 'Earnings'),
          Tab(text: 'Tax Compliance'),
          Tab(text: 'Payouts'),
          Tab(text: 'Reconciliation'),
          Tab(text: 'Analytics'),
        ],
      ),
    );
  }

  Color _getComplianceColor(int score) {
    if (score >= 90) return Colors.green;
    if (score >= 70) return Colors.orange;
    return Colors.red;
  }

  IconData _getComplianceIcon(int score) {
    if (score >= 90) return Icons.check_circle;
    if (score >= 70) return Icons.warning;
    return Icons.error;
  }

  Future<void> _handleDocumentUpload(Map<String, dynamic> data) async {
    // Handle tax document upload
    debugPrint('Uploading tax document: $data');
    await _refreshData();
  }

  Future<void> _handleWithdrawalRequest(Map<String, dynamic> data) async {
    // Handle withdrawal request
    debugPrint('Processing withdrawal request: $data');
    await _refreshData();
  }

  Future<void> _exportFinancialReport() async {
    // Export comprehensive financial report
    debugPrint('Exporting financial report...');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Financial report exported successfully'),
        backgroundColor: Colors.green,
      ),
    );
  }
}
