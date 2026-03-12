import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import 'package:intl/intl.dart';

class PayoutPreviewWidget extends StatelessWidget {
  final Map<String, dynamic> payoutPreview;
  final Map<String, dynamic> currentSplit;

  const PayoutPreviewWidget({
    super.key,
    required this.payoutPreview,
    required this.currentSplit,
  });

  @override
  Widget build(BuildContext context) {
    final availableBalanceUsd = payoutPreview['available_balance_usd'] ?? 0.0;
    final creatorPercentage = currentSplit['creator_percentage'] ?? 70.0;
    final platformPercentage = currentSplit['platform_percentage'] ?? 30.0;
    final currencyFormat = NumberFormat.currency(
      symbol: '\$',
      decimalDigits: 2,
    );

    // Calculate breakdown
    final grossRevenue = availableBalanceUsd / (creatorPercentage / 100);
    final platformShare = grossRevenue * (platformPercentage / 100);

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.account_balance_wallet,
                color: Colors.green.shade700,
                size: 20.sp,
              ),
              SizedBox(width: 2.w),
              Text(
                'Next Payout Preview',
                style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade900,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          // Available Balance
          Container(
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Your Payout',
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade700,
                  ),
                ),
                Text(
                  currencyFormat.format(availableBalanceUsd),
                  style: GoogleFonts.inter(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.green.shade900,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 1.5.h),
          // Detailed Breakdown
          _buildBreakdownRow(
            'Gross Revenue',
            currencyFormat.format(grossRevenue),
            Colors.grey.shade600,
          ),
          SizedBox(height: 1.h),
          _buildBreakdownRow(
            'Your Share (${creatorPercentage.toStringAsFixed(0)}%)',
            currencyFormat.format(availableBalanceUsd),
            Colors.green.shade700,
          ),
          SizedBox(height: 1.h),
          _buildBreakdownRow(
            'Platform Share (${platformPercentage.toStringAsFixed(0)}%)',
            currencyFormat.format(platformShare),
            Colors.blue.shade700,
          ),
          SizedBox(height: 2.h),
          // Earnings Calculator Link
          InkWell(
            onTap: () {
              // TODO: Navigate to earnings calculator
            },
            child: Container(
              padding: EdgeInsets.all(2.w),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.calculate,
                    color: Colors.blue.shade700,
                    size: 16.sp,
                  ),
                  SizedBox(width: 2.w),
                  Text(
                    'Try Earnings Calculator',
                    style: GoogleFonts.inter(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.blue.shade900,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownRow(String label, String value, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11.sp,
            color: Colors.grey.shade600,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 12.sp,
            fontWeight: FontWeight.w600,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}
