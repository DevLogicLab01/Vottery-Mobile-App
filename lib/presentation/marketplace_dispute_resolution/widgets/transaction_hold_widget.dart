import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../theme/app_theme.dart';

class TransactionHoldWidget extends StatelessWidget {
  final List<Map<String, dynamic>> heldTransactions;
  final VoidCallback onRefresh;

  const TransactionHoldWidget({
    super.key,
    required this.heldTransactions,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (heldTransactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_open, size: 20.w, color: Colors.green),
            SizedBox(height: 2.h),
            Text(
              'No Held Transactions',
              style: GoogleFonts.inter(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              'All transaction funds are flowing normally',
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
      itemCount: heldTransactions.length,
      itemBuilder: (context, index) {
        return _buildHeldTransactionCard(context, heldTransactions[index]);
      },
    );
  }

  Widget _buildHeldTransactionCard(
    BuildContext context,
    Map<String, dynamic> transaction,
  ) {
    final serviceTitle =
        transaction['marketplace_services']?['title'] ?? 'Unknown Service';
    final buyerName = transaction['buyer']?['full_name'] ?? 'Unknown Buyer';
    final sellerName = transaction['seller']?['full_name'] ?? 'Unknown Seller';
    final amountUsd = transaction['amount_usd'] ?? 0.0;
    final createdAt = transaction['created_at'] ?? '';

    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lock, color: Colors.amber, size: 6.w),
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
              Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Text(
                  'HELD',
                  style: GoogleFonts.inter(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber.shade800,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Container(
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.attach_money,
                  color: Colors.amber.shade800,
                  size: 8.w,
                ),
                SizedBox(width: 2.w),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Held Amount',
                      style: GoogleFonts.inter(
                        fontSize: 12.sp,
                        color: AppTheme.textSecondaryLight,
                      ),
                    ),
                    Text(
                      '\$${amountUsd.toStringAsFixed(2)}',
                      style: GoogleFonts.inter(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber.shade800,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 2.h),
          _buildInfoRow('Buyer', buyerName),
          SizedBox(height: 1.h),
          _buildInfoRow('Seller', sellerName),
          SizedBox(height: 1.h),
          _buildInfoRow('Held Since', createdAt.substring(0, 10)),
          SizedBox(height: 2.h),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: Icon(Icons.lock_open, size: 5.w),
                  label: Text('Release Funds'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: Icon(Icons.undo, size: 5.w),
                  label: Text('Refund'),
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
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
