import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class WalletBalanceHeaderWidget extends StatelessWidget {
  final Map<String, dynamic>? walletBalance;
  final VoidCallback onRequestPayout;

  const WalletBalanceHeaderWidget({
    super.key,
    required this.walletBalance,
    required this.onRequestPayout,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalBalance = walletBalance?['total_balance'] ?? 0.0;
    final availableBalance = walletBalance?['available_balance'] ?? 0.0;
    final pendingBalance = walletBalance?['pending_balance'] ?? 0.0;
    final lifetimeEarnings = walletBalance?['lifetime_earnings'] ?? 0.0;

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryLight, AppTheme.accentLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          Text(
            'Total Balance',
            style: TextStyle(
              fontSize: 13.sp,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            '\$${totalBalance.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              Expanded(
                child: _buildBalanceCard(
                  'Available',
                  availableBalance,
                  Icons.account_balance_wallet,
                  theme,
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: _buildBalanceCard(
                  'Pending',
                  pendingBalance,
                  Icons.pending,
                  theme,
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: _buildBalanceCard(
                  'Lifetime',
                  lifetimeEarnings,
                  Icons.trending_up,
                  theme,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          ElevatedButton.icon(
            onPressed: onRequestPayout,
            icon: Icon(Icons.payment, size: 5.w),
            label: Text('Request Payout'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppTheme.primaryLight,
              minimumSize: Size(double.infinity, 6.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceCard(
    String label,
    double amount,
    IconData icon,
    ThemeData theme,
  ) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 6.w),
          SizedBox(height: 0.5.h),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.sp,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
          SizedBox(height: 0.5.h),
          Text(
            '\$${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
