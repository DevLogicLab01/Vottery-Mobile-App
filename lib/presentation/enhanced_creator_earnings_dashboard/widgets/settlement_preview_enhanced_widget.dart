import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class SettlementPreviewEnhancedWidget extends StatelessWidget {
  final Map<String, dynamic> earningsSummary;
  final List<Map<String, dynamic>> taxCalculations;

  const SettlementPreviewEnhancedWidget({
    super.key,
    required this.earningsSummary,
    required this.taxCalculations,
  });

  @override
  Widget build(BuildContext context) {
    final availableBalance = earningsSummary['available_balance_usd'] ?? 0.0;
    final totalTaxWithholding = taxCalculations.fold<double>(
      0.0,
      (sum, calc) => sum + (calc['tax_amount_usd'] ?? 0.0),
    );
    final netPayout = availableBalance - totalTaxWithholding;

    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Settlement Preview',
            style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 2.h),
          _buildSettlementCard(
            availableBalance,
            totalTaxWithholding,
            netPayout,
          ),
          SizedBox(height: 3.h),
          _buildTaxDocumentRequirements(),
          SizedBox(height: 3.h),
          _buildWithdrawButton(context, netPayout),
        ],
      ),
    );
  }

  Widget _buildSettlementCard(
    double availableBalance,
    double taxWithholding,
    double netPayout,
  ) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        children: [
          _buildAmountRow('Available Balance', availableBalance, false),
          Divider(height: 3.h),
          _buildAmountRow('Tax Withholding', taxWithholding, true),
          Divider(height: 3.h),
          _buildAmountRow('Net Payout', netPayout, false, isTotal: true),
        ],
      ),
    );
  }

  Widget _buildAmountRow(
    String label,
    double amount,
    bool isNegative, {
    bool isTotal = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 14.sp : 13.sp,
            fontWeight: isTotal ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
        Text(
          '${isNegative ? '-' : ''}\$${amount.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: isTotal ? 16.sp : 14.sp,
            fontWeight: FontWeight.w700,
            color: isTotal
                ? AppTheme.primaryLight
                : (isNegative ? Colors.red : AppTheme.textPrimaryLight),
          ),
        ),
      ],
    );
  }

  Widget _buildTaxDocumentRequirements() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.blue.withAlpha(26),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info, color: Colors.blue, size: 5.w),
              SizedBox(width: 2.w),
              Text(
                'Tax Document Status',
                style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          _buildDocumentStatus('W-9 Form', true),
          _buildDocumentStatus('Bank Verification', true),
          _buildDocumentStatus('Tax ID Validation', true),
        ],
      ),
    );
  }

  Widget _buildDocumentStatus(String label, bool isComplete) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 0.5.h),
      child: Row(
        children: [
          Icon(
            isComplete ? Icons.check_circle : Icons.warning,
            color: isComplete ? Colors.green : Colors.orange,
            size: 4.w,
          ),
          SizedBox(width: 2.w),
          Text(label, style: TextStyle(fontSize: 12.sp)),
        ],
      ),
    );
  }

  Widget _buildWithdrawButton(BuildContext context, double netPayout) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: netPayout > 0 ? () {} : null,
        child: Text('Withdraw \$${netPayout.toStringAsFixed(2)}'),
      ),
    );
  }
}
