import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../services/marketplace_dispute_service.dart';
import '../../../theme/app_theme.dart';

class RefundProcessingWidget extends StatefulWidget {
  final List<Map<String, dynamic>> pendingRefunds;
  final VoidCallback onRefresh;

  const RefundProcessingWidget({
    super.key,
    required this.pendingRefunds,
    required this.onRefresh,
  });

  @override
  State<RefundProcessingWidget> createState() => _RefundProcessingWidgetState();
}

class _RefundProcessingWidgetState extends State<RefundProcessingWidget> {
  final MarketplaceDisputeService _disputeService =
      MarketplaceDisputeService.instance;
  bool _isProcessing = false;

  Future<void> _processRefund(Map<String, dynamic> refund) async {
    setState(() => _isProcessing = true);

    try {
      final success = await _disputeService.processAutomatedRefund(
        transactionId: refund['id'],
        refundAmount: refund['amount_usd'] ?? 0.0,
        reason: refund['refund_reason'] ?? 'Dispute resolution',
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Refund processed successfully'),
            backgroundColor: Colors.green,
          ),
        );
        widget.onRefresh();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Refund processing failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.pendingRefunds.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 20.w, color: Colors.green),
            SizedBox(height: 2.h),
            Text(
              'No Pending Refunds',
              style: GoogleFonts.inter(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              'All refunds have been processed',
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
      itemCount: widget.pendingRefunds.length,
      itemBuilder: (context, index) {
        return _buildRefundCard(widget.pendingRefunds[index]);
      },
    );
  }

  Widget _buildRefundCard(Map<String, dynamic> refund) {
    final userName = refund['user_profiles']?['full_name'] ?? 'Unknown User';
    final amountUsd = refund['amount_usd'] ?? 0.0;
    final refundReason = refund['refund_reason'] ?? 'No reason provided';
    final refundStatus = refund['refund_status'] ?? 'pending';

    final statusColor = refundStatus == 'processing'
        ? Colors.blue
        : refundStatus == 'pending'
        ? Colors.orange
        : Colors.green;

    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.undo, color: statusColor, size: 6.w),
              SizedBox(width: 3.w),
              Expanded(
                child: Text(
                  userName,
                  style: GoogleFonts.inter(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Text(
                  refundStatus.toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Container(
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Row(
              children: [
                Icon(Icons.attach_money, color: Colors.green, size: 8.w),
                SizedBox(width: 2.w),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Refund Amount',
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
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 2.h),
          Container(
            padding: EdgeInsets.all(2.w),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Refund Reason:',
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 0.5.h),
                Text(
                  refundReason,
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    color: AppTheme.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
          if (refundStatus == 'pending') ...[
            SizedBox(height: 2.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isProcessing ? null : () => _processRefund(refund),
                icon: _isProcessing
                    ? SizedBox(
                        width: 20.0,
                        height: 20.0,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.0,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : Icon(Icons.check_circle),
                label: Text(_isProcessing ? 'Processing...' : 'Process Refund'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
