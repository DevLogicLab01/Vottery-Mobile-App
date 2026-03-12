import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class RevenueSplitCalculatorWidget extends StatelessWidget {
  final double totalRevenue;
  final double creatorSplit;
  final double platformSplit;

  const RevenueSplitCalculatorWidget({
    super.key,
    required this.totalRevenue,
    required this.creatorSplit,
    required this.platformSplit,
  });

  @override
  Widget build(BuildContext context) {
    final creatorAmount = totalRevenue * creatorSplit;
    final platformAmount = totalRevenue * platformSplit;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '70/30 Creator Revenue Split',
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 1.h),
            Text(
              'Platform fee breakdown',
              style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
            ),
            SizedBox(height: 2.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSplitCard('Creator (70%)', creatorAmount, Colors.green),
                _buildSplitCard('Platform (30%)', platformAmount, Colors.blue),
              ],
            ),
            SizedBox(height: 2.h),
            LinearProgressIndicator(
              value: creatorSplit,
              backgroundColor: Colors.blue.withAlpha(77),
              valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
              minHeight: 1.h,
            ),
            SizedBox(height: 1.h),
            Center(
              child: Text(
                'Total Revenue: \$${totalRevenue.toStringAsFixed(2)}',
                style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSplitCard(String label, double amount, Color color) {
    return Column(
      children: [
        Text(
          '\$${amount.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        SizedBox(height: 0.5.h),
        Text(
          label,
          style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
