import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import 'package:intl/intl.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class PrizeDistributionDashboardWidget extends StatelessWidget {
  final List<Map<String, dynamic>> distributions;
  final VoidCallback onRefresh;

  const PrizeDistributionDashboardWidget({
    super.key,
    required this.distributions,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (distributions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.payments_outlined,
              size: 20.w,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            SizedBox(height: 2.h),
            Text(
              'No prize distributions',
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
        itemCount: distributions.length,
        itemBuilder: (context, index) {
          final distribution = distributions[index];
          return _buildDistributionCard(theme, distribution);
        },
      ),
    );
  }

  Widget _buildDistributionCard(
    ThemeData theme,
    Map<String, dynamic> distribution,
  ) {
    final position = distribution['position'] ?? 0;
    final prizeAmount = distribution['prize_amount'] ?? 0.0;
    final status = distribution['status'] ?? 'pending';
    final claimDeadline = distribution['claim_deadline'] != null
        ? DateTime.parse(distribution['claim_deadline'])
        : null;

    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (status) {
      case 'paid':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        statusText = 'PAID';
        break;
      case 'claimed':
        statusColor = Colors.blue;
        statusIcon = Icons.verified;
        statusText = 'CLAIMED';
        break;
      case 'notified':
        statusColor = Colors.orange;
        statusIcon = Icons.notifications_active;
        statusText = 'NOTIFIED';
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.pending;
        statusText = 'PENDING';
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
              Row(
                children: [
                  Container(
                    width: 10.w,
                    height: 10.w,
                    decoration: BoxDecoration(
                      color: AppTheme.accentLight.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Center(
                      child: Text(
                        '#$position',
                        style: GoogleFonts.inter(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.accentLight,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 3.w),
                  Text(
                    '\$${prizeAmount.toStringAsFixed(2)}',
                    style: GoogleFonts.inter(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Icon(statusIcon, color: statusColor, size: 5.w),
                  SizedBox(width: 2.w),
                  Text(
                    statusText,
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
          if (claimDeadline != null && status != 'paid') ...[
            SizedBox(height: 2.h),
            Container(
              padding: EdgeInsets.all(2.w),
              decoration: BoxDecoration(
                color: AppTheme.errorLight.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Row(
                children: [
                  Icon(Icons.schedule, color: AppTheme.errorLight, size: 4.w),
                  SizedBox(width: 2.w),
                  Text(
                    'Claim by: ${DateFormat('MMM dd, yyyy').format(claimDeadline)}',
                    style: GoogleFonts.inter(
                      fontSize: 11.sp,
                      color: AppTheme.errorLight,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
