import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../features/payouts/constants/payout_constants.dart';
import '../../services/supabase_service.dart';
import '../../services/wallet_service.dart';
import './widgets/automated_payout_processing_widget.dart';
import './widgets/prize_redemption_options_widget.dart';
import './widgets/revenue_split_calculator_widget.dart';
import './widgets/transaction_history_widget.dart';
import './widgets/wallet_balance_cards_widget.dart';
import './widgets/withdrawal_limits_widget.dart';

/// Digital Wallet & Prize Redemption Dashboard
///
/// Features:
/// - Gamified election winnings breakdown (lottery, predictions, quests)
/// - Prize redemption (cash via Stripe/Trolley, gift cards, crypto USDC)
/// - Automated payout processing with KYC verification
/// - Stripe Connect integration for creator bank accounts
/// - 70/30 creator revenue split calculator
/// - Transaction history with filters
/// - Multi-currency support (8 purchasing power zones)
/// - Withdrawal limits and security features
class WalletDashboard extends StatefulWidget {
  const WalletDashboard({super.key});

  @override
  State<WalletDashboard> createState() => _WalletDashboardState();
}

class _WalletDashboardState extends State<WalletDashboard> {
  final SupabaseService _supabaseService = SupabaseService.instance;
  final WalletService _walletService = WalletService.instance;

  bool _isLoading = true;
  Map<String, dynamic> _walletData = {};
  List<Map<String, dynamic>> _transactions = [];
  Map<String, dynamic> _earningsBreakdown = {};
  double _availableBalance = 0.0;
  double _pendingBalance = 0.0;
  double _lifetimeEarnings = 0.0;
  String _selectedCurrency = 'USD';

  @override
  void initState() {
    super.initState();
    _loadWalletData();
  }

