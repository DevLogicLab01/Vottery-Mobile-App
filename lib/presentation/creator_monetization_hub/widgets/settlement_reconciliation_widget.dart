import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class SettlementReconciliationWidget extends StatelessWidget {
  final Map<String, dynamic> earningsSummary;
  final Map<String, dynamic> payoutSummary;

  const SettlementReconciliationWidget({
    super.key,
    required this.earningsSummary,
    required this.payoutSummary,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      symbol: r'$',
      decimalDigits: 2,
    );
    final lifetimePayouts =
        (earningsSummary['lifetime_payouts_usd'] ?? 0.0) as num;
    final pendingBalance =
        (earningsSummary['pending_balance_usd'] ?? 0.0) as num;

    return SingleChildScrollView(
      padding: EdgeInsets.all(2.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildReconciliationSummary(
            lifetimePayouts.toDouble(),
            pendingBalance.toDouble(),
            currencyFormat,
          ),
          SizedBox(height: 3.h),
          Text(
            'Recent Settlements',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          SizedBox(height: 2.h),
          _buildSettlementCard(
            'Stripe Payout #12345',
            1250.50,
            'completed',
            DateTime.now().subtract(const Duration(days: 2)),
            currencyFormat,
          ),
          SizedBox(height: 1.h),
          _buildSettlementCard(
            'Stripe Payout #12344',
            980.30,
            'completed',
            DateTime.now().subtract(const Duration(days: 9)),
            currencyFormat,
          ),
          SizedBox(height: 1.h),
          _buildSettlementCard(
            'Stripe Payout #12343',
            1500.00,
            'pending',
            DateTime.now().subtract(const Duration(days: 1)),
            currencyFormat,
          ),
        ],
      ),
    );
  }

  Widget _buildReconciliationSummary(
    double lifetime,
    double pending,
    NumberFormat format,
  ) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple, Colors.purple.shade700],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withAlpha(77),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Lifetime Payouts',
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: Colors.white.withAlpha(230),
                    ),
                  ),
                  SizedBox(height: 0.5.h),
                  Text(
                    format.format(lifetime),
                    style: TextStyle(
                      fontSize: 18.sp,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Icon(Icons.check_circle, color: Colors.white, size: 8.w),
            ],
          ),
          SizedBox(height: 2.h),
          Container(
            padding: EdgeInsets.all(2.w),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(51),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Pending Settlement',
                  style: TextStyle(fontSize: 10.sp, color: Colors.white),
                ),
                Text(
                  format.format(pending),
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettlementCard(
    String title,
    double amount,
    String status,
    DateTime date,
    NumberFormat format,
  ) {
    final statusColor = status == 'completed' ? Colors.green : Colors.orange;

    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(2.w),
            decoration: BoxDecoration(
              color: statusColor.withAlpha(26),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Icon(
              status == 'completed' ? Icons.check_circle : Icons.pending,
              color: statusColor,
              size: 5.w,
            ),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimaryLight,
                  ),
                ),
                SizedBox(height: 0.5.h),
                Text(
                  DateFormat('MMM dd, yyyy').format(date),
                  style: TextStyle(
                    fontSize: 9.sp,
                    color: AppTheme.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                format.format(amount),
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimaryLight,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                decoration: BoxDecoration(
                  color: statusColor.withAlpha(26),
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: TextStyle(
                    fontSize: 8.sp,
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
