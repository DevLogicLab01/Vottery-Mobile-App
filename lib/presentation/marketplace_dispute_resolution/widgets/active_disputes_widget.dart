import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../theme/app_theme.dart';

class ActiveDisputesWidget extends StatelessWidget {
  final List<Map<String, dynamic>> disputes;
  final VoidCallback onRefresh;

  const ActiveDisputesWidget({
    super.key,
    required this.disputes,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (disputes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 20.w, color: Colors.green),
            SizedBox(height: 2.h),
            Text(
              'No Active Disputes',
              style: GoogleFonts.inter(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              'All marketplace transactions are proceeding smoothly',
              style: GoogleFonts.inter(
                fontSize: 14.sp,
                color: AppTheme.textSecondaryLight,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(4.w),
      itemCount: disputes.length,
      itemBuilder: (context, index) {
        return _buildDisputeCard(context, disputes[index]);
      },
    );
  }

  Widget _buildDisputeCard(BuildContext context, Map<String, dynamic> dispute) {
    final serviceTitle =
        dispute['marketplace_services']?['title'] ?? 'Unknown Service';
    final buyerName = dispute['buyer']?['full_name'] ?? 'Unknown Buyer';
    final sellerName = dispute['seller']?['full_name'] ?? 'Unknown Seller';
    final amountUsd = dispute['amount_usd'] ?? 0.0;
    final disputeReason = dispute['dispute_reason'] ?? 'No reason provided';

    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.gavel, color: Colors.orange, size: 6.w),
              SizedBox(width: 3.w),
              Expanded(
                child: Text(
                  serviceTitle,
                  style: GoogleFonts.inter(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                '\$${amountUsd.toStringAsFixed(2)}',
                style: GoogleFonts.inter(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          _buildInfoRow('Buyer', buyerName),
          SizedBox(height: 1.h),
          _buildInfoRow('Seller', sellerName),
          SizedBox(height: 2.h),
          Container(
            padding: EdgeInsets.all(2.w),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dispute Reason:',
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.red,
                  ),
                ),
                SizedBox(height: 0.5.h),
                Text(
                  disputeReason,
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    color: AppTheme.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: Icon(Icons.psychology, size: 5.w),
                  label: Text('AI Mediation'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryLight,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: Icon(Icons.visibility, size: 5.w),
                  label: Text('View Details'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primaryLight,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      children: [
        Text(
          '$label: ',
          style: GoogleFonts.inter(
            fontSize: 12.sp,
            color: AppTheme.textSecondaryLight,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 12.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
