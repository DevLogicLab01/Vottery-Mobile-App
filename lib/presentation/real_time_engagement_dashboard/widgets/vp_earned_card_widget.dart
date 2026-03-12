import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class VpEarnedCardWidget extends StatelessWidget {
  final int amount;
  final Map<String, dynamic> breakdown;

  const VpEarnedCardWidget({
    super.key,
    required this.amount,
    required this.breakdown,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(Icons.stars, color: Colors.amber, size: 16.sp),
            Text(
              amount.toString(),
              style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold),
            ),
            Text(
              'VP Earned (1 hour)',
              style: TextStyle(fontSize: 11.sp, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
