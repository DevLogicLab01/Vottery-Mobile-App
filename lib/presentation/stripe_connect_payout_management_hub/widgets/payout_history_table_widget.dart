import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../services/payout_management_service.dart';
import '../../../theme/app_theme.dart';

class PayoutHistoryTableWidget extends StatefulWidget {
  const PayoutHistoryTableWidget({super.key});

  @override
  State<PayoutHistoryTableWidget> createState() =>
      _PayoutHistoryTableWidgetState();
}

class _PayoutHistoryTableWidgetState extends State<PayoutHistoryTableWidget> {
  final PayoutManagementService _payoutService =
      PayoutManagementService.instance;

  bool _isLoading = true;
  List<Map<String, dynamic>> _payouts = [];
  int _currentPage = 1;
  int _totalPayouts = 0;
  final int _pageSize = 50;

  String? _statusFilter;
  DateTime? _startDate;
  DateTime? _endDate;
  double? _minAmount;
  double? _maxAmount;

  Map<String, dynamic>? _selectedPayout;

  @override
  void initState() {
    super.initState();
    _loadPayoutHistory();
  }

  Future<void> _loadPayoutHistory() async {
    setState(() => _isLoading = true);

    try {
      final result = await _payoutService.getPayoutHistory(
        page: _currentPage,
        limit: _pageSize,
        statusFilter: _statusFilter,
        startDate: _startDate,
        endDate: _endDate,
      );

      setState(() {
        _payouts = result['payouts'] as List<Map<String, dynamic>>;
        _totalPayouts = result['total'] as int;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _exportToCSV() async {
    try {
      final csvData = await _payoutService.exportPayoutHistory();

      if (csvData != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payout history exported successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No data to export'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Filter Payouts'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Status',
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 1.h),
              DropdownButtonFormField<String?>(
                initialValue: _statusFilter,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 3.w,
                    vertical: 1.h,
                  ),
                ),
                items: [
                  DropdownMenuItem(value: null, child: Text('All')),
                  DropdownMenuItem(value: 'pending', child: Text('Pending')),
                  DropdownMenuItem(
                    value: 'in_transit',
                    child: Text('In Transit'),
                  ),
                  DropdownMenuItem(value: 'paid', child: Text('Paid')),
                  DropdownMenuItem(value: 'failed', child: Text('Failed')),
                  DropdownMenuItem(value: 'canceled', child: Text('Canceled')),
                ],
                onChanged: (value) {
                  setState(() => _statusFilter = value);
                },
              ),
              SizedBox(height: 2.h),
              Text(
                'Date Range',
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 1.h),
              Row(
                children: [
                  Expanded(
                    child: TextButton.icon(
                      onPressed: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _startDate ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (date != null) {
                          setState(() => _startDate = date);
                        }
                      },
                      icon: Icon(Icons.calendar_today, size: 4.w),
                      label: Text(
                        _startDate != null
                            ? DateFormat('MMM d').format(_startDate!)
                            : 'Start',
                        style: TextStyle(fontSize: 11.sp),
                      ),
                    ),
                  ),
                  Text('-'),
                  Expanded(
                    child: TextButton.icon(
                      onPressed: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _endDate ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (date != null) {
                          setState(() => _endDate = date);
                        }
                      },
                      icon: Icon(Icons.calendar_today, size: 4.w),
                      label: Text(
                        _endDate != null
                            ? DateFormat('MMM d').format(_endDate!)
                            : 'End',
                        style: TextStyle(fontSize: 11.sp),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _statusFilter = null;
                _startDate = null;
                _endDate = null;
              });
              Navigator.pop(context);
              _loadPayoutHistory();
            },
            child: Text('Clear'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _loadPayoutHistory();
            },
            child: Text('Apply'),
          ),
        ],
      ),
    );
  }

  void _showPayoutDetails(Map<String, dynamic> payout) {
    final amount = payout['amount_usd'] ?? 0.0;
    final stripeFee = (amount * 0.029) + 0.30;
    final netAmount = amount - stripeFee;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Payout Details'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Base Amount', '\$${amount.toStringAsFixed(2)}'),
              _buildDetailRow(
                'Stripe Fee (2.9% + \$0.30)',
                '\$${stripeFee.toStringAsFixed(2)}',
              ),
              Divider(),
              _buildDetailRow(
                'Net Payout',
                '\$${netAmount.toStringAsFixed(2)}',
                isBold: true,
              ),
              SizedBox(height: 2.h),
              _buildDetailRow('Status', payout['status'] ?? 'unknown'),
              _buildDetailRow(
                'Method',
                payout['payment_method'] ?? 'bank_transfer',
              ),
              _buildDetailRow(
                'Transaction ID',
                payout['stripe_payout_id'] ?? 'N/A',
              ),
              if (payout['created_at'] != null)
                _buildDetailRow(
                  'Created',
                  DateFormat(
                    'MMM d, yyyy h:mm a',
                  ).format(DateTime.parse(payout['created_at'])),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 0.5.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11.sp,
              color: AppTheme.textSecondaryLight,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 11.sp,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w400,
              color: AppTheme.textPrimaryLight,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalPages = (_totalPayouts / _pageSize).ceil();

    return Column(
      children: [
        // Filter and Export Bar
        Container(
          padding: EdgeInsets.all(3.w),
          color: Colors.grey[100],
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '$_totalPayouts total payouts',
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimaryLight,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.filter_list, color: AppTheme.primaryLight),
                onPressed: _showFilterDialog,
              ),
              IconButton(
                icon: Icon(Icons.download, color: AppTheme.primaryLight),
                onPressed: _exportToCSV,
              ),
            ],
          ),
        ),

        // Data Table
        Expanded(
          child: _isLoading
              ? Center(child: CircularProgressIndicator())
              : _payouts.isEmpty
              ? Center(
                  child: Text(
                    'No payouts found',
                    style: GoogleFonts.inter(
                      fontSize: 14.sp,
                      color: AppTheme.textSecondaryLight,
                    ),
                  ),
                )
              : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SingleChildScrollView(
                    child: DataTable(
                      columns: [
                        DataColumn(
                          label: Text(
                            'Date',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'Amount',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'Method',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'Status',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'Actions',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                      rows: _payouts.map((payout) {
                        final date = payout['created_at'] != null
                            ? DateFormat(
                                'MMM d, yyyy',
                              ).format(DateTime.parse(payout['created_at']))
                            : 'N/A';
                        final amount = payout['amount_usd'] ?? 0.0;
                        final method = payout['payment_method'] ?? 'N/A';
                        final status = payout['status'] ?? 'unknown';

                        Color statusColor;
                        switch (status) {
                          case 'paid':
                            statusColor = Colors.green;
                            break;
                          case 'pending':
                            statusColor = Colors.orange;
                            break;
                          case 'in_transit':
                            statusColor = Colors.blue;
                            break;
                          case 'failed':
                            statusColor = Colors.red;
                            break;
                          default:
                            statusColor = Colors.grey;
                        }

                        return DataRow(
                          cells: [
                            DataCell(Text(date)),
                            DataCell(Text('\$${amount.toStringAsFixed(2)}')),
                            DataCell(Text(method)),
                            DataCell(
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 2.w,
                                  vertical: 0.5.h,
                                ),
                                decoration: BoxDecoration(
                                  color: statusColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4.0),
                                ),
                                child: Text(
                                  status.toUpperCase(),
                                  style: GoogleFonts.inter(
                                    fontSize: 10.sp,
                                    fontWeight: FontWeight.w600,
                                    color: statusColor,
                                  ),
                                ),
                              ),
                            ),
                            DataCell(
                              IconButton(
                                icon: Icon(
                                  Icons.visibility,
                                  color: AppTheme.primaryLight,
                                ),
                                onPressed: () => _showPayoutDetails(payout),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
        ),

        // Pagination
        if (totalPages > 1)
          Container(
            padding: EdgeInsets.all(3.w),
            color: Colors.grey[100],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: Icon(Icons.chevron_left),
                  onPressed: _currentPage > 1
                      ? () {
                          setState(() => _currentPage--);
                          _loadPayoutHistory();
                        }
                      : null,
                ),
                Text(
                  'Page $_currentPage of $totalPages',
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.chevron_right),
                  onPressed: _currentPage < totalPages
                      ? () {
                          setState(() => _currentPage++);
                          _loadPayoutHistory();
                        }
                      : null,
                ),
              ],
            ),
          ),
      ],
    );
  }
}
