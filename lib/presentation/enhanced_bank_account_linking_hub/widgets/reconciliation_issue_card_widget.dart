import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import '../../../theme/app_theme.dart';

class ReconciliationIssueCardWidget extends StatelessWidget {
  final String payoutId;
  final String issueType;
  final String stripeAmount;
  final String dbAmount;
  final String status;
  final VoidCallback? onReview;

  const ReconciliationIssueCardWidget({
    super.key,
    required this.payoutId,
    required this.issueType,
    required this.stripeAmount,
    required this.dbAmount,
    required this.status,
    this.onReview,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 1.h),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.orange.withAlpha(10),
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(color: Colors.orange.withAlpha(80)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber, color: Colors.orange, size: 5.w),
              SizedBox(width: 2.w),
              Expanded(
                child: Text(
                  issueType,
                  style: GoogleFonts.inter(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimaryLight,
                  ),
                ),
              ),
              if (onReview != null)
                TextButton(
                  onPressed: onReview,
                  child: Text(
                    'Review',
                    style: GoogleFonts.inter(
                      fontSize: 10.sp,
                      color: AppTheme.primaryLight,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 0.5.h),
          Text(
            'Payout ID: ${payoutId.length > 16 ? payoutId.substring(0, 16) : payoutId}...',
            style: GoogleFonts.inter(
              fontSize: 10.sp,
              color: AppTheme.textSecondaryLight,
            ),
          ),
          SizedBox(height: 0.5.h),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Stripe: \$$stripeAmount',
                      style: GoogleFonts.inter(
                        fontSize: 11.sp,
                        color: Colors.blue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Database: \$$dbAmount',
                      style: GoogleFonts.inter(
                        fontSize: 11.sp,
                        color: Colors.purple,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(6.0),
                ),
                child: Text(
                  'MANUAL REVIEW',
                  style: GoogleFonts.inter(
                    fontSize: 8.sp,
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
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
