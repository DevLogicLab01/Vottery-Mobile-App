import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

/// Election announcement widget with quick-vote CTA
class ElectionAnnouncementWidget extends StatelessWidget {
  final Map<String, dynamic> election;
  final Function(String) onQuickVote;

  const ElectionAnnouncementWidget({
    super.key,
    required this.election,
    required this.onQuickVote,
  });

  @override
  Widget build(BuildContext context) {
    final title = election['title'] as String? ?? 'Election';
    final description = election['description'] as String? ?? '';
    final deadline = election['deadline'] as String?;
    final voteCount = election['vote_count'] as int? ?? 0;

    return Container(
      margin: EdgeInsets.symmetric(vertical: 1.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: AppTheme.borderLight, width: 1),
          bottom: BorderSide(color: AppTheme.borderLight, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Election Badge
          Container(
            padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.5.h),
            decoration: BoxDecoration(
              color: AppTheme.primaryLight.withAlpha(26),
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.how_to_vote,
                  size: 4.w,
                  color: AppTheme.primaryLight,
                ),
                SizedBox(width: 1.w),
                Text(
                  'Active Election',
                  style: GoogleFonts.inter(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryLight,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 2.h),

          // Title
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          SizedBox(height: 1.h),

          // Description
          if (description.isNotEmpty)
            Text(
              description,
              style: GoogleFonts.inter(
                fontSize: 13.sp,
                color: AppTheme.textSecondaryLight,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          SizedBox(height: 2.h),

          // Stats Row
          Row(
            children: [
              Icon(Icons.people, size: 4.w, color: AppTheme.textSecondaryLight),
              SizedBox(width: 1.w),
              Text(
                '$voteCount votes',
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  color: AppTheme.textSecondaryLight,
                ),
              ),
              SizedBox(width: 4.w),
              Icon(
                Icons.access_time,
                size: 4.w,
                color: AppTheme.textSecondaryLight,
              ),
              SizedBox(width: 1.w),
              Text(
                _formatDeadline(deadline),
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  color: AppTheme.textSecondaryLight,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),

          // Quick Vote Button
          ElevatedButton(
            onPressed: () => onQuickVote(election['id'] as String),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryLight,
              foregroundColor: Colors.white,
              minimumSize: Size(double.infinity, 6.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.how_to_vote, size: 5.w),
                SizedBox(width: 2.w),
                Text(
                  'Vote Now (+10 VP)',
                  style: GoogleFonts.inter(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDeadline(String? deadline) {
    if (deadline == null) return 'No deadline';
    try {
      final dateTime = DateTime.parse(deadline);
      final now = DateTime.now();
      final difference = dateTime.difference(now);

      if (difference.inDays > 0) {
        return '${difference.inDays}d left';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h left';
      } else {
        return '${difference.inMinutes}m left';
      }
    } catch (e) {
      return 'No deadline';
    }
  }
}
