import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class MarketplaceTransactionsWidget extends StatefulWidget {
  final List<Map<String, dynamic>> transactions;
  final VoidCallback onRefresh;

  const MarketplaceTransactionsWidget({
    super.key,
    required this.transactions,
    required this.onRefresh,
  });

  @override
  State<MarketplaceTransactionsWidget> createState() =>
      _MarketplaceTransactionsWidgetState();
}

class _MarketplaceTransactionsWidgetState
    extends State<MarketplaceTransactionsWidget> {
  String? _statusFilter;

  @override
  Widget build(BuildContext context) {
    final filteredTransactions = _statusFilter == null
        ? widget.transactions
        : widget.transactions
              .where((t) => t['transaction_status'] == _statusFilter)
              .toList();

    return Column(
      children: [
        _buildStatusFilter(),
        Expanded(
          child: filteredTransactions.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: EdgeInsets.all(4.w),
                  itemCount: filteredTransactions.length,
                  itemBuilder: (context, index) {
                    return _buildTransactionCard(filteredTransactions[index]);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildStatusFilter() {
    final statuses = ['All', 'Pending', 'In Progress', 'Completed', 'Disputed'];

    return SizedBox(
      height: 5.h,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.all(4.w),
        itemCount: statuses.length,
        itemBuilder: (context, index) {
          final status = statuses[index];
          final isSelected =
              (_statusFilter == null && status == 'All') ||
              _statusFilter == status.toLowerCase().replaceAll(' ', '_');

          return Padding(
            padding: EdgeInsets.only(right: 2.w),
            child: ChoiceChip(
              label: Text(status),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _statusFilter = status == 'All'
                      ? null
                      : status.toLowerCase().replaceAll(' ', '_');
                });
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildTransactionCard(Map<String, dynamic> transaction) {
    final serviceTitle =
        transaction['marketplace_services']?['title'] ?? 'Unknown Service';
    final buyerName =
        transaction['user_profiles']?['full_name'] ?? 'Unknown Buyer';
    final amountPaid = transaction['amount_paid'] ?? 0.0;
    final creatorEarnings = transaction['creator_earnings'] ?? 0.0;
    final status = transaction['transaction_status'] ?? 'pending';
    final tierSelected = transaction['tier_selected'] ?? 'Standard';

    return Card(
      margin: EdgeInsets.only(bottom: 2.h),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: _getStatusColor(status).withAlpha(26),
          child: Icon(
            _getStatusIcon(status),
            color: _getStatusColor(status),
            size: 6.w,
          ),
        ),
        title: Text(
          serviceTitle,
          style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          'Buyer: $buyerName • $tierSelected',
          style: TextStyle(fontSize: 12.sp),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '\$${creatorEarnings.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w700,
                color: AppTheme.accentLight,
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.3.h),
              decoration: BoxDecoration(
                color: _getStatusColor(status).withAlpha(26),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Text(
                _formatStatus(status),
                style: TextStyle(
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w600,
                  color: _getStatusColor(status),
                ),
              ),
            ),
          ],
        ),
        children: [
          Padding(
            padding: EdgeInsets.all(4.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow(
                  'Total Amount',
                  '\$${amountPaid.toStringAsFixed(2)}',
                ),
                SizedBox(height: 1.h),
                _buildInfoRow(
                  'Your Earnings',
                  '\$${creatorEarnings.toStringAsFixed(2)}',
                ),
                SizedBox(height: 1.h),
                _buildInfoRow(
                  'Platform Fee',
                  '\$${(amountPaid - creatorEarnings).toStringAsFixed(2)}',
                ),
                SizedBox(height: 2.h),
                if (status == 'pending' || status == 'in_progress')
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {},
                      child: Text('Update Status'),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 12.sp, color: AppTheme.textSecondaryLight),
        ),
        Text(
          value,
          style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 15.w,
            color: AppTheme.textSecondaryLight,
          ),
          SizedBox(height: 2.h),
          Text(
            'No transactions yet',
            style: TextStyle(
              fontSize: 14.sp,
              color: AppTheme.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'completed':
        return Icons.check_circle;
      case 'in_progress':
        return Icons.pending;
      case 'disputed':
        return Icons.warning;
      default:
        return Icons.schedule;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'completed':
        return Colors.green;
      case 'in_progress':
        return Colors.blue;
      case 'disputed':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  String _formatStatus(String status) {
    return status
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) {
          return word[0].toUpperCase() + word.substring(1);
        })
        .join(' ');
  }
}
