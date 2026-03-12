import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../features/payouts/api/payout_api.dart';
import '../../features/payouts/constants/payout_constants.dart';
import '../../services/stripe_connect_service.dart';
import '../../services/wallet_service.dart';
import './widgets/prize_breakdown_dashboard_widget.dart';
import './widgets/redemption_options_widget.dart';
import './widgets/automated_payout_processing_widget.dart';
import './widgets/revenue_split_calculator_widget.dart';
import './widgets/transaction_history_widget.dart';
import './widgets/wallet_balance_header_widget.dart';
import './widgets/security_features_widget.dart';
import './widgets/revenue_analytics_widget.dart';

/// Digital Wallet & Prize Redemption System
///
/// Comprehensive gamified election winnings management with multi-currency support
/// and automated payout processing across 8 purchasing power zones.
///
/// Features:
/// - Wallet balance display (available/pending/lifetime earnings)
/// - Prize breakdown (lottery prizes, prediction pool rewards, quest bonuses)
/// - Redemption options (cash, gift cards, crypto)
/// - Automated payout processing (Stripe/Trolley)
/// - 70/30 creator revenue split calculator
/// - Transaction history with filters
/// - Tax documentation (1099-K generation)
/// - Multi-currency support (8 purchasing power zones)
/// - Security features (2FA for large withdrawals)
/// - Revenue analytics (7-day/30-day trends)
class DigitalWalletPrizeRedemptionSystem extends StatefulWidget {
  const DigitalWalletPrizeRedemptionSystem({super.key});

  @override
  State<DigitalWalletPrizeRedemptionSystem> createState() =>
      _DigitalWalletPrizeRedemptionSystemState();
}

