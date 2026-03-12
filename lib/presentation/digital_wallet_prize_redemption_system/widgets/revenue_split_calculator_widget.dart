import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class RevenueSplitCalculatorWidget extends StatelessWidget {
  final double totalEarnings;
  final String currency;

  const RevenueSplitCalculatorWidget({
    super.key,
    required this.totalEarnings,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    final creatorShare = totalEarnings * 0.70;
    final platformFee = totalEarnings * 0.30;

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 10.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '70/30 Revenue Split',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 2.h),

          // Visual split representation
          Row(
            children: [
              Expanded(
                flex: 70,
                child: Container(
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(4.0),
                      bottomLeft: Radius.circular(4.0),
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 30,
                child: Container(
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(4.0),
                      bottomRight: Radius.circular(4.0),
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),

          // Creator share
          _buildSplitRow(
            label: 'Your Share (70%)',
            amount: '\$${creatorShare.toStringAsFixed(2)}',
            color: Colors.green,
          ),
          SizedBox(height: 1.h),

          // Platform fee
          _buildSplitRow(
            label: 'Platform Fee (30%)',
            amount: '\$${platformFee.toStringAsFixed(2)}',
            color: Colors.orange,
          ),
          SizedBox(height: 1.h),

          const Divider(),
          SizedBox(height: 1.h),

          // Total
          _buildSplitRow(
            label: 'Total Earnings',
            amount: '\$${totalEarnings.toStringAsFixed(2)}',
            color: Colors.black87,
            isBold: true,
          ),
        ],
      ),
    );
  }

  Widget _buildSplitRow({
    required String label,
    required String amount,
    required Color color,
    bool isBold = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            color: color,
          ),
        ),
        Text(
          amount,
          style: TextStyle(
            fontSize: 16,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}
