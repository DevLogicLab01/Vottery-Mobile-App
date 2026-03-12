import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class TransactionHistoryWidget extends StatefulWidget {
  final List<Map<String, dynamic>> transactions;
  final String currency;
  final VoidCallback onRefresh;

  const TransactionHistoryWidget({
    super.key,
    required this.transactions,
    required this.currency,
    required this.onRefresh,
  });

  @override
  State<TransactionHistoryWidget> createState() =>
      _TransactionHistoryWidgetState();
}

class _TransactionHistoryWidgetState extends State<TransactionHistoryWidget> {
  String _selectedFilter = 'all';

  @override
  Widget build(BuildContext context) {
    final filteredTransactions = _selectedFilter == 'all'
        ? widget.transactions
        : widget.transactions
              .where((t) => t['type'] == _selectedFilter)
              .toList();

    return Column(
      children: [
        // Filter chips
        Padding(
          padding: EdgeInsets.all(3.w),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('All', 'all'),
                SizedBox(width: 2.w),
                _buildFilterChip('Winnings', 'winning'),
                SizedBox(width: 2.w),
                _buildFilterChip('Redemptions', 'redemption'),
                SizedBox(width: 2.w),
                _buildFilterChip('Payouts', 'payout'),
              ],
            ),
          ),
        ),

        // Transaction list
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async => widget.onRefresh(),
            child: filteredTransactions.isEmpty
                ? Center(
                    child: Text(
                      'No transactions found',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: 3.w),
                    itemCount: filteredTransactions.length,
                    itemBuilder: (context, index) {
                      return _buildTransactionItem(filteredTransactions[index]);
                    },
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, String filter) {
    final isSelected = _selectedFilter == filter;

    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = filter),
      child: Chip(
        label: Text(label),
        backgroundColor: isSelected ? Colors.blue : Colors.grey[200],
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : Colors.grey[700],
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildTransactionItem(Map<String, dynamic> transaction) {
    final type = transaction['type'] ?? '';
    final amount = transaction['amount'] ?? 0.0;
    final description = transaction['description'] ?? '';
    final createdAt = transaction['created_at'] ?? '';
    final isCredit = transaction['is_credit'] ?? false;

    return Padding(
      padding: EdgeInsets.only(bottom: 2.h),
      child: Container(
        padding: EdgeInsets.all(3.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(13),
              blurRadius: 5.0,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(2.w),
              decoration: BoxDecoration(
                color: isCredit
                    ? Colors.green.withAlpha(26)
                    : Colors.red.withAlpha(26),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Icon(
                isCredit ? Icons.add : Icons.remove,
                color: isCredit ? Colors.green : Colors.red,
                size: 20.sp,
              ),
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    createdAt,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            Text(
              '${isCredit ? '+' : '-'}\$${amount.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isCredit ? Colors.green : Colors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
