import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class WalletBalanceCardsWidget extends StatelessWidget {
  final double availableBalance;
  final double pendingBalance;
  final double lifetimeEarnings;
  final String currency;

  const WalletBalanceCardsWidget({
    super.key,
    required this.availableBalance,
    required this.pendingBalance,
    required this.lifetimeEarnings,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildBalanceCard(
          'Available Balance',
          availableBalance,
          Colors.green,
          Icons.account_balance_wallet,
        ),
        SizedBox(height: 1.h),
        Row(
          children: [
            Expanded(
              child: _buildBalanceCard(
                'Pending',
                pendingBalance,
                Colors.orange,
                Icons.pending,
              ),
            ),
            SizedBox(width: 2.w),
            Expanded(
              child: _buildBalanceCard(
                'Lifetime',
                lifetimeEarnings,
                Colors.blue,
                Icons.trending_up,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBalanceCard(
    String label,
    double amount,
    Color color,
    IconData icon,
  ) {
    return Card(
      elevation: 3,
      color: color.withAlpha(26),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24.sp),
                SizedBox(width: 2.w),
                Text(
                  label,
                  style: TextStyle(fontSize: 13.sp, color: Colors.grey[700]),
                ),
              ],
            ),
            SizedBox(height: 1.h),
            Text(
              '${_getCurrencySymbol(currency)}${amount.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 24.sp,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getCurrencySymbol(String currency) {
    switch (currency) {
      case 'USD':
        return '\$';
      case 'EUR':
        return '€';
      case 'GBP':
        return '£';
      case 'JPY':
        return '¥';
      case 'INR':
        return '₹';
      case 'BRL':
        return 'R\$';
      case 'NGN':
        return '₦';
      case 'ZAR':
        return 'R';
      default:
        return '\$';
    }
  }
}