  Future<void> _loadWalletData() async {
    try {
      setState(() => _isLoading = true);

      final userId = _supabaseService.client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Load wallet balance
      final balance = await _walletService.getWalletBalance();

      // Load earnings breakdown
      final breakdown = <String, dynamic>{
        'lottery': 0.0,
        'predictions': 0.0,
        'quests': 0.0,
      };

      // Load transaction history
      final transactions = await _walletService.getTransactions(limit: 50);

      setState(() {
        _walletData = balance ?? {};
        _availableBalance = (balance?['available_balance'] ?? 0.0).toDouble();
        _pendingBalance = (balance?['pending_balance'] ?? 0.0).toDouble();
        _lifetimeEarnings = (balance?['lifetime_earnings'] ?? 0.0).toDouble();
        _earningsBreakdown = breakdown;
        _transactions = transactions;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Load wallet data error: $e');
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

  Future<void> _requestPayout({
    required String method,
    required double amount,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      final userId = _supabaseService.client.auth.currentUser?.id;
      if (userId == null) return;

      // Same minimum threshold as Web (PayoutApi / PayoutConstants)
      if (amount < PayoutConstants.payoutThreshold) {
        throw Exception(PayoutErrors.belowThreshold);
      }

      // Validate withdrawal limits (align with Web MAX_PAYOUT_SINGLE if present)
      if (amount > 10000) {
        throw Exception('Maximum daily withdrawal is \$10,000');
      }

      final result = await _walletService.requestPayout(
        method: method,
        amount: amount,
      );

      if (result.success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Payout request submitted. You\'ll be paid by the next payment date.',
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
        await _loadWalletData();
      } else {
        throw Exception(result.errorMessage ?? 'Payout request failed');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payout failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _getProcessingTime(String method) {
    switch (method) {
      case 'gift_card':
        return 'Instant';
      case 'bank_transfer':
        return '2-3 business days';
      case 'stripe':
        return '1-2 business days';
      default:
        return 'Unknown';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Digital Wallet & Prize Redemption',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadWalletData,
            tooltip: 'Refresh',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.currency_exchange),
            onSelected: (currency) {
              setState(() => _selectedCurrency = currency);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'USD', child: Text('USD (\$)')),
              const PopupMenuItem(value: 'EUR', child: Text('EUR (€)')),
              const PopupMenuItem(value: 'GBP', child: Text('GBP (£)')),
              const PopupMenuItem(value: 'JPY', child: Text('JPY (¥)')),
              const PopupMenuItem(value: 'INR', child: Text('INR (₹)')),
              const PopupMenuItem(value: 'BRL', child: Text('BRL (R\$)')),
              const PopupMenuItem(value: 'NGN', child: Text('NGN (₦)')),
              const PopupMenuItem(value: 'ZAR', child: Text('ZAR (R)')),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadWalletData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.all(3.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Wallet Balance Cards
                    WalletBalanceCardsWidget(
                      availableBalance: _availableBalance,
                      pendingBalance: _pendingBalance,
                      lifetimeEarnings: _lifetimeEarnings,
                      currency: _selectedCurrency,
                    ),
                    SizedBox(height: 2.h),

                    // Gamified Earnings Breakdown
                    _buildEarningsBreakdown(),
                    SizedBox(height: 2.h),

                    // Prize Redemption Options
                    PrizeRedemptionOptionsWidget(
                      availableBalance: _availableBalance,
                      onRedeemCash: (amount) => _requestPayout(
                        method: 'bank_transfer',
                        amount: amount,
                      ),
                      onRedeemGiftCard: (provider, amount) => _requestPayout(
                        method: 'gift_card',
                        amount: amount,
                        additionalData: {'provider': provider},
                      ),
                    ),
                    SizedBox(height: 2.h),

                    // Revenue Split Calculator (70/30)
                    RevenueSplitCalculatorWidget(
                      totalRevenue: _lifetimeEarnings,
                      creatorSplit: 0.70,
                      platformSplit: 0.30,
                    ),
                    SizedBox(height: 2.h),

                    // Withdrawal Limits
                    WithdrawalLimitsWidget(
                      dailyLimit: 10000.0,
                      monthlyLimit: 50000.0,
                      usedDaily: _walletData['daily_withdrawn'] ?? 0.0,
                      usedMonthly: _walletData['monthly_withdrawn'] ?? 0.0,
                    ),
                    SizedBox(height: 2.h),

                    // Automated Payout Processing
                    AutomatedPayoutProcessingWidget(
                      pendingPayouts: _transactions
                          .where((t) => t['status'] == 'pending')
                          .length,
                      processingPayouts: _transactions
                          .where((t) => t['status'] == 'processing')
                          .length,
                    ),
                    SizedBox(height: 2.h),

                    // Transaction History
                    TransactionHistoryWidget(
                      transactions: _transactions,
                      onFilter: (filter) async {
                        // Implement filtering logic
                        await _loadWalletData();
                      },
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildEarningsBreakdown() {
    final lotteryEarnings = _earningsBreakdown['lottery'] ?? 0.0;
    final predictionEarnings = _earningsBreakdown['predictions'] ?? 0.0;
    final questEarnings = _earningsBreakdown['quests'] ?? 0.0;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Gamified Earnings Breakdown',
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 2.h),
            _buildEarningRow(
              'Lottery Prizes',
              lotteryEarnings,
              Icons.emoji_events,
              Colors.amber,
            ),
            SizedBox(height: 1.h),
            _buildEarningRow(
              'Prediction Pool Rewards',
              predictionEarnings,
              Icons.analytics,
              Colors.blue,
            ),
            SizedBox(height: 1.h),
            _buildEarningRow(
              'Quest Bonuses',
              questEarnings,
              Icons.stars,
              Colors.purple,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEarningRow(
    String label,
    double amount,
    IconData icon,
    Color color,
  ) {
    return Row(
      children: [
        Icon(icon, color: color, size: 24.sp),
        SizedBox(width: 3.w),
        Expanded(
          child: Text(label, style: TextStyle(fontSize: 14.sp)),
        ),
        Text(
          '\$${amount.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
