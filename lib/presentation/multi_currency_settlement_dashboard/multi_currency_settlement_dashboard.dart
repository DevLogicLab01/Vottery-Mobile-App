import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/currency_exchange_service.dart';
import '../../services/multi_currency_settlement_service.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/enhanced_empty_state_widget.dart';
import '../../widgets/error_boundary_wrapper.dart';
import '../../widgets/shimmer_skeleton_loader.dart';
import './widgets/compliance_status_widget.dart';
import './widgets/live_currency_rates_widget.dart';
import './widgets/multi_currency_wallet_widget.dart';
import './widgets/payout_history_widget.dart';
import './widgets/settlement_timeline_widget.dart';
import './widgets/withdrawal_request_form_widget.dart';
import './widgets/zone_overview_widget.dart';

/// Multi-Currency Settlement Dashboard for international payout management
/// across 8 purchasing power zones with real-time currency conversion
class MultiCurrencySettlementDashboard extends StatefulWidget {
  const MultiCurrencySettlementDashboard({super.key});

  @override
  State<MultiCurrencySettlementDashboard> createState() =>
      _MultiCurrencySettlementDashboardState();
}

class _MultiCurrencySettlementDashboardState
    extends State<MultiCurrencySettlementDashboard> {
  final MultiCurrencySettlementService _settlementService =
      MultiCurrencySettlementService.instance;
  final CurrencyExchangeService _currencyService =
      CurrencyExchangeService.instance;

  bool _isLoading = true;
  Map<String, dynamic> _payoutSummary = {};
  Map<String, Map<String, dynamic>> _zoneStatus = {};
  Map<String, double> _exchangeRates = {};
  Map<String, double> _walletBalances = {};
  Map<String, String> _complianceStatus = {};
  List<Map<String, dynamic>> _payoutHistory = [];

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
    _currencyService.startAutoRefresh();
  }

  @override
  void dispose() {
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
        _settlementService.getPayoutHistory(limit: 20),
      ]);

      setState(() {
        _payoutSummary = results[0] as Map<String, dynamic>;
        _zoneStatus = results[1] as Map<String, Map<String, dynamic>>;
        _exchangeRates = results[2] as Map<String, double>;
        _walletBalances = results[3] as Map<String, double>;
        _complianceStatus = results[4] as Map<String, String>;
        _payoutHistory = results[5] as List<Map<String, dynamic>>;
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
      builder: (context) => WithdrawalRequestFormWidget(
        onSubmit: (data) async {
          final success = await _settlementService.submitWithdrawalRequest(
            amount: data['amount'],
            zone: data['zone'],
            paymentMethod: data['payment_method'],
            beneficiaryDetails: data['beneficiary_details'],
            taxDocumentUrl: data['tax_document_url'],
          );

          if (success && mounted) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Withdrawal request submitted successfully'),
                backgroundColor: Colors.green,
              ),
            );
            _refreshData();
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ErrorBoundaryWrapper(
      screenName: 'MultiCurrencySettlementDashboard',
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
          title: 'Multi-Currency Settlement',
          actions: [
            IconButton(
              icon: Icon(Icons.refresh, size: 6.w),
              onPressed: _refreshData,
            ),
            SizedBox(width: 2.w),
          ],
        ),
        body: _isLoading
            ? const SkeletonDashboard()
            : _payoutHistory.isEmpty
            ? NoTransactionsEmptyState()
            : RefreshIndicator(
                onRefresh: _refreshData,
                color: AppTheme.vibrantYellow,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.all(4.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSummaryHeader(),
                      SizedBox(height: 3.h),
                      ZoneOverviewWidget(
                        zoneStatus: _zoneStatus,
                        complianceStatus: _complianceStatus,
                      ),
                      SizedBox(height: 3.h),
                      LiveCurrencyRatesWidget(
                        exchangeRates: _exchangeRates,
                        onRefresh: () async {
                          final rates = await _currencyService.getExchangeRates(
                            forceRefresh: true,
                          );
                          setState(() => _exchangeRates = rates);
                        },
                      ),
                      SizedBox(height: 3.h),
                      SettlementTimelineWidget(),
                      SizedBox(height: 3.h),
                      MultiCurrencyWalletWidget(
                        balances: _walletBalances,
                        exchangeRates: _exchangeRates,
                      ),
                      SizedBox(height: 3.h),
                      ComplianceStatusWidget(
                        complianceStatus: _complianceStatus,
                      ),
                      SizedBox(height: 3.h),
                      PayoutHistoryWidget(
                        payoutHistory: _payoutHistory,
                        onFilterApplied: (filters) async {
                          final filtered = await _settlementService
                              .getPayoutHistory(
                                startDate: filters['start_date'],
                                endDate: filters['end_date'],
                                zone: filters['zone'],
                                minAmount: filters['min_amount'],
                                maxAmount: filters['max_amount'],
                                status: filters['status'],
                                paymentMethod: filters['payment_method'],
                              );
                          setState(() => _payoutHistory = filtered);
                        },
                      ),
                      SizedBox(height: 10.h),
                    ],
                  ),
                ),
              ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _showWithdrawalForm,
          backgroundColor: AppTheme.vibrantYellow,
          icon: const Icon(Icons.add, color: Colors.white),
          label: Text(
            'New Withdrawal',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 12.sp,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryHeader() {
    final currencyFormat = NumberFormat.currency(
      symbol: r'$',
      decimalDigits: 2,
    );
    final dateFormat = DateFormat('MMM dd, yyyy');

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
          Text(
            'Settlement Status',
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 2.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Pending',
                    style: GoogleFonts.inter(
                      fontSize: 11.sp,
                      color: Colors.white.withAlpha(230),
                    ),
                  ),
                  Text(
                    currencyFormat.format(
                      _payoutSummary['total_pending'] ?? 0.0,
                    ),
                    style: GoogleFonts.inter(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Active Zones',
                    style: GoogleFonts.inter(
                      fontSize: 11.sp,
                      color: Colors.white.withAlpha(230),
                    ),
                  ),
                  Text(
                    '${_payoutSummary['active_zones'] ?? 0}/8',
                    style: GoogleFonts.inter(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(51),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.calendar_today, size: 4.w, color: Colors.white),
                SizedBox(width: 2.w),
                Text(
                  'Next Settlement: ${dateFormat.format(_payoutSummary['next_settlement_date'] ?? DateTime.now())}',
                  style: GoogleFonts.inter(
                    fontSize: 11.sp,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
