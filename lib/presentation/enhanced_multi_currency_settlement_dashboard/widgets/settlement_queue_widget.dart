import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import 'package:intl/intl.dart';

class SettlementQueueWidget extends StatelessWidget {
  final List<Map<String, dynamic>> settlementQueue;
  final VoidCallback onRefresh;

  const SettlementQueueWidget({
    super.key,
    required this.settlementQueue,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (settlementQueue.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 20.w,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            SizedBox(height: 2.h),
            Text(
              'No pending settlements',
              style: GoogleFonts.inter(
                fontSize: 13.sp,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: ListView.builder(
        padding: EdgeInsets.all(4.w),
        itemCount: settlementQueue.length,
        itemBuilder: (context, index) {
          final settlement = settlementQueue[index];
          return _buildSettlementCard(theme, settlement);
        },
      ),
    );
  }

  Widget _buildSettlementCard(
    ThemeData theme,
    Map<String, dynamic> settlement,
  ) {
    final amount = settlement['amount'] ?? 0.0;
    final zone = settlement['zone'] ?? 'Unknown';
    final status = settlement['status'] ?? 'pending';
    final paymentMethod = settlement['payment_method'] ?? 'bank_transfer';
    final createdAt = settlement['created_at'] != null
        ? DateTime.parse(settlement['created_at'])
        : DateTime.now();

    Color statusColor;
    IconData statusIcon;
    double progress;

    switch (status) {
      case 'completed':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        progress = 1.0;
        break;
      case 'processing':
        statusColor = Colors.orange;
        statusIcon = Icons.hourglass_empty;
        progress = 0.6;
        break;
      case 'failed':
        statusColor = Colors.red;
        statusIcon = Icons.error;
        progress = 0.0;
        break;
      default:
        statusColor = Colors.blue;
        statusIcon = Icons.pending;
        progress = 0.3;
    }

    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '\$${amount.toStringAsFixed(2)}',
                style: GoogleFonts.inter(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              Row(
                children: [
                  Icon(statusIcon, color: statusColor, size: 5.w),
                  SizedBox(width: 2.w),
                  Text(
                    status.toUpperCase(),
                    style: GoogleFonts.inter(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Row(
            children: [
              Icon(
                Icons.public,
                size: 4.w,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              SizedBox(width: 2.w),
              Text(
                zone.replaceAll('_', ' '),
                style: GoogleFonts.inter(
                  fontSize: 11.sp,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              SizedBox(width: 3.w),
              Icon(
                Icons.payment,
                size: 4.w,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              SizedBox(width: 2.w),
              Text(
                paymentMethod.replaceAll('_', ' '),
                style: GoogleFonts.inter(
                  fontSize: 11.sp,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Text(
            'Requested: ${DateFormat('MMM dd, yyyy HH:mm').format(createdAt)}',
            style: GoogleFonts.inter(
              fontSize: 10.sp,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: 1.h),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: theme.colorScheme.outline.withValues(alpha: 0.2),
            valueColor: AlwaysStoppedAnimation<Color>(statusColor),
          ),
        ],
      ),
    );
  }
}
