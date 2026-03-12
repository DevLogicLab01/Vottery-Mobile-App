import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class TaxIntegrationPanelWidget extends StatelessWidget {
  final List<Map<String, dynamic>> taxCalculations;

  const TaxIntegrationPanelWidget({super.key, required this.taxCalculations});

  @override
  Widget build(BuildContext context) {
    final totalTaxLiability = taxCalculations.fold<double>(
      0.0,
      (sum, calc) => sum + (calc['tax_amount_usd'] ?? 0.0),
    );

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.orange.withAlpha(26),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.orange.withAlpha(51)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.account_balance, color: Colors.orange, size: 6.w),
              SizedBox(width: 2.w),
              Text(
                'Tax Integration (Stripe Tax)',
                style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Estimated Tax Liability',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: AppTheme.textSecondaryLight,
                    ),
                  ),
                  Text(
                    '\$${totalTaxLiability.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                child: Text('View Details'),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          _buildComplianceStatus(),
        ],
      ),
    );
  }

  Widget _buildComplianceStatus() {
    return Row(
      children: [
        Icon(Icons.check_circle, color: Colors.green, size: 5.w),
        SizedBox(width: 2.w),
        Expanded(
          child: Text(
            'All tax documents up to date',
            style: TextStyle(fontSize: 12.sp, color: Colors.green),
          ),
        ),
      ],
    );
  }
}
