import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../../theme/app_theme.dart';

/// Widget displaying individual active tie card
class ActiveTieCardWidget extends StatelessWidget {
  final Map<String, dynamic> tieResult;
  final VoidCallback onScheduleRunoff;
  final VoidCallback onManualResolve;

  const ActiveTieCardWidget({
    super.key,
    required this.tieResult,
    required this.onScheduleRunoff,
    required this.onManualResolve,
  });

  @override
  Widget build(BuildContext context) {
    final election = tieResult['election'] as Map<String, dynamic>?;
    final tiedCandidates = List<Map<String, dynamic>>.from(
      tieResult['tied_candidates'] ?? [],
    );
    final tiedVoteCount = tieResult['tied_vote_count'] ?? 0;
    final resolutionStatus = tieResult['resolution_status'] ?? 'unresolved';

    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.orange.shade200, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 8.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(6.0),
                ),
                child: Text(
                  '🤝 Tied Results',
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.orange.shade800,
                  ),
                ),
              ),
              const Spacer(),
              _buildStatusBadge(resolutionStatus),
            ],
          ),
          SizedBox(height: 1.5.h),
          // Election Title
          Text(
            election?['title'] ?? 'Unknown Election',
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryLight,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 1.h),
          // Tied Candidates
          Text(
            'Tied Candidates:',
            style: GoogleFonts.inter(
              fontSize: 12.sp,
              fontWeight: FontWeight.w500,
              color: AppTheme.textSecondaryLight,
            ),
          ),
          SizedBox(height: 0.5.h),
          ...tiedCandidates.map(
            (candidate) => Padding(
              padding: EdgeInsets.only(bottom: 0.5.h),
              child: Row(
                children: [
                  Icon(Icons.person, size: 16.0, color: AppTheme.primaryLight),
                  SizedBox(width: 2.w),
                  Expanded(
                    child: Text(
                      candidate['option_title'] ?? 'Unknown',
                      style: GoogleFonts.inter(
                        fontSize: 13.sp,
                        color: AppTheme.textPrimaryLight,
                      ),
                    ),
                  ),
                  Text(
                    '$tiedVoteCount votes',
                    style: GoogleFonts.inter(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryLight,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 2.h),
          // Action Buttons
          if (resolutionStatus == 'unresolved') ...[
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onScheduleRunoff,
                    icon: const Icon(Icons.how_to_vote, size: 18.0),
                    label: Text(
                      'Schedule Runoff',
                      style: GoogleFonts.inter(fontSize: 12.sp),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryLight,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 1.2.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onManualResolve,
                    icon: const Icon(Icons.gavel, size: 18.0),
                    label: Text(
                      'Manual Resolve',
                      style: GoogleFonts.inter(fontSize: 12.sp),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primaryLight,
                      side: BorderSide(color: AppTheme.primaryLight),
                      padding: EdgeInsets.symmetric(vertical: 1.2.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String label;

    switch (status) {
      case 'unresolved':
        color = Colors.orange;
        label = 'Unresolved';
        break;
      case 'runoff_scheduled':
        color = Colors.blue;
        label = 'Runoff Scheduled';
        break;
      case 'manual_override':
        color = Colors.green;
        label = 'Manually Resolved';
        break;
      case 'lottery_resolved':
        color = Colors.purple;
        label = 'Lottery Resolved';
        break;
      default:
        color = Colors.grey;
        label = 'Unknown';
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(6.0),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 11.sp,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }
}