class _DigitalWalletPrizeRedemptionSystemState
    extends State<DigitalWalletPrizeRedemptionSystem>
    with SingleTickerProviderStateMixin {
  final WalletService _walletService = WalletService.instance;
  final StripeConnectService _stripeService = StripeConnectService.instance;

  late TabController _tabController;

  bool _isLoading = true;
  Map<String, dynamic> _walletBalance = {};
  List<Map<String, dynamic>> _prizeBreakdown = [];
  List<Map<String, dynamic>> _transactionHistory = [];
  Map<String, dynamic> _revenueAnalytics = {};
  String _selectedCurrency = 'USD';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadWalletData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadWalletData() async {
    try {
      setState(() => _isLoading = true);

      // Load wallet balance
      final balance = await _walletService.getWalletBalance();

      // Load prize breakdown
      final breakdown = await _walletService.getPendingWinnings();

      // Load transaction history
      final transactions = await _walletService.getTransactions(limit: 50);

      // Load revenue analytics - compute locally from transactions
      final analytics = _computeRevenueAnalytics(transactions);

      setState(() {
        _walletBalance = balance ?? {};
        _prizeBreakdown = breakdown;
        _transactionHistory = transactions;
        _revenueAnalytics = analytics;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load wallet data: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Add this helper method after _loadWalletData
  Map<String, dynamic> _computeRevenueAnalytics(
    List<Map<String, dynamic>> transactions,
  ) {
    // Compute analytics from transaction history
    final now = DateTime.now();
    final last7Days = transactions.where((t) {
      final date = DateTime.parse(t['created_at'] ?? now.toIso8601String());
      return now.difference(date).inDays <= 7;
    }).toList();

    final last30Days = transactions.where((t) {
      final date = DateTime.parse(t['created_at'] ?? now.toIso8601String());
      return now.difference(date).inDays <= 30;
    }).toList();

    return {
      'last_7_days': last7Days.length,
      'last_30_days': last30Days.length,
      'total_earnings': transactions.fold(
        0.0,
        (sum, t) => sum + (t['amount_usd'] ?? 0.0),
      ),
    };
  }

  Future<void> _requestPayout({
    required String method,
    required double amount,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      // Use same minimum threshold as Web (PayoutApi / PayoutConstants)
      if (amount < PayoutConstants.payoutThreshold) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Minimum payout amount is \$${PayoutConstants.payoutThreshold.toInt()}.',
              ),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      final result = await PayoutApi.instance.requestPayout(
        amount: amount,
        method: method,
        paymentDetails: null,
      );

      if (result.success) {
        await _loadWalletData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(PayoutSuccess.requestSubmitted),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.error ?? 'Payout request failed. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payout error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Digital Wallet',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          // Currency selector
          PopupMenuButton<String>(
            initialValue: _selectedCurrency,
            onSelected: (currency) {
              setState(() => _selectedCurrency = currency);
              _loadWalletData();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'USD', child: Text('USD (\$)')),
              const PopupMenuItem(value: 'EUR', child: Text('EUR (€)')),
              const PopupMenuItem(value: 'GBP', child: Text('GBP (£)')),
              const PopupMenuItem(value: 'JPY', child: Text('JPY (¥)')),
              const PopupMenuItem(value: 'AUD', child: Text('AUD (A\$)')),
              const PopupMenuItem(value: 'CAD', child: Text('CAD (C\$)')),
              const PopupMenuItem(value: 'INR', child: Text('INR (₹)')),
              const PopupMenuItem(value: 'BRL', child: Text('BRL (R\$)')),
            ],
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 2.w),
              child: Row(
                children: [
                  Text(
                    _selectedCurrency,
                    style: const TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Icon(Icons.arrow_drop_down, color: Colors.black87),
                ],
              ),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: Colors.blue,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.blue,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Redeem'),
            Tab(text: 'Transactions'),
            Tab(text: 'Analytics'),
            Tab(text: 'Settings'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                // Overview Tab
                _buildOverviewTab(),
                // Redeem Tab
                _buildRedeemTab(),
                // Transactions Tab
                _buildTransactionsTab(),
                // Analytics Tab
                _buildAnalyticsTab(),
                // Settings Tab
                _buildSettingsTab(),
              ],
            ),
    );
  }

  Widget _buildOverviewTab() {
    return RefreshIndicator(
      onRefresh: _loadWalletData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Wallet Balance Header
            WalletBalanceHeaderWidget(
              balance: _walletBalance,
              currency: _selectedCurrency,
            ),
            SizedBox(height: 3.h),

            // Prize Breakdown Dashboard
            PrizeBreakdownDashboardWidget(
              prizeBreakdown: _prizeBreakdown,
              currency: _selectedCurrency,
            ),
            SizedBox(height: 3.h),

            // Revenue Split Calculator
            RevenueSplitCalculatorWidget(
              totalEarnings: _walletBalance['available'] ?? 0.0,
              currency: _selectedCurrency,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRedeemTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(3.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Redemption Options
          RedemptionOptionsWidget(
            availableBalance: _walletBalance['available'] ?? 0.0,
            currency: _selectedCurrency,
            onRedeemCash: (amount, method) =>
                _requestPayout(method: method, amount: amount),
            onRedeemGiftCard: (amount, provider) => _requestPayout(
              method: 'gift_card',
              amount: amount,
              additionalData: {'provider': provider},
            ),
          ),
          SizedBox(height: 3.h),

          // Automated Payout Processing
          AutomatedPayoutProcessingWidget(
            pendingPayouts: _transactionHistory
                .where((t) => t['status'] == 'pending')
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionsTab() {
    return Column(
      children: [
        // Transaction History
        Expanded(
          child: TransactionHistoryWidget(
            transactions: _transactionHistory,
            currency: _selectedCurrency,
            onRefresh: _loadWalletData,
          ),
        ),
      ],
    );
  }

  Widget _buildAnalyticsTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(3.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Revenue Analytics
          RevenueAnalyticsWidget(
            analytics: _revenueAnalytics,
            currency: _selectedCurrency,
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(3.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Security Features
          SecurityFeaturesWidget(
            onEnable2FA: () async {
              // Implement 2FA setup
            },
            onSetAutoRedeem: (threshold) async {
              // Implement auto-redeem threshold
            },
          ),
        ],
      ),
    );
  }
}
