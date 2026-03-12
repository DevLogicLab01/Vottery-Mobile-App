import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class WithdrawalLimitsWidget extends StatelessWidget {
  final double dailyLimit;
  final double monthlyLimit;
  final double usedDaily;
  final double usedMonthly;

  const WithdrawalLimitsWidget({
    super.key,
    required this.dailyLimit,
    required this.monthlyLimit,
    required this.usedDaily,
    required this.usedMonthly,
  });

  @override
  Widget build(BuildContext context) {
    final dailyRemaining = dailyLimit - usedDaily;
    final monthlyRemaining = monthlyLimit - usedMonthly;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Withdrawal Limits',
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 1.h),
            Text(
              'Max \$10,000/day | Max \$50,000/month',
              style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
            ),
            SizedBox(height: 2.h),
            _buildLimitProgress(
              'Daily Limit',
              usedDaily,
              dailyLimit,
              dailyRemaining,
              Colors.orange,
            ),
            SizedBox(height: 2.h),
            _buildLimitProgress(
              'Monthly Limit',
              usedMonthly,
              monthlyLimit,
              monthlyRemaining,
              Colors.blue,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLimitProgress(
    String label,
    double used,
    double limit,
    double remaining,
    Color color,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w500),
            ),
            Text(
              '\$${remaining.toStringAsFixed(2)} remaining',
              style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
            ),
          ],
        ),
        SizedBox(height: 0.5.h),
        LinearProgressIndicator(
          value: used / limit,
          backgroundColor: Colors.grey[300],
          valueColor: AlwaysStoppedAnimation<Color>(color),
          minHeight: 1.h,
        ),
        SizedBox(height: 0.5.h),
        Text(
          '\$${used.toStringAsFixed(2)} / \$${limit.toStringAsFixed(2)}',
          style: TextStyle(fontSize: 11.sp, color: Colors.grey[600]),
        ),
      ],
    );
  }
}
