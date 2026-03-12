import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class TransactionHistoryWidget extends StatelessWidget {
  final List<Map<String, dynamic>> transactions;
  final Function(String filter) onFilter;

  const TransactionHistoryWidget({
    super.key,
    required this.transactions,
    required this.onFilter,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Transaction History',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.filter_list),
                  onSelected: onFilter,
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'all', child: Text('All')),
                    const PopupMenuItem(
                      value: 'winnings',
                      child: Text('Winnings'),
                    ),
                    const PopupMenuItem(
                      value: 'redemptions',
                      child: Text('Redemptions'),
                    ),
                    const PopupMenuItem(
                      value: 'payouts',
                      child: Text('Payouts'),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 2.h),
            if (transactions.isEmpty)
              Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 3.h),
                  child: Text(
                    'No transactions yet',
                    style: TextStyle(fontSize: 13.sp, color: Colors.grey[600]),
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: transactions.length,
                itemBuilder: (context, index) {
                  final transaction = transactions[index];
                  return _buildTransactionCard(transaction);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionCard(Map<String, dynamic> transaction) {
    final type = transaction['type'] ?? 'unknown';
    final amount = (transaction['amount'] ?? 0.0).toDouble();
    final status = transaction['status'] ?? 'pending';
    final date = transaction['created_at'] ?? '';

    final color = type == 'winning'
        ? Colors.green
        : type == 'redemption'
        ? Colors.orange
        : Colors.blue;

    final icon = type == 'winning'
        ? Icons.emoji_events
        : type == 'redemption'
        ? Icons.card_giftcard
        : Icons.account_balance;

    return Card(
      margin: EdgeInsets.only(bottom: 1.h),
      child: ListTile(
        leading: Icon(icon, color: color, size: 28.sp),
        title: Text(
          type.toUpperCase(),
          style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '$date | Status: $status',
          style: TextStyle(fontSize: 11.sp, color: Colors.grey[600]),
        ),
        trailing: Text(
          '\$${amount.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ),
    );
  }
}
