import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/billing_service.dart';
import '../../services/wallet_service.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/enhanced_empty_state_widget.dart';
import '../../widgets/error_boundary_wrapper.dart';
import '../../widgets/shimmer_skeleton_loader.dart';
import './widgets/automated_billing_widget.dart';
import './widgets/payment_retry_widget.dart';
import './widgets/prize_payout_automation_widget.dart';
import './widgets/refund_processing_widget.dart';
import './widgets/regional_pricing_widget.dart';
import './widgets/transaction_compliance_widget.dart';

/// Automated Payment Processing Hub with Stripe workflows and regional pricing
class AutomatedPaymentProcessingHub extends StatefulWidget {
  const AutomatedPaymentProcessingHub({super.key});

  @override
  State<AutomatedPaymentProcessingHub> createState() =>
      _AutomatedPaymentProcessingHubState();
}

class _AutomatedPaymentProcessingHubState
    extends State<AutomatedPaymentProcessingHub>
    with SingleTickerProviderStateMixin {
  final WalletService _walletService = WalletService.instance;
  final BillingService _billingService = BillingService.instance;

  late TabController _tabController;
  bool _isLoading = true;

  Map<String, dynamic>? _wallet;
  List<Map<String, dynamic>> _transactions = [];
  List<Map<String, dynamic>> _regionalPricing = [];
  List<Map<String, dynamic>> _complianceLogs = [];
  List<Map<String, dynamic>> _retryLogs = [];
  List<Map<String, dynamic>> _refundRecords = [];

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

    try {
      final wallet = await _walletService.getWallet();
      final transactions = await _walletService.getTransactions();
      final zone = wallet?['purchasing_power_zone'] ?? 'zone_1_us_canada';
      final pricing = await _walletService.getRegionalPricing(zone);

      // Mock compliance and retry logs (would come from backend)
      final complianceLogs = <Map<String, dynamic>>[];
      final retryLogs = <Map<String, dynamic>>[];
      final refundRecords = <Map<String, dynamic>>[];

      setState(() {
        _wallet = wallet;
        _transactions = transactions;
        _regionalPricing = pricing;
        _complianceLogs = complianceLogs;
        _retryLogs = retryLogs;
        _refundRecords = refundRecords;
      });
    } catch (e) {
      debugPrint('Load payment processing data error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ErrorBoundaryWrapper(
      screenName: 'AutomatedPaymentProcessingHub',
      onRetry: _loadData,
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
          title: 'Payment Processing',
        ),
        body: _isLoading
            ? const SkeletonDashboard()
            : _transactions.isEmpty
            ? NoTransactionsEmptyState()
            : SingleChildScrollView(
                child: Column(
                  children: [
                    _buildProcessingStatsHeader(),
                    _buildTabBar(),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildAutomatedBillingTab(),
                          _buildPrizePayoutsTab(),
                          _buildRegionalPricingTab(),
                          _buildComplianceTab(),
                          _buildRetryLogicTab(),
                          _buildRefundProcessingTab(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildProcessingStatsHeader() {
    final balance = _wallet?['balance_usd'] ?? 0.0;
    final totalTransactions = _transactions.length;
    final successfulTransactions = _transactions
        .where((t) => t['transaction_type'] == 'deposit')
        .length;

    return Container(
      margin: EdgeInsets.all(4.w),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryLight, AppTheme.secondaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Wallet Balance',
                  '\$${balance.toStringAsFixed(2)}',
                  Icons.account_balance_wallet,
                ),
              ),
              Container(
                width: 1,
                height: 8.h,
                color: Colors.white.withAlpha(77),
              ),
              Expanded(
                child: _buildStatItem(
                  'Total Transactions',
                  '$totalTransactions',
                  Icons.receipt_long,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Success Rate',
                  totalTransactions > 0
                      ? '${((successfulTransactions / totalTransactions) * 100).toStringAsFixed(1)}%'
                      : '0%',
                  Icons.check_circle,
                ),
              ),
              Container(
                width: 1,
                height: 8.h,
                color: Colors.white.withAlpha(77),
              ),
              Expanded(
                child: _buildStatItem(
                  'Zone',
                  _wallet?['purchasing_power_zone']
                          ?.toString()
                          .split('_')
                          .last
                          .toUpperCase() ??
                      'N/A',
                  Icons.public,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 8.w),
        SizedBox(height: 1.h),
        Text(
          value,
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 11.sp, color: Colors.white.withAlpha(230)),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        labelColor: AppTheme.primaryLight,
        unselectedLabelColor: AppTheme.textSecondaryLight,
        indicatorColor: AppTheme.primaryLight,
        labelStyle: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600),
        tabs: const [
          Tab(text: 'Automated Billing'),
          Tab(text: 'Prize Payouts'),
          Tab(text: 'Regional Pricing'),
          Tab(text: 'Compliance'),
          Tab(text: 'Retry Logic'),
          Tab(text: 'Refunds'),
        ],
      ),
    );
  }

  Widget _buildAutomatedBillingTab() {
    return AutomatedBillingWidget(
      transactions: _transactions,
      onRefresh: () => _loadData(),
    );
  }

  Widget _buildPrizePayoutsTab() {
    return PrizePayoutAutomationWidget(
      transactions: _transactions
          .where((t) => t['transaction_type'] == 'prize_payout')
          .toList(),
      onRefresh: () => _loadData(),
    );
  }

  Widget _buildRegionalPricingTab() {
    return RegionalPricingWidget(
      pricingData: _regionalPricing,
      currentZone: _wallet?['purchasing_power_zone'] ?? 'zone_1_us_canada',
    );
  }

  Widget _buildComplianceTab() {
    return TransactionComplianceWidget(
      complianceLogs: _complianceLogs,
      transactions: _transactions,
    );
  }

  Widget _buildRetryLogicTab() {
    return PaymentRetryWidget(
      retryLogs: _retryLogs,
      onRetry: (invoiceId) => _handleRetryPayment(invoiceId),
    );
  }

  Widget _buildRefundProcessingTab() {
    return RefundProcessingWidget(
      refundRecords: _refundRecords,
      onProcessRefund: (refundId) => _handleProcessRefund(refundId),
    );
  }

  Future<void> _handleRetryPayment(String invoiceId) async {
    // TODO: Implement retry payment logic via Edge Function
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Payment retry initiated')));
  }

  Future<void> _handleProcessRefund(String refundId) async {
    // TODO: Implement refund processing via Edge Function
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Refund processing initiated')),
    );
  }
}
