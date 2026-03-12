import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class TotalCostCard extends StatelessWidget {
  final double totalMonthlyCost;
  final double trendVsLastMonth;
  final double costPerQuery;
  final double costPerUser;

  const TotalCostCard({
    super.key,
    required this.totalMonthlyCost,
    required this.trendVsLastMonth,
    required this.costPerQuery,
    required this.costPerUser,
  });

  @override
  Widget build(BuildContext context) {
    final isUp = trendVsLastMonth > 0;
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.indigo.shade700, Colors.indigo.shade500],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16.0),
        ),
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(
                  Icons.account_balance_wallet,
                  color: Colors.white70,
                  size: 20,
                ),
                SizedBox(width: 2.w),
                Text(
                  'Total Monthly Infrastructure Cost',
                  style: TextStyle(fontSize: 12.sp, color: Colors.white70),
                ),
              ],
            ),
            SizedBox(height: 1.h),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '\$${totalMonthlyCost.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 22.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(width: 2.w),
                Padding(
                  padding: EdgeInsets.only(bottom: 0.5.h),
                  child: Row(
                    children: [
                      Icon(
                        isUp ? Icons.arrow_upward : Icons.arrow_downward,
                        color: isUp
                            ? Colors.red.shade300
                            : Colors.green.shade300,
                        size: 14,
                      ),
                      Text(
                        '${trendVsLastMonth.abs().toStringAsFixed(1)}% vs last month',
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: isUp
                              ? Colors.red.shade300
                              : Colors.green.shade300,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 1.5.h),
            Row(
              children: [
                Expanded(
                  child: _StatChip(
                    label: 'Per Query',
                    value: '\$${costPerQuery.toStringAsFixed(4)}',
                    icon: Icons.query_stats,
                  ),
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: _StatChip(
                    label: 'Per User',
                    value: '\$${costPerUser.toStringAsFixed(3)}',
                    icon: Icons.person,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatChip({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 1.h),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(38),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white70, size: 14),
          SizedBox(width: 1.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                label,
                style: TextStyle(fontSize: 9.sp, color: Colors.white70),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
