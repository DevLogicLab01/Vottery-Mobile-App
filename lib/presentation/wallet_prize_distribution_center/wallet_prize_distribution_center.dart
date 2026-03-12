import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/wallet_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/offline_status_badge.dart';
import './widgets/active_winnings_card_widget.dart';
import './widgets/lottery_draw_card_widget.dart';
import './widgets/payout_history_card_widget.dart';
import './widgets/regional_pricing_widget.dart';
import './widgets/wallet_balance_header_widget.dart';
import '../../widgets/error_boundary_wrapper.dart';
import '../../widgets/shimmer_skeleton_loader.dart';
import '../../widgets/enhanced_empty_state_widget.dart';

/// Wallet & Prize Distribution Center - Gamified election winnings management
/// Implements automated payout processing, lottery draws, and regional pricing
class WalletPrizeDistributionCenter extends StatefulWidget {
  const WalletPrizeDistributionCenter({super.key});

  @override
  State<WalletPrizeDistributionCenter> createState() =>
      _WalletPrizeDistributionCenterState();
}

class _WalletPrizeDistributionCenterState
    extends State<WalletPrizeDistributionCenter>
    with SingleTickerProviderStateMixin {
  final WalletService _walletService = WalletService.instance;
  late TabController _tabController;

  bool _isLoading = true;
  Map<String, dynamic>? _walletBalance;
  List<Map<String, dynamic>> _activeWinnings = [];
  List<Map<String, dynamic>> _payoutHistory = [];
  List<Map<String, dynamic>> _lotteryDraws = [];
  List<Map<String, dynamic>> _zoneFeeStructure = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
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
      final balance = await _walletService.getWalletBalance();
      final winnings = await _walletService.getPendingWinnings();
      final history = await _walletService.getPayoutHistory();
      final lotteries = await _walletService.getLotteryDraws();
      final zones = await _walletService.getZoneFeeStructure();

      setState(() {
        _walletBalance = balance;
        _activeWinnings = winnings;
        _payoutHistory = history;
        _lotteryDraws = lotteries;
        _zoneFeeStructure = zones;
      });
    } catch (e) {
      debugPrint('Load wallet data error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _requestPayout() async {
    final payoutMethod = await _showPayoutMethodDialog();
    if (payoutMethod == null) return;

    final amount = await _showAmountDialog();
    if (amount == null || amount <= 0) return;

    final result = await _walletService.requestPayout(
      amount: amount,
      method: payoutMethod,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.success
                ? 'Payout request submitted. You\'ll be paid by the next payment date.'
                : (result.errorMessage ?? 'Failed to submit payout request'),
          ),
          backgroundColor: result.success ? AppTheme.accentLight : AppTheme.errorLight,
        ),
      );

      if (result.success) {
        _loadData();
      }
    }
  }

  Future<String?> _showPayoutMethodDialog() async {
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Payout Method'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildPayoutMethodOption('bank_transfer', 'Bank Transfer'),
            _buildPayoutMethodOption('digital_wallet', 'Digital Wallet'),
            _buildPayoutMethodOption('stripe', 'Stripe Connect'),
          ],
        ),
      ),
    );
  }

  Widget _buildPayoutMethodOption(String method, String label) {
    return ListTile(
      title: Text(label),
      onTap: () => Navigator.of(context).pop(method),
    );
  }

  Future<double?> _showAmountDialog() async {
    final controller = TextEditingController();
    final result = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enter Amount'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Amount (USD)',
            prefixText: '\$',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final amount = double.tryParse(controller.text);
              Navigator.of(context).pop(amount);
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    controller.dispose();
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ErrorBoundaryWrapper(
      screenName: 'WalletPrizeDistributionCenter',
      onRetry: _loadData,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: CustomAppBar(
            title: 'Wallet & Prizes',
            variant: CustomAppBarVariant.standard,
            actions: [
              const OfflineStatusBadge(),
              IconButton(
                icon: Icon(
                  Icons.refresh,
                  color: theme.appBarTheme.foregroundColor,
                ),
                onPressed: _loadData,
              ),
            ],
          ),
        ),
        body: _isLoading
            ? const SkeletonDashboard()
            : _activeWinnings.isEmpty
            ? NoDataEmptyState(
                title: 'No Winnings Yet',
                description: 'Participate in lottery draws to win prizes!',
                onRefresh: _loadData,
              )
            : Column(
                children: [
                  WalletBalanceHeaderWidget(
                    walletBalance: _walletBalance,
                    onRequestPayout: _requestPayout,
                  ),
                  TabBar(
                    controller: _tabController,
                    labelColor: theme.colorScheme.primary,
                    unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
                    indicatorColor: theme.colorScheme.primary,
                    tabs: [
                      Tab(text: 'Winnings'),
                      Tab(text: 'History'),
                      Tab(text: 'Lottery'),
                      Tab(text: 'Pricing'),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildActiveWinningsTab(),
                        _buildPayoutHistoryTab(),
                        _buildLotteryDrawsTab(),
                        _buildRegionalPricingTab(),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildActiveWinningsTab() {
    if (_activeWinnings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.emoji_events_outlined,
              size: 20.w,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            SizedBox(height: 2.h),
            Text(
              'No active winnings',
              style: TextStyle(
                fontSize: 14.sp,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: EdgeInsets.all(4.w),
        itemCount: _activeWinnings.length,
        itemBuilder: (context, index) {
          return ActiveWinningsCardWidget(
            winning: _activeWinnings[index],
            onClaim: () => _loadData(),
          );
        },
      ),
    );
  }

  Widget _buildPayoutHistoryTab() {
    if (_payoutHistory.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              size: 20.w,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            SizedBox(height: 2.h),
            Text(
              'No payout history',
              style: TextStyle(
                fontSize: 14.sp,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: EdgeInsets.all(4.w),
        itemCount: _payoutHistory.length,
        itemBuilder: (context, index) {
          return PayoutHistoryCardWidget(payout: _payoutHistory[index]);
        },
      ),
    );
  }

  Widget _buildLotteryDrawsTab() {
    if (_lotteryDraws.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.casino_outlined,
              size: 20.w,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            SizedBox(height: 2.h),
            Text(
              'No active lottery draws',
              style: TextStyle(
                fontSize: 14.sp,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: EdgeInsets.all(4.w),
        itemCount: _lotteryDraws.length,
        itemBuilder: (context, index) {
          return LotteryDrawCardWidget(
            lottery: _lotteryDraws[index],
            onJoin: () => _loadData(),
          );
        },
      ),
    );
  }

  Widget _buildRegionalPricingTab() {
    return RegionalPricingWidget(zoneFeeStructure: _zoneFeeStructure);
  }
}
