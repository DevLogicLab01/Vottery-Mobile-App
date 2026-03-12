import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import 'package:intl/intl.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class SettlementReconciliationWidget extends StatelessWidget {
  final List<Map<String, dynamic>> settlementHistory;
  final VoidCallback onRefresh;

  const SettlementReconciliationWidget({
    super.key,
    required this.settlementHistory,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (settlementHistory.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              size: 20.w,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            SizedBox(height: 2.h),
            Text(
              'No settlement history',
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
        itemCount: settlementHistory.length,
        itemBuilder: (context, index) {
          final settlement = settlementHistory[index];
          return _buildReconciliationCard(theme, settlement);
        },
      ),
    );
  }

  Widget _buildReconciliationCard(
    ThemeData theme,
    Map<String, dynamic> settlement,
  ) {
    final expectedAmount = settlement['expected_amount'] ?? 0.0;
    final actualAmount = settlement['actual_amount'] ?? 0.0;
    final discrepancy = actualAmount - expectedAmount;
    final zone = settlement['zone'] ?? 'Unknown';
    final completedAt = settlement['completed_at'] != null
        ? DateTime.parse(settlement['completed_at'])
        : DateTime.now();

    final hasDiscrepancy = discrepancy.abs() > 0.01;

    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: hasDiscrepancy
              ? AppTheme.errorLight
              : theme.colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                zone.replaceAll('_', ' '),
                style: GoogleFonts.inter(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              if (hasDiscrepancy)
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 2.w,
                    vertical: 0.5.h,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.errorLight,
                    borderRadius: BorderRadius.circular(4.0),
                  ),
                  child: Text(
                    'DISCREPANCY',
                    style: GoogleFonts.inter(
                      fontSize: 9.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 2.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Expected',
                    style: GoogleFonts.inter(
                      fontSize: 10.sp,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    '\$${expectedAmount.toStringAsFixed(2)}',
                    style: GoogleFonts.inter(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Actual',
                    style: GoogleFonts.inter(
                      fontSize: 10.sp,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    '\$${actualAmount.toStringAsFixed(2)}',
                    style: GoogleFonts.inter(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                      color: hasDiscrepancy
                          ? AppTheme.errorLight
                          : Colors.green,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (hasDiscrepancy) ...[
            SizedBox(height: 1.h),
            Container(
              padding: EdgeInsets.all(2.w),
              decoration: BoxDecoration(
                color: AppTheme.errorLight.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning, color: AppTheme.errorLight, size: 4.w),
                  SizedBox(width: 2.w),
                  Expanded(
                    child: Text(
                      'Discrepancy: ${discrepancy > 0 ? '+' : ''}\$${discrepancy.toStringAsFixed(2)}',
                      style: GoogleFonts.inter(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.errorLight,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          SizedBox(height: 1.h),
          Text(
            'Completed: ${DateFormat('MMM dd, yyyy HH:mm').format(completedAt)}',
            style: GoogleFonts.inter(
              fontSize: 10.sp,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
