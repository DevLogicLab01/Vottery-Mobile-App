import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../theme/app_theme.dart';

class PayoutHistoryTrackingWidget extends StatefulWidget {
  final List<Map<String, dynamic>> transactions;
  final VoidCallback onLoadMore;

  const PayoutHistoryTrackingWidget({
    super.key,
    required this.transactions,
    required this.onLoadMore,
  });

  @override
  State<PayoutHistoryTrackingWidget> createState() =>
      _PayoutHistoryTrackingWidgetState();
}

class _PayoutHistoryTrackingWidgetState
    extends State<PayoutHistoryTrackingWidget> {
  String _selectedFilter = 'All';
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filteredTransactions {
    var filtered = widget.transactions;

    if (_selectedFilter != 'All') {
      filtered = filtered
          .where(
            (t) =>
                t['type']?.toString().toLowerCase() ==
                _selectedFilter.toLowerCase(),
          )
          .toList();
    }

    if (_searchController.text.isNotEmpty) {
      filtered = filtered
          .where(
            (t) =>
                t['description']?.toString().toLowerCase().contains(
                  _searchController.text.toLowerCase(),
                ) ??
                false,
          )
          .toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.cardLight,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 10.0,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Payout History',
                style: GoogleFonts.inter(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimaryLight,
                ),
              ),
              IconButton(
                icon: Icon(Icons.file_download, color: AppTheme.primaryLight),
                onPressed: _exportToCSV,
                tooltip: 'Export to CSV',
              ),
            ],
          ),
          SizedBox(height: 2.h),
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search transactions...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
              contentPadding: EdgeInsets.symmetric(vertical: 1.h),
            ),
            onChanged: (_) => setState(() {}),
          ),
          SizedBox(height: 2.h),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('All'),
                SizedBox(width: 2.w),
                _buildFilterChip('Redemptions'),
                SizedBox(width: 2.w),
                _buildFilterChip('Earnings'),
                SizedBox(width: 2.w),
                _buildFilterChip('Refunds'),
              ],
            ),
          ),
          SizedBox(height: 2.h),
          if (_filteredTransactions.isEmpty)
            _buildEmptyState()
          else
            ..._filteredTransactions.map((transaction) {
              return _buildTransactionCard(transaction);
            }),
          if (_filteredTransactions.length >= 20)
            Padding(
              padding: EdgeInsets.only(top: 2.h),
              child: Center(
                child: TextButton(
                  onPressed: widget.onLoadMore,
                  child: Text('Load More'),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _selectedFilter == label;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = label;
        });
      },
      selectedColor: AppTheme.primaryLight,
      labelStyle: GoogleFonts.inter(
        fontSize: 12.sp,
        fontWeight: FontWeight.w600,
        color: isSelected ? Colors.white : AppTheme.textPrimaryLight,
      ),
    );
  }

  Widget _buildTransactionCard(Map<String, dynamic> transaction) {
    final type = transaction['type'] ?? 'unknown';
    final amount = (transaction['amount'] ?? 0.0).toDouble();
    final status = transaction['status'] ?? 'pending';
    final date = transaction['created_at'] != null
        ? DateTime.parse(transaction['created_at'])
        : DateTime.now();
    final description = transaction['description'] ?? 'Transaction';

    final typeColor = _getTypeColor(type);
    final typeIcon = _getTypeIcon(type);
    final statusColor = _getStatusColor(status);

    return Card(
      margin: EdgeInsets.only(bottom: 2.h),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: ExpansionTile(
        leading: Container(
          padding: EdgeInsets.all(2.w),
          decoration: BoxDecoration(
            color: typeColor.withAlpha(26),
            shape: BoxShape.circle,
          ),
          child: Icon(typeIcon, color: typeColor, size: 20.sp),
        ),
        title: Text(
          description,
          style: GoogleFonts.inter(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          DateFormat('MMM dd, yyyy • hh:mm a').format(date),
          style: GoogleFonts.inter(
            fontSize: 11.sp,
            color: AppTheme.textSecondaryLight,
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${amount >= 0 ? '+' : ''}${amount.toStringAsFixed(0)} VP',
              style: GoogleFonts.inter(
                fontSize: 14.sp,
                fontWeight: FontWeight.w700,
                color: amount >= 0 ? AppTheme.accentLight : AppTheme.errorLight,
              ),
            ),
            SizedBox(height: 0.5.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.3.h),
              decoration: BoxDecoration(
                color: statusColor.withAlpha(26),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Text(
                status.toUpperCase(),
                style: GoogleFonts.inter(
                  fontSize: 9.sp,
                  fontWeight: FontWeight.w600,
                  color: statusColor,
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
                _buildDetailRow('Transaction ID', transaction['id'] ?? 'N/A'),
                SizedBox(height: 1.h),
                _buildDetailRow('Method', transaction['method'] ?? 'N/A'),
                SizedBox(height: 1.h),
                _buildDetailRow(
                  'USD Equivalent',
                  '\$${(amount * 0.005).toStringAsFixed(2)}',
                ),
                if (transaction['confirmation_number'] != null) ...[
                  SizedBox(height: 1.h),
                  _buildDetailRow(
                    'Confirmation',
                    transaction['confirmation_number'],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
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
            color: AppTheme.textPrimaryLight,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 48.sp,
              color: Colors.grey.shade400,
            ),
            SizedBox(height: 2.h),
            Text(
              'No transactions found',
              style: GoogleFonts.inter(
                fontSize: 14.sp,
                color: AppTheme.textSecondaryLight,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'redemption':
        return Colors.orange;
      case 'earnings':
        return AppTheme.accentLight;
      case 'refund':
        return AppTheme.secondaryLight;
      default:
        return Colors.grey;
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'redemption':
        return Icons.card_giftcard;
      case 'earnings':
        return Icons.trending_up;
      case 'refund':
        return Icons.replay;
      default:
        return Icons.receipt;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return AppTheme.accentLight;
      case 'pending':
        return AppTheme.warningLight;
      case 'failed':
        return AppTheme.errorLight;
      default:
        return Colors.grey;
    }
  }

  void _exportToCSV() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('CSV export will be sent to your email'),
        backgroundColor: AppTheme.accentLight,
      ),
    );
  }
}
