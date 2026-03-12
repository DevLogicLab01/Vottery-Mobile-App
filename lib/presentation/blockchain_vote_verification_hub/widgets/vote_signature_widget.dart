import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart' as google_fonts;
import 'package:sizer/sizer.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class VoteSignatureWidget extends StatelessWidget {
  final Map<String, dynamic> vote;

  const VoteSignatureWidget({super.key, required this.vote});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final electionTitle = vote['election_title'] ?? 'Election';
    final voteHash = vote['vote_hash'] ?? '';
    final digitalSignature = vote['digital_signature'] ?? '';
    final blockchainHash = vote['blockchain_hash'] ?? '';
    final timestamp = vote['timestamp'] ?? DateTime.now();
    final verificationStatus = vote['verification_status'] ?? 'pending';

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
            children: [
              Icon(Icons.verified_user, color: AppTheme.accentLight, size: 6.w),
              SizedBox(width: 3.w),
              Expanded(
                child: Text(
                  electionTitle,
                  style: google_fonts.GoogleFonts.inter(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
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
          _buildHashRow('Vote Hash', voteHash, theme),
          SizedBox(height: 1.h),
          _buildHashRow('Digital Signature', digitalSignature, theme),
          SizedBox(height: 1.h),
          _buildHashRow('Blockchain Hash', blockchainHash, theme),
          SizedBox(height: 2.h),
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
          ).copyWith(fontFamily: 'monospace'),
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
