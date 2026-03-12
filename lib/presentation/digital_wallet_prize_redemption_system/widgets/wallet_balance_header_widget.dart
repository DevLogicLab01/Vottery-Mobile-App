import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class WalletBalanceHeaderWidget extends StatelessWidget {
  final Map<String, dynamic> balance;
  final String currency;

  const WalletBalanceHeaderWidget({
    super.key,
    required this.balance,
    required this.currency,
  });

  String _getCurrencySymbol() {
    switch (currency) {
      case 'USD':
        return '\$';
      case 'EUR':
        return '€';
      case 'GBP':
        return '£';
      case 'JPY':
        return '¥';
      case 'AUD':
        return 'A\$';
      case 'CAD':
        return 'C\$';
      case 'INR':
        return '₹';
      case 'BRL':
        return 'R\$';
      default:
        return '\$';
    }
  }

  @override
  Widget build(BuildContext context) {
    final available = balance['available'] ?? 0.0;
    final pending = balance['pending'] ?? 0.0;
    final lifetime = balance['lifetime'] ?? 0.0;
    final symbol = _getCurrencySymbol();

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF667eea), Color(0xFF764ba2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(26),
            blurRadius: 10.0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Available Balance',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            '$symbol${available.toStringAsFixed(2)}',
            style: TextStyle(
              color: Colors.white,
              fontSize: 32.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              Expanded(
                child: _buildBalanceCard(
                  label: 'Pending',
                  amount: '$symbol${pending.toStringAsFixed(2)}',
                  icon: Icons.schedule,
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: _buildBalanceCard(
                  label: 'Lifetime Earnings',
                  amount: '$symbol${lifetime.toStringAsFixed(2)}',
                  icon: Icons.trending_up,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceCard({
    required String label,
    required String amount,
    required IconData icon,
  }) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(51),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white70, size: 20.sp),
          SizedBox(height: 1.h),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          SizedBox(height: 0.5.h),
          Text(
            amount,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
