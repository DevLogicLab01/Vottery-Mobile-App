import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/wallet_service.dart';
import '../../services/vp_service.dart';
import '../../services/currency_exchange_service.dart';
import '../../services/creator_verification_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/error_boundary_wrapper.dart';
import '../../widgets/shimmer_skeleton_loader.dart';
import '../../widgets/enhanced_empty_state_widget.dart';
import './widgets/vp_balance_display_widget.dart';
import './widgets/redemption_options_widget.dart';
import './widgets/kyc_verification_workflow_widget.dart';
import './widgets/payout_history_tracking_widget.dart';
import './widgets/conversion_calculator_widget.dart';
import './widgets/quick_actions_widget.dart';

class DigitalWalletScreen extends StatefulWidget {
  const DigitalWalletScreen({super.key});

  @override
  State<DigitalWalletScreen> createState() => _DigitalWalletScreenState();
}

class _DigitalWalletScreenState extends State<DigitalWalletScreen> {
  final WalletService _walletService = WalletService.instance;
  final VPService _vpService = VPService.instance;
  final CurrencyExchangeService _currencyService =
      CurrencyExchangeService.instance;
  final CreatorVerificationService _verificationService =
      CreatorVerificationService.instance;

  bool _isLoading = true;
  Map<String, dynamic>? _vpBalance;
  Map<String, dynamic>? _verificationStatus;
  List<Map<String, dynamic>> _transactions = [];
  Map<String, double> _exchangeRates = {};

  @override
  void initState() {
    super.initState();
    _loadWalletData();
  }

  Future<void> _loadWalletData() async {
    setState(() => _isLoading = true);

    try {
      final results = await Future.wait([
        _vpService.getVPBalance(),
        _verificationService.getVerificationStatus(),
        _walletService.getTransactions(limit: 20),
        _currencyService.getExchangeRates(),
      ]);

      setState(() {
        _vpBalance = results[0] as Map<String, dynamic>?;
        _verificationStatus = results[1] as Map<String, dynamic>?;
        _transactions = results[2] as List<Map<String, dynamic>>;
        _exchangeRates = results[3] as Map<String, double>;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Load wallet data error: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _refreshData() async {
    await _loadWalletData();
  }

  @override
  Widget build(BuildContext context) {
    return ErrorBoundaryWrapper(
      screenName: 'DigitalWalletScreen',
      onRetry: _refreshData,
      child: Scaffold(
        backgroundColor: AppTheme.backgroundLight,
        appBar: CustomAppBar(
          title: 'Digital Wallet',
          actions: [
            IconButton(icon: Icon(Icons.refresh), onPressed: _refreshData),
          ],
        ),
        body: _isLoading
            ? _buildLoadingState()
            : _vpBalance == null
            ? _buildEmptyState()
            : _buildWalletContent(),
      ),
    );
  }

  Widget _buildLoadingState() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        children: [
          SkeletonCard(height: 20.h),
          SizedBox(height: 2.h),
          SkeletonCard(height: 25.h),
          SizedBox(height: 2.h),
          SkeletonCard(height: 15.h),
          SizedBox(height: 2.h),
          SkeletonList(itemCount: 3),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return EnhancedEmptyStateWidget(
      title: 'Your Wallet is Empty',
      description:
          'Start earning VP by participating in elections, completing quests, and engaging with content!',
      illustrationUrl: 'https://illustrations.popsy.co/amber/wallet.svg',
      fallbackIcon: Icons.account_balance_wallet_outlined,
      primaryActionLabel: 'Start Earning VP',
      onPrimaryAction: () {
        Navigator.pushNamed(context, '/feed-quest-dashboard');
      },
      secondaryActionLabel: 'Learn More',
      onSecondaryAction: () {
        // Navigate to help center
      },
    );
  }

  Widget _buildWalletContent() {
    return RefreshIndicator(
      onRefresh: _refreshData,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            VPBalanceDisplayWidget(
              vpBalance: _vpBalance!,
              exchangeRates: _exchangeRates,
            ),
            SizedBox(height: 3.h),
            RedemptionOptionsWidget(
              vpBalance: _vpBalance!,
              verificationStatus: _verificationStatus,
              onRedemptionComplete: _refreshData,
            ),
            SizedBox(height: 3.h),
            KYCVerificationWorkflowWidget(
              verificationStatus: _verificationStatus,
              onVerificationUpdate: _refreshData,
            ),
            SizedBox(height: 3.h),
            ConversionCalculatorWidget(exchangeRates: _exchangeRates),
            SizedBox(height: 3.h),
            QuickActionsWidget(verificationStatus: _verificationStatus),
            SizedBox(height: 3.h),
            PayoutHistoryTrackingWidget(
              transactions: _transactions,
              onLoadMore: () async {
                final moreTransactions = await _walletService.getTransactions(
                  limit: 20,
                );
                setState(() {
                  _transactions.addAll(moreTransactions);
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}
