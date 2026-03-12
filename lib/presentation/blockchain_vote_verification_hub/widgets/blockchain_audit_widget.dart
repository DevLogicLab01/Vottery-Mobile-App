import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart' as google_fonts;
import 'package:sizer/sizer.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class BlockchainAuditWidget extends StatelessWidget {
  final List<Map<String, dynamic>> auditLogs;

  const BlockchainAuditWidget({super.key, required this.auditLogs});

  @override
  Widget build(BuildContext context) {
    if (auditLogs.isEmpty) {
      return Center(
        child: Text(
          'No blockchain audit logs',
          style: google_fonts.GoogleFonts.inter(
            fontSize: 14.sp,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(4.w),
      itemCount: auditLogs.length,
      itemBuilder: (context, index) {
        final log = auditLogs[index];
        return _buildAuditLogCard(context, log);
      },
    );
  }

  Widget _buildAuditLogCard(BuildContext context, Map<String, dynamic> log) {
    final theme = Theme.of(context);
    final blockHash = log['block_hash'] ?? '';
    final transactionHash = log['transaction_hash'] ?? '';
    final blockNumber = log['block_number'] ?? 0;
    final timestamp = log['timestamp'] ?? DateTime.now();
    final verificationStatus = log['verification_status'] ?? 'pending';
    final voteCount = log['vote_count'] ?? 0;

    return Container(
      margin: EdgeInsets.only(bottom: 3.h),
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
                  Icon(Icons.link, color: AppTheme.primaryLight, size: 6.w),
                  SizedBox(width: 3.w),
                  Text(
                    'Block #$blockNumber',
                    style: google_fonts.GoogleFonts.inter(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                decoration: BoxDecoration(
                  color: _getStatusColor(
                    verificationStatus,
                  ).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Text(
                  verificationStatus.toUpperCase(),
                  style: google_fonts.GoogleFonts.inter(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w600,
                    color: _getStatusColor(verificationStatus),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Divider(color: theme.colorScheme.outline.withValues(alpha: 0.2)),
          SizedBox(height: 2.h),
          _buildHashRow('Block Hash', blockHash, theme),
          SizedBox(height: 1.h),
          _buildHashRow('Transaction Hash', transactionHash, theme),
          SizedBox(height: 2.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.how_to_vote,
                    size: 4.w,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  SizedBox(width: 2.w),
                  Text(
                    '$voteCount votes',
                    style: google_fonts.GoogleFonts.inter(
                      fontSize: 11.sp,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 4.w,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  SizedBox(width: 2.w),
                  Text(
                    timeago.format(timestamp),
                    style: google_fonts.GoogleFonts.inter(
                      fontSize: 11.sp,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHashRow(String label, String hash, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: google_fonts.GoogleFonts.inter(
            fontSize: 11.sp,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        SizedBox(height: 0.5.h),
        Text(
          hash.length > 50 ? '${hash.substring(0, 50)}...' : hash,
          style: google_fonts.GoogleFonts.inter(
            fontSize: 10.sp,
            color: theme.colorScheme.onSurface,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'verified':
        return AppTheme.accentLight;
      case 'pending':
        return AppTheme.warningLight;
      case 'failed':
        return AppTheme.errorLight;
      default:
        return AppTheme.textSecondaryLight;
    }
  }
}
