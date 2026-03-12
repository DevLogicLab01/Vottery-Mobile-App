import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

class VPTransactionLoggingWidget extends StatelessWidget {
  final List<Map<String, dynamic>> transactions;
  final VoidCallback onRefresh;

  const VPTransactionLoggingWidget({
    super.key,
    required this.transactions,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (transactions.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(8.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.receipt_long,
                size: 48.sp,
                color: Colors.grey.shade400,
              ),
              SizedBox(height: 2.h),
              Text(
                'No VP transactions logged yet',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14.sp),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: ListView.builder(
        padding: EdgeInsets.all(4.w),
        itemCount: transactions.length,
        itemBuilder: (context, index) {
          final tx = transactions[index];
          return _buildTransactionCard(context, tx);
        },
      ),
    );
  }

  Widget _buildTransactionCard(BuildContext context, Map<String, dynamic> tx) {
    final isVerified = tx['verification_status'] == 'verified';
    final vpAmount = tx['vp_amount'] ?? 0;
    final txHash = tx['transaction_hash'] ?? 'Pending...';
    final createdAt = DateTime.parse(tx['created_at']);

    return Card(
      margin: EdgeInsets.only(bottom: 2.h),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Container(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.account_balance_wallet,
                      color: Colors.blue.shade700,
                      size: 20.sp,
                    ),
                    SizedBox(width: 2.w),
                    Text(
                      'VP Transaction',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 2.w,
                    vertical: 0.5.h,
                  ),
                  decoration: BoxDecoration(
                    color: isVerified
                        ? Colors.green.shade100
                        : Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(6.0),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isVerified ? Icons.verified : Icons.pending,
                        size: 12.sp,
                        color: isVerified
                            ? Colors.green.shade700
                            : Colors.orange.shade700,
                      ),
                      SizedBox(width: 1.w),
                      Text(
                        isVerified ? 'Verified' : 'Pending',
                        style: TextStyle(
                          fontSize: 10.sp,
                          color: isVerified
                              ? Colors.green.shade700
                              : Colors.orange.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 2.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'VP Amount:',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.grey.shade600,
                  ),
                ),
                Text(
                  '$vpAmount VP',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber.shade900,
                  ),
                ),
              ],
            ),
            SizedBox(height: 1.h),
            Row(
              children: [
                Text(
                  'TX Hash: ',
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: Colors.grey.shade600,
                  ),
                ),
                Expanded(
                  child: Text(
                    txHash.length > 20
                        ? '${txHash.substring(0, 20)}...'
                        : txHash,
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: Colors.blue.shade700,
                      fontFamily: 'monospace',
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.copy, size: 16.sp),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: txHash));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Transaction hash copied')),
                    );
                  },
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(),
                ),
              ],
            ),
            SizedBox(height: 1.h),
            Text(
              'Date: ${createdAt.toString().substring(0, 19)}',
              style: TextStyle(fontSize: 10.sp, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }
}
