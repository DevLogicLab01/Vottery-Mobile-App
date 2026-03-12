import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class EscrowSystemWidget extends StatelessWidget {
  final Map<String, dynamic> service;
  final Map<String, dynamic> tier;
  final Future<bool> Function() onConfirm;

  const EscrowSystemWidget({
    super.key,
    required this.service,
    required this.tier,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final amount = (tier['price'] as num).toDouble();
    final platformFee = amount * 0.15;
    final processingFee = amount * 0.029 + 0.30;
    final total = amount + processingFee;

    return AlertDialog(
      title: Text(
        'Escrow Payment',
        style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Payment Flow',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryLight,
              ),
            ),
            SizedBox(height: 2.h),
            _buildFlowStep(
              '1',
              'You pay',
              '\$${total.toStringAsFixed(2)}',
              Colors.blue,
            ),
            _buildFlowArrow(),
            _buildFlowStep(
              '2',
              'Funds held in escrow',
              'Secure',
              Colors.orange,
            ),
            _buildFlowArrow(),
            _buildFlowStep('3', 'Creator delivers', 'Work', Colors.purple),
            _buildFlowArrow(),
            _buildFlowStep('4', 'You approve', 'Release', Colors.green),
            _buildFlowArrow(),
            _buildFlowStep(
              '5',
              'Funds released',
              '\$${(amount - platformFee).toStringAsFixed(2)}',
              Colors.green,
            ),
            SizedBox(height: 3.h),
            Container(
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: AppTheme.primaryLight.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Column(
                children: [
                  _buildPriceRow('Service', '\$${amount.toStringAsFixed(2)}'),
                  _buildPriceRow(
                    'Platform Fee (15%)',
                    '\$${platformFee.toStringAsFixed(2)}',
                  ),
                  _buildPriceRow(
                    'Processing Fee',
                    '\$${processingFee.toStringAsFixed(2)}',
                  ),
                  Divider(),
                  _buildPriceRow(
                    'Total',
                    '\$${total.toStringAsFixed(2)}',
                    isBold: true,
                  ),
                ],
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              '• Funds automatically released after 7 days\n• Dispute resolution available\n• Full refund if work not delivered',
              style: TextStyle(
                fontSize: 11.sp,
                color: AppTheme.textSecondaryLight,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            final success = await onConfirm();
            if (context.mounted) {
              Navigator.pop(context, success);
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryLight,
          ),
          child: Text('Confirm Payment'),
        ),
      ],
    );
  }

  Widget _buildFlowStep(
    String number,
    String label,
    String value,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          width: 8.w,
          height: 8.w,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          child: Center(
            child: Text(
              number,
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
        SizedBox(width: 3.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimaryLight,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 11.sp,
                  color: AppTheme.textSecondaryLight,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFlowArrow() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 0.5.h),
      child: Row(
        children: [
          SizedBox(width: 4.w),
          Icon(
            Icons.arrow_downward,
            color: AppTheme.textSecondaryLight,
            size: 5.w,
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 0.5.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: AppTheme.textPrimaryLight,
            ),
          ),
        ],
      ),
    );
  }
}
