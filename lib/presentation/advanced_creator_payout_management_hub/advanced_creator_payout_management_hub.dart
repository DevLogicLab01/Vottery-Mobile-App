import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/creator_monetization_service.dart';
import '../../services/currency_exchange_service.dart';
import '../../services/multi_currency_settlement_service.dart';
import '../../services/reconciliation_service.dart';
import '../../services/stripe_connect_service.dart';
import '../../services/tax_compliance_service.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/error_boundary_wrapper.dart';
import '../../widgets/shimmer_skeleton_loader.dart';
import './widgets/automated_payout_scheduling_widget.dart';
import './widgets/multi_zone_currency_conversion_widget.dart';
import './widgets/settlement_reconciliation_dashboard_widget.dart';
import './widgets/tax_compliance_tracking_widget.dart';

/// Advanced Creator Payout Management Hub
/// Comprehensive monetization oversight with automated scheduling,
/// multi-zone currency support, tax compliance, and settlement reconciliation
class AdvancedCreatorPayoutManagementHub extends StatefulWidget {
  const AdvancedCreatorPayoutManagementHub({super.key});

  @override
  State<AdvancedCreatorPayoutManagementHub> createState() =>
      _AdvancedCreatorPayoutManagementHubState();
}

class _AdvancedCreatorPayoutManagementHubState
    extends State<AdvancedCreatorPayoutManagementHub>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final CreatorMonetizationService _monetizationService =
      CreatorMonetizationService.instance;
  final MultiCurrencySettlementService _settlementService =
      MultiCurrencySettlementService.instance;
  final TaxComplianceService _taxService = TaxComplianceService.instance;
  final StripeConnectService _stripeService = StripeConnectService.instance;
  final CurrencyExchangeService _currencyService =
      CurrencyExchangeService.instance;
  final ReconciliationService _reconciliationService =
      ReconciliationService.instance;

  bool _isLoading = true;
  Map<String, dynamic> _payoutSchedule = {};
  Map<String, double> _exchangeRates = {};
  Map<String, dynamic> _taxComplianceStatus = {};
  Map<String, dynamic> _reconciliationData = {};
  Map<String, dynamic> _earningsSummary = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadDashboardData();
    _currencyService.startAutoRefresh();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _currencyService.stopAutoRefresh();
    super.dispose();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);

    try {
      final results = await Future.wait([
        _stripeService.getPayoutSchedule(),
        _currencyService.getExchangeRates(),
        _taxService.getComplianceStatus(),
        _reconciliationService.getReconciliationSummary(),
        _monetizationService.getCreatorEarnings(),
      ]);

      if (mounted) {
        setState(() {
          _payoutSchedule = results[0] ?? {};
          _exchangeRates = results[1] as Map<String, double>;
          _taxComplianceStatus = results[2] as Map<String, dynamic>;
          _reconciliationData = results[3] as Map<String, dynamic>;
          _earningsSummary = results[4] as Map<String, dynamic>;
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
      screenName: 'AdvancedCreatorPayoutManagementHub',
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
          title: 'Payout Management',
          actions: [
            IconButton(
              icon: Icon(Icons.refresh, size: 6.w),
              onPressed: _refreshData,
            ),
            IconButton(
              icon: Icon(Icons.help_outline, size: 6.w),
              onPressed: _showHelpDialog,
            ),
            SizedBox(width: 2.w),
          ],
        ),
        body: _isLoading
            ? const SkeletonDashboard()
            : RefreshIndicator(
                onRefresh: _refreshData,
                child: Column(
                  children: [
                    _buildEarningsHeader(),
                    _buildTabBar(),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          AutomatedPayoutSchedulingWidget(
                            currentSchedule: _payoutSchedule,
                            onScheduleUpdated: _refreshData,
                          ),
                          MultiZoneCurrencyConversionWidget(
                            exchangeRates: _exchangeRates,
                            earningsSummary: _earningsSummary,
                            onRefresh: _refreshData,
                          ),
                          TaxComplianceTrackingWidget(
                            complianceStatus: _taxComplianceStatus,
                            onRefresh: _refreshData,
                          ),
                          SettlementReconciliationDashboardWidget(
                            reconciliationData: _reconciliationData,
                            onRefresh: _refreshData,
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

  Widget _buildEarningsHeader() {
    final currencyFormat = NumberFormat.currency(
      symbol: r'$',
      decimalDigits: 2,
    );
    final totalEarnings = (_earningsSummary['total_earnings'] ?? 0.0) as num;
    final availableBalance =
        (_earningsSummary['available_balance'] ?? 0.0) as num;
    final pendingPayouts = (_earningsSummary['pending_payouts'] ?? 0.0) as num;

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
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildEarningsStat(
                'Total Earnings',
                currencyFormat.format(totalEarnings),
                Icons.account_balance_wallet,
              ),
              _buildEarningsStat(
                'Available',
                currencyFormat.format(availableBalance),
                Icons.attach_money,
              ),
              _buildEarningsStat(
                'Pending',
                currencyFormat.format(pendingPayouts),
                Icons.pending_actions,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEarningsStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 7.w),
        SizedBox(height: 1.h),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11.sp,
            color: Colors.white.withAlpha(230),
          ),
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: AppTheme.surfaceLight,
      child: TabBar(
        controller: _tabController,
        labelColor: AppTheme.primaryLight,
        unselectedLabelColor: AppTheme.textSecondaryLight,
        indicatorColor: AppTheme.primaryLight,
        isScrollable: true,
        labelStyle: GoogleFonts.inter(
          fontSize: 12.sp,
          fontWeight: FontWeight.w600,
        ),
        tabs: const [
          Tab(text: 'Scheduling'),
          Tab(text: 'Currency'),
          Tab(text: 'Tax Compliance'),
          Tab(text: 'Reconciliation'),
        ],
      ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Payout Management Help',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHelpItem(
                'Scheduling',
                'Configure automated payout frequency (Weekly, Bi-weekly, Monthly) with minimum \$10 threshold.',
              ),
              SizedBox(height: 2.h),
              _buildHelpItem(
                'Currency',
                'View real-time exchange rates across 8 purchasing power zones with automatic USD conversion.',
              ),
              SizedBox(height: 2.h),
              _buildHelpItem(
                'Tax Compliance',
                'Upload W-9 (US) or W-8BEN (International) forms with signature capture for tax compliance.',
              ),
              SizedBox(height: 2.h),
              _buildHelpItem(
                'Reconciliation',
                'Track Stripe and Trolley payouts with automatic transaction matching and discrepancy detection.',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Got it'),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpItem(String title, String description) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 13.sp,
          ),
        ),
        SizedBox(height: 0.5.h),
        Text(
          description,
          style: GoogleFonts.inter(
            fontSize: 11.sp,
            color: AppTheme.textSecondaryLight,
          ),
        ),
      ],
    );
  }
}
