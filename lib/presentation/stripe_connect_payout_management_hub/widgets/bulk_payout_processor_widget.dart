import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../services/payout_management_service.dart';
import '../../../theme/app_theme.dart';

class BulkPayoutProcessorWidget extends StatefulWidget {
  const BulkPayoutProcessorWidget({super.key});

  @override
  State<BulkPayoutProcessorWidget> createState() =>
      _BulkPayoutProcessorWidgetState();
}

class _BulkPayoutProcessorWidgetState extends State<BulkPayoutProcessorWidget> {
  final PayoutManagementService _payoutService =
      PayoutManagementService.instance;

  bool _isLoading = true;
  bool _isProcessing = false;
  List<Map<String, dynamic>> _pendingPayouts = [];
  Set<String> _selectedPayoutIds = {};
  String _bulkAction = 'process_all';

  @override
  void initState() {
    super.initState();
    _loadPendingPayouts();
  }

  Future<void> _loadPendingPayouts() async {
    setState(() => _isLoading = true);

    try {
      final payouts = await _payoutService.getBulkPayoutQueue();

      setState(() {
        _pendingPayouts = payouts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _toggleSelectAll() {
    setState(() {
      if (_selectedPayoutIds.length == _pendingPayouts.length) {
        _selectedPayoutIds.clear();
      } else {
        _selectedPayoutIds = _pendingPayouts
            .map((p) => p['id'] as String)
            .toSet();
      }
    });
  }

  void _toggleSelection(String payoutId) {
    setState(() {
      if (_selectedPayoutIds.contains(payoutId)) {
        _selectedPayoutIds.remove(payoutId);
      } else {
        _selectedPayoutIds.add(payoutId);
      }
    });
  }

  Future<void> _processBulkAction() async {
    if (_selectedPayoutIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select at least one payout'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final totalAmount = _pendingPayouts
        .where((p) => _selectedPayoutIds.contains(p['id']))
        .fold<double>(0.0, (sum, p) => sum + (p['amount_usd'] ?? 0.0));

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirm Bulk Action'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Action: ${_bulkAction.replaceAll('_', ' ').toUpperCase()}',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 1.h),
            Text('Selected Payouts: ${_selectedPayoutIds.length}'),
            Text('Total Amount: \$${totalAmount.toStringAsFixed(2)}'),
            SizedBox(height: 2.h),
            Text(
              'This action cannot be undone. Continue?',
              style: GoogleFonts.inter(fontSize: 11.sp, color: Colors.red),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _executeBulkAction();
            },
            child: Text('Confirm'),
          ),
        ],
      ),
    );
  }

