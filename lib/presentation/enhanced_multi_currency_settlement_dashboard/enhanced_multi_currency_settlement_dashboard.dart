import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/currency_exchange_service.dart';
import '../../services/multi_currency_settlement_service.dart';
import '../../services/ga4_analytics_service.dart';
import '../../widgets/custom_app_bar.dart';
import '../../theme/app_theme.dart';
import './widgets/enhanced_zone_management_widget.dart';
import './widgets/enhanced_live_exchange_rates_widget.dart';
import './widgets/enhanced_payment_methods_widget.dart';
import './widgets/enhanced_withdrawal_form_widget.dart';
import './widgets/settlement_queue_widget.dart';
import './widgets/settlement_reconciliation_widget.dart';
import '../../widgets/error_boundary_wrapper.dart';
import '../../widgets/shimmer_skeleton_loader.dart';
import '../../widgets/enhanced_empty_state_widget.dart';

/// Enhanced Multi-Currency Settlement Dashboard with comprehensive 8-zone management,
/// real-time exchange rates, multi-payment methods, and advanced settlement tracking
class EnhancedMultiCurrencySettlementDashboard extends StatefulWidget {
  const EnhancedMultiCurrencySettlementDashboard({super.key});

  @override
  State<EnhancedMultiCurrencySettlementDashboard> createState() =>
      _EnhancedMultiCurrencySettlementDashboardState();
}

class _EnhancedMultiCurrencySettlementDashboardState
    extends State<EnhancedMultiCurrencySettlementDashboard>
    with SingleTickerProviderStateMixin {
  final MultiCurrencySettlementService _settlementService =
      MultiCurrencySettlementService.instance;
  final CurrencyExchangeService _currencyService =
      CurrencyExchangeService.instance;
  final GA4AnalyticsService _analytics = GA4AnalyticsService.instance;

  late TabController _tabController;
  bool _isLoading = true;
  Map<String, dynamic> _payoutSummary = {};
  Map<String, Map<String, dynamic>> _zoneStatus = {};
  Map<String, double> _exchangeRates = {};
  Map<String, double> _walletBalances = {};
  Map<String, String> _complianceStatus = {};
  List<Map<String, dynamic>> _settlementQueue = [];
  List<Map<String, dynamic>> _settlementHistory = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
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
        _settlementService.getPendingPayoutsSummary(),
        _settlementService.getZonePayoutStatus(),
        _currencyService.getExchangeRates(),
        _settlementService.getMultiCurrencyBalances(),
        _settlementService.getComplianceStatus(),
        _settlementService.getPayoutHistory(limit: 50),
      ]);

      setState(() {
        _payoutSummary = results[0] as Map<String, dynamic>;
        _zoneStatus = results[1] as Map<String, Map<String, dynamic>>;
        _exchangeRates = results[2] as Map<String, double>;
        _walletBalances = results[3] as Map<String, double>;
        _complianceStatus = results[4] as Map<String, String>;
        _settlementQueue = [];
        _settlementHistory = results[5] as List<Map<String, dynamic>>;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Load dashboard data error: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _refreshData() async {
    await _loadDashboardData();
  }

  void _showWithdrawalForm() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EnhancedWithdrawalFormWidget(
        zoneStatus: _zoneStatus,
        exchangeRates: _exchangeRates,
        complianceStatus: _complianceStatus,
        onSubmit: (data) async {
          final success = await _settlementService.submitWithdrawalRequest(
            amount: data['amount'],
            zone: data['zone'],
            paymentMethod: data['payment_method'],
            beneficiaryDetails: data['beneficiary_details'],
            taxDocumentUrl: data['tax_document_url'],
          );

          if (mounted) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  success
                      ? 'Withdrawal request submitted successfully'
                      : 'Failed to submit withdrawal request',
                ),
                backgroundColor: success
                    ? AppTheme.accentLight
                    : AppTheme.errorLight,
              ),
            );

            if (success) {
              await _analytics.trackWithdrawalInitiated(
                amount: data['amount'],
                zone: data['zone'],
                paymentMethod: data['payment_method'],
              );
              _refreshData();
            }
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ErrorBoundaryWrapper(
      screenName: 'EnhancedMultiCurrencySettlementDashboard',
      onRetry: _loadDashboardData,
      child: Scaffold(
        backgroundColor: theme.colorScheme.surface,
        appBar: CustomAppBar(
          title: 'Enhanced Settlement Dashboard',
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _refreshData,
            ),
          ],
        ),
        body: _isLoading
            ? const SkeletonDashboard()
            : _settlementHistory.isEmpty
            ? NoTransactionsEmptyState()
            : SingleChildScrollView(
                child: Column(
                  children: [
                    _buildSummaryHeader(theme),
                    TabBar(
                      controller: _tabController,
                      isScrollable: true,
                      labelColor: AppTheme.primaryLight,
                      unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
                      indicatorColor: AppTheme.primaryLight,
                      tabs: const [
                        Tab(text: 'Zones'),
                        Tab(text: 'Exchange Rates'),
                        Tab(text: 'Payment Methods'),
                        Tab(text: 'Settlement Queue'),
                        Tab(text: 'Reconciliation'),
                      ],
                    ),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          EnhancedZoneManagementWidget(
                            zoneStatus: _zoneStatus,
                            complianceStatus: _complianceStatus,
                            onRefresh: _refreshData,
                          ),
                          EnhancedLiveExchangeRatesWidget(
                            exchangeRates: _exchangeRates,
                            onRefresh: () async {
                              final rates = await _currencyService
                                  .getExchangeRates(forceRefresh: true);
                              setState(() => _exchangeRates = rates);
                            },
                          ),
                          EnhancedPaymentMethodsWidget(
                            walletBalances: _walletBalances,
                            exchangeRates: _exchangeRates,
                          ),
                          SettlementQueueWidget(
                            settlementQueue: _settlementQueue,
                            onRefresh: _refreshData,
                          ),
                          SettlementReconciliationWidget(
                            settlementHistory: _settlementHistory,
                            onRefresh: _refreshData,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _showWithdrawalForm,
          backgroundColor: AppTheme.primaryLight,
          icon: const Icon(Icons.add, color: Colors.white),
          label: Text(
            'New Withdrawal',
            style: GoogleFonts.inter(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryHeader(ThemeData theme) {
    final totalPending = _payoutSummary['total_pending'] ?? 0.0;
    final activeZones = _payoutSummary['active_zones'] ?? 0;
    final nextSettlement = _payoutSummary['next_settlement_date'] ?? 'N/A';

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.primaryLight.withValues(alpha: 0.1),
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildSummaryItem(
            theme,
            'Total Pending',
            '\$${totalPending.toStringAsFixed(2)}',
            Icons.account_balance_wallet,
          ),
          _buildSummaryItem(
            theme,
            'Active Zones',
            activeZones.toString(),
            Icons.public,
          ),
          _buildSummaryItem(
            theme,
            'Next Settlement',
            nextSettlement,
            Icons.schedule,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(
    ThemeData theme,
    String label,
    String value,
    IconData icon,
  ) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.primaryLight, size: 6.w),
        SizedBox(height: 0.5.h),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 14.sp,
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurface,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10.sp,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
