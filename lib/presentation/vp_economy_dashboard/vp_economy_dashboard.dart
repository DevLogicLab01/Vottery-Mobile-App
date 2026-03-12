import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/vp_service.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/enhanced_empty_state_widget.dart';
import '../../widgets/error_boundary_wrapper.dart';
import '../../widgets/shimmer_skeleton_loader.dart';
import './widgets/earning_card_widget.dart';
import './widgets/spending_card_widget.dart';
import './widgets/transaction_item_widget.dart';

/// VP Economy Dashboard - Central hub for Vottery Points management
/// Displays balance, earning opportunities, spending options, and transaction history
class VPEconomyDashboard extends StatefulWidget {
  const VPEconomyDashboard({super.key});

  @override
  State<VPEconomyDashboard> createState() => _VPEconomyDashboardState();
}

class _VPEconomyDashboardState extends State<VPEconomyDashboard>
    with SingleTickerProviderStateMixin {
  final VPService _vpService = VPService.instance;

  int _currentBalance = 0;
  List<Map<String, dynamic>> _earningOpportunities = [];
  List<Map<String, dynamic>> _spendingOptions = [];
  List<Map<String, dynamic>> _transactions = [];
  bool _isLoading = true;

  late AnimationController _balanceAnimationController;
  late Animation<double> _balanceAnimation;

  @override
  void initState() {
    super.initState();
    _balanceAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _balanceAnimation = CurvedAnimation(
      parent: _balanceAnimationController,
      curve: Curves.easeOutCubic,
    );
    _loadData();
  }

  @override
  void dispose() {
    _balanceAnimationController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final balanceData = await _vpService.getVPBalance();
    final balance = balanceData?['available_vp'] as int? ?? 0;
    final earning = await _vpService.getEarningOpportunities();
    final spending = await _vpService.getSpendingOptions();
    final transactions = await _vpService.getVPTransactionHistory(limit: 20);

    if (mounted) {
      setState(() {
        _currentBalance = balance;
        _earningOpportunities = earning;
        _spendingOptions = spending;
        _transactions = transactions;
        _isLoading = false;
      });
      _balanceAnimationController.forward();
    }
  }

  Future<void> _refreshData() async {
    await _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ErrorBoundaryWrapper(
      screenName: 'VPEconomyDashboard',
      onRetry: _loadData,
      child: Scaffold(
        backgroundColor: theme.colorScheme.surface,
        appBar: CustomAppBar(
          title: 'VP Economy',
          actions: [
            IconButton(
              icon: CustomIconWidget(
                iconName: 'info_outline',
                color: theme.colorScheme.onPrimary,
                size: 24,
              ),
              onPressed: () => _showVPGuide(context),
            ),
          ],
        ),
        body: _isLoading
            ? const SkeletonDashboard()
            : _transactions.isEmpty
            ? NoTransactionsEmptyState()
            : RefreshIndicator(
                onRefresh: _refreshData,
                color: theme.colorScheme.primary,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // VP Balance Header
                      _buildBalanceHeader(theme),

                      SizedBox(height: 3.h),

                      // Earning Opportunities Section
                      _buildSectionHeader(theme, 'Earning Opportunities'),
                      SizedBox(height: 1.5.h),
                      _buildEarningSection(),

                      SizedBox(height: 3.h),

                      // Spending Options Section
                      _buildSectionHeader(theme, 'Spending Options'),
                      SizedBox(height: 1.5.h),
                      _buildSpendingSection(),

                      SizedBox(height: 3.h),

                      // Recent Transactions Section
                      _buildSectionHeader(theme, 'Recent Transactions'),
                      SizedBox(height: 1.5.h),
                      _buildTransactionsSection(theme),

                      SizedBox(height: 3.h),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildBalanceHeader(ThemeData theme) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.all(4.w),
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 4.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primaryContainer,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Current Balance',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onPrimary.withValues(alpha: 0.9),
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 1.h),
          AnimatedBuilder(
            animation: _balanceAnimation,
            builder: (context, child) {
              final animatedBalance =
                  (_currentBalance * _balanceAnimation.value).toInt();
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    animatedBalance.toString(),
                    style: theme.textTheme.displayMedium?.copyWith(
                      color: theme.colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 20.sp,
                    ),
                  ),
                  SizedBox(width: 2.w),
                  Padding(
                    padding: EdgeInsets.only(top: 1.h),
                    child: Text(
                      'VP',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: theme.colorScheme.onPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(ThemeData theme, String title) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: Text(
        title,
        style: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.onSurface,
        ),
      ),
    );
  }

  Widget _buildEarningSection() {
    return SizedBox(
      height: 20.h,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 4.w),
        itemCount: _earningOpportunities.length,
        itemBuilder: (context, index) {
          return EarningCardWidget(
            opportunity: _earningOpportunities[index],
            onTap: () => _handleEarningTap(_earningOpportunities[index]),
          );
        },
      ),
    );
  }

  Widget _buildSpendingSection() {
    return SizedBox(
      height: 20.h,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 4.w),
        itemCount: _spendingOptions.length,
        itemBuilder: (context, index) {
          return SpendingCardWidget(
            option: _spendingOptions[index],
            currentBalance: _currentBalance,
            onTap: () => _handleSpendingTap(_spendingOptions[index]),
          );
        },
      ),
    );
  }

  Widget _buildTransactionsSection(ThemeData theme) {
    if (_transactions.isEmpty) {
      return Container(
        margin: EdgeInsets.symmetric(horizontal: 4.w),
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
        child: Center(
          child: Column(
            children: [
              CustomIconWidget(
                iconName: 'receipt_long',
                color: theme.colorScheme.onSurfaceVariant,
                size: 48,
              ),
              SizedBox(height: 2.h),
              Text(
                'No transactions yet',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      itemCount: _transactions.length,
      separatorBuilder: (context, index) => SizedBox(height: 1.h),
      itemBuilder: (context, index) {
        return TransactionItemWidget(transaction: _transactions[index]);
      },
    );
  }

  void _handleEarningTap(Map<String, dynamic> opportunity) {
    final category = opportunity['category'] as String;
    switch (category) {
      case 'voting':
        Navigator.pushNamed(context, AppRoutes.voteDashboard);
        break;
      case 'social':
        // Navigate to social features
        break;
      case 'challenge':
        // Navigate to challenges
        break;
      case 'prediction':
        // Navigate to predictions
        break;
    }
  }

  void _handleSpendingTap(Map<String, dynamic> option) async {
    final vpCost = option['vpCost'] as int;
    if (_currentBalance < vpCost) {
      _showInsufficientBalanceDialog();
      return;
    }

    final confirmed = await _showPurchaseConfirmation(option);
    if (confirmed == true) {
      final success = await _vpService.spendVPPremiumContent(option['id']);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully purchased ${option['title']}'),
            backgroundColor: Theme.of(context).colorScheme.tertiary,
          ),
        );
        _refreshData();
      }
    }
  }

  void _showInsufficientBalanceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Insufficient Balance'),
        content: const Text(
          'You don\'t have enough VP for this purchase. Earn more VP by participating in votes and challenges!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<bool?> _showPurchaseConfirmation(Map<String, dynamic> option) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirm Purchase'),
        content: Text(
          'Purchase ${option['title']} for ${option['vpCost']} VP?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  void _showVPGuide(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('VP Earning Tips'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Earn VP by:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 1.h),
              const Text('• Voting in elections (10 VP)'),
              const Text('• Social interactions (5 VP)'),
              const Text('• Daily challenges (50-500 VP)'),
              const Text('• Prediction pools (up to 1000 VP)'),
              SizedBox(height: 2.h),
              const Text(
                'Spend VP on:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 1.h),
              const Text('• Ad-free experience'),
              const Text('• Custom themes'),
              const Text('• Prediction entries'),
              const Text('• Premium content'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}