  Future<void> _executeBulkAction() async {
    setState(() => _isProcessing = true);

    try {
      final result = await _payoutService.processBulkPayouts(
        _selectedPayoutIds.toList(),
      );

      final successCount = result['success'] ?? 0;
      final failedCount = result['failed'] ?? 0;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Processed: $successCount succeeded, $failedCount failed',
            ),
            backgroundColor: failedCount > 0 ? Colors.orange : Colors.green,
          ),
        );

        setState(() {
          _selectedPayoutIds.clear();
          _isProcessing = false;
        });

        _loadPendingPayouts();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Bulk processing failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (_pendingPayouts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 25.w, color: Colors.green),
            SizedBox(height: 2.h),
            Text(
              'No Pending Payouts',
              style: GoogleFonts.inter(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimaryLight,
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              'All payouts have been processed',
              style: GoogleFonts.inter(
                fontSize: 12.sp,
                color: AppTheme.textSecondaryLight,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Bulk Action Bar
        Container(
          padding: EdgeInsets.all(3.w),
          color: AppTheme.primaryLight.withValues(alpha: 0.1),
          child: Column(
            children: [
              Row(
                children: [
                  Checkbox(
                    value: _selectedPayoutIds.length == _pendingPayouts.length,
                    onChanged: (_) => _toggleSelectAll(),
                    activeColor: AppTheme.primaryLight,
                  ),
                  Text(
                    '${_selectedPayoutIds.length} selected',
                    style: GoogleFonts.inter(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Spacer(),
                  if (_selectedPayoutIds.isNotEmpty)
                    Text(
                      'Total: \$${_pendingPayouts.where((p) => _selectedPayoutIds.contains(p['id'])).fold<double>(0.0, (sum, p) => sum + (p['amount_usd'] ?? 0.0)).toStringAsFixed(2)}',
                      style: GoogleFonts.inter(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primaryLight,
                      ),
                    ),
                ],
              ),
              SizedBox(height: 1.h),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _bulkAction,
                      decoration: InputDecoration(
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 3.w,
                          vertical: 1.h,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      items: [
                        DropdownMenuItem(
                          value: 'process_all',
                          child: Text('Process All'),
                        ),
                        DropdownMenuItem(
                          value: 'hold_all',
                          child: Text('Hold All'),
                        ),
                        DropdownMenuItem(
                          value: 'approve_all',
                          child: Text('Approve All'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _bulkAction = value);
                        }
                      },
                    ),
                  ),
                  SizedBox(width: 3.w),
                  ElevatedButton(
                    onPressed: _isProcessing || _selectedPayoutIds.isEmpty
                        ? null
                        : _processBulkAction,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryLight,
                      padding: EdgeInsets.symmetric(
                        horizontal: 4.w,
                        vertical: 1.5.h,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    child: _isProcessing
                        ? SizedBox(
                            height: 2.h,
                            width: 2.h,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.0,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            'Execute',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Payout List
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.all(4.w),
            itemCount: _pendingPayouts.length,
            itemBuilder: (context, index) {
              final payout = _pendingPayouts[index];
              final payoutId = payout['id'];
              final amount = payout['amount_usd'] ?? 0.0;
              final creatorName = payout['creator']?['full_name'] ?? 'Unknown';
              final creatorEmail = payout['creator']?['email'] ?? '';
              final createdAt = payout['created_at'] != null
                  ? DateTime.parse(payout['created_at'])
                  : null;
              final isSelected = _selectedPayoutIds.contains(payoutId);

              return Card(
                margin: EdgeInsets.only(bottom: 2.h),
                elevation: isSelected ? 4 : 2,
                color: isSelected
                    ? AppTheme.primaryLight.withValues(alpha: 0.1)
                    : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  side: BorderSide(
                    color: isSelected
                        ? AppTheme.primaryLight
                        : Colors.transparent,
                    width: 2.0,
                  ),
                ),
                child: CheckboxListTile(
                  value: isSelected,
                  onChanged: (_) => _toggleSelection(payoutId),
                  activeColor: AppTheme.primaryLight,
                  title: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              creatorName,
                              style: GoogleFonts.inter(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimaryLight,
                              ),
                            ),
                            Text(
                              creatorEmail,
                              style: GoogleFonts.inter(
                                fontSize: 10.sp,
                                color: AppTheme.textSecondaryLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '\$${amount.toStringAsFixed(2)}',
                        style: GoogleFonts.inter(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primaryLight,
                        ),
                      ),
                    ],
                  ),
                  subtitle: createdAt != null
                      ? Text(
                          'Requested: ${DateFormat('MMM d, yyyy h:mm a').format(createdAt)}',
                          style: GoogleFonts.inter(
                            fontSize: 10.sp,
                            color: AppTheme.textSecondaryLight,
                          ),
                        )
                      : null,
                ),
              );
            },
          ),
        ),

        // Processing Progress Indicator
        if (_isProcessing)
          Container(
            padding: EdgeInsets.all(3.w),
            color: AppTheme.vibrantYellow.withValues(alpha: 0.2),
            child: Row(
              children: [
                SizedBox(
                  height: 5.w,
                  width: 5.w,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.0,
                    color: AppTheme.primaryLight,
                  ),
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: Text(
                    'Processing ${_selectedPayoutIds.length} payouts...',
                    style: GoogleFonts.inter(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimaryLight,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
