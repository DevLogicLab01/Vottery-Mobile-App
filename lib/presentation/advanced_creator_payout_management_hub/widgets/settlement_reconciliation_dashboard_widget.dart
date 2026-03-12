import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../services/reconciliation_service.dart';
import '../../../theme/app_theme.dart';

class SettlementReconciliationDashboardWidget extends StatefulWidget {
  final Map<String, dynamic> reconciliationData;
  final VoidCallback onRefresh;

  const SettlementReconciliationDashboardWidget({
    super.key,
    required this.reconciliationData,
    required this.onRefresh,
  });

  @override
  State<SettlementReconciliationDashboardWidget> createState() =>
      _SettlementReconciliationDashboardWidgetState();
}

class _SettlementReconciliationDashboardWidgetState
    extends State<SettlementReconciliationDashboardWidget> {
  final ReconciliationService _reconciliationService =
      ReconciliationService.instance;

  List<Map<String, dynamic>> _transactions = [];
  String _filterStatus = 'all';
  String _filterMethod = 'all';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    setState(() => _isLoading = true);

    try {
      final transactions = await _reconciliationService.getPayoutTransactions(
        status: _filterStatus == 'all' ? null : _filterStatus,
        paymentMethod: _filterMethod == 'all' ? null : _filterMethod,
      );

      setState(() {
        _transactions = transactions;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Load transactions error: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _exportToCSV() async {
    try {
      final success = await _reconciliationService.exportTransactionsToCSV(
        transactions: _transactions,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Transactions exported to CSV'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Export CSV error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to export transactions'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final matchedCount = widget.reconciliationData['matched_transactions'] ?? 0;
    final pendingCount = widget.reconciliationData['pending_transactions'] ?? 0;
    final discrepancyCount =
        widget.reconciliationData['discrepancy_count'] ?? 0;

    return Column(
      children: [
        _buildReconciliationHeader(
          matchedCount,
          pendingCount,
          discrepancyCount,
        ),
        _buildFilters(),
        Expanded(
          child: _isLoading
              ? Center(child: CircularProgressIndicator())
              : _buildTransactionsList(),
        ),
      ],
    );
  }

  Widget _buildReconciliationHeader(
    int matched,
    int pending,
    int discrepancies,
  ) {
    return Container(
      padding: EdgeInsets.all(4.w),
      color: AppTheme.surfaceLight,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Settlement Reconciliation',
                style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              IconButton(
                icon: Icon(Icons.download, size: 6.w),
                onPressed: _exportToCSV,
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              Expanded(
                child: _buildStatusCard(
                  'Matched',
                  matched.toString(),
                  Colors.green,
                  Icons.check_circle,
                ),
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: _buildStatusCard(
                  'Pending',
                  pending.toString(),
                  Colors.orange,
                  Icons.pending,
                ),
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: _buildStatusCard(
                  'Discrepancies',
                  discrepancies.toString(),
                  Colors.red,
                  Icons.error,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(
    String label,
    String count,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: color),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 6.w),
          SizedBox(height: 0.5.h),
          Text(
            count,
            style: GoogleFonts.inter(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10.sp,
              color: AppTheme.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: EdgeInsets.all(3.w),
      color: AppTheme.backgroundLight,
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<String>(
              initialValue: _filterStatus,
              decoration: InputDecoration(
                labelText: 'Status',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 3.w,
                  vertical: 1.h,
                ),
              ),
              items: [
                DropdownMenuItem(value: 'all', child: Text('All')),
                DropdownMenuItem(value: 'matched', child: Text('Matched')),
                DropdownMenuItem(value: 'pending', child: Text('Pending')),
                DropdownMenuItem(
                  value: 'discrepancy',
                  child: Text('Discrepancy'),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _filterStatus = value);
                  _loadTransactions();
                }
              },
            ),
          ),
          SizedBox(width: 2.w),
          Expanded(
            child: DropdownButtonFormField<String>(
              initialValue: _filterMethod,
              decoration: InputDecoration(
                labelText: 'Method',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 3.w,
                  vertical: 1.h,
                ),
              ),
              items: [
                DropdownMenuItem(value: 'all', child: Text('All')),
                DropdownMenuItem(value: 'stripe', child: Text('Stripe')),
                DropdownMenuItem(value: 'trolley', child: Text('Trolley')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _filterMethod = value);
                  _loadTransactions();
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionsList() {
    if (_transactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long,
              size: 15.w,
              color: AppTheme.textSecondaryLight,
            ),
            SizedBox(height: 2.h),
            Text(
              'No transactions found',
              style: GoogleFonts.inter(
                fontSize: 13.sp,
                color: AppTheme.textSecondaryLight,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(4.w),
      itemCount: _transactions.length,
      itemBuilder: (context, index) {
        return _buildTransactionCard(_transactions[index]);
      },
    );
  }

  Widget _buildTransactionCard(Map<String, dynamic> transaction) {
    final amount = (transaction['amount'] ?? 0.0) as num;
    final method = transaction['payment_method'] ?? 'Unknown';
    final status = transaction['status'] ?? 'pending';
    final transactionId = transaction['transaction_id'] ?? 'N/A';
    final date = transaction['created_at'] != null
        ? DateTime.parse(transaction['created_at'] as String)
        : DateTime.now();

    final currencyFormat = NumberFormat.currency(
      symbol: r'$',
      decimalDigits: 2,
    );
    final dateFormat = DateFormat('MMM dd, yyyy');

    Color statusColor;
    IconData statusIcon;

    switch (status) {
      case 'matched':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'discrepancy':
        statusColor = Colors.red;
        statusIcon = Icons.error;
        break;
      default:
        statusColor = Colors.orange;
        statusIcon = Icons.pending;
    }

    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: statusColor.withAlpha(51)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                currencyFormat.format(amount),
                style: GoogleFonts.inter(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                decoration: BoxDecoration(
                  color: statusColor.withAlpha(26),
                  borderRadius: BorderRadius.circular(6.0),
                ),
                child: Row(
                  children: [
                    Icon(statusIcon, size: 4.w, color: statusColor),
                    SizedBox(width: 1.w),
                    Text(
                      status.toUpperCase(),
                      style: GoogleFonts.inter(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Row(
            children: [
              Icon(
                method.toLowerCase() == 'stripe'
                    ? Icons.credit_card
                    : Icons.account_balance,
                size: 4.w,
                color: AppTheme.textSecondaryLight,
              ),
              SizedBox(width: 2.w),
              Text(
                method,
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  color: AppTheme.textSecondaryLight,
                ),
              ),
            ],
          ),
          SizedBox(height: 0.5.h),
          Text(
            'Transaction ID: $transactionId',
            style: GoogleFonts.inter(
              fontSize: 11.sp,
              color: AppTheme.textSecondaryLight,
            ),
          ),
          Text(
            'Date: ${dateFormat.format(date)}',
            style: GoogleFonts.inter(
              fontSize: 11.sp,
              color: AppTheme.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }
}
