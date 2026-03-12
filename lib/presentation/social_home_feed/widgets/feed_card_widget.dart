import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

/// Feed card for friend voting activities with quick-vote options
class FeedCardWidget extends StatelessWidget {
  final Map<String, dynamic> activity;
  final Function(String) onQuickVote;

  const FeedCardWidget({
    super.key,
    required this.activity,
    required this.onQuickVote,
  });

  @override
  Widget build(BuildContext context) {
    final voter = activity['voter'] as Map<String, dynamic>?;
    final election = activity['election'] as Map<String, dynamic>?;
    final voterName =
        voter?['full_name'] as String? ?? voter?['email'] as String? ?? 'User';
    final electionTitle = election?['title'] as String? ?? 'Election';
    final createdAt = activity['created_at'] as String?;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: AppTheme.shadowLight,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with user info
          Padding(
            padding: EdgeInsets.all(3.w),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 5.w,
                  backgroundColor: AppTheme.primaryLight.withAlpha(26),
                  child: Text(
                    voterName.isNotEmpty ? voterName[0].toUpperCase() : 'U',
                    style: GoogleFonts.inter(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryLight,
                    ),
                  ),
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        voterName,
                        style: GoogleFonts.inter(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimaryLight,
                        ),
                      ),
                      Text(
                        'voted in $electionTitle',
                        style: GoogleFonts.inter(
                          fontSize: 12.sp,
                          color: AppTheme.textSecondaryLight,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Text(
                  _formatTime(createdAt),
                  style: GoogleFonts.inter(
                    fontSize: 11.sp,
                    color: AppTheme.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),

          // Quick vote button
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 2.h),
            child: ElevatedButton(
              onPressed: () => onQuickVote(election?['id'] as String? ?? ''),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryLight,
                foregroundColor: Colors.white,
                minimumSize: Size(double.infinity, 5.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CustomIconWidget(
                    iconName: 'how_to_vote',
                    size: 4.w,
                    color: Colors.white,
                  ),
                  SizedBox(width: 2.w),
                  Text(
                    'Quick Vote (+10 VP)',
                    style: GoogleFonts.inter(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Engagement actions
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
            child: Row(
              children: [
                _buildActionButton('thumb_up', '12', () {}),
                SizedBox(width: 4.w),
                _buildActionButton('comment', '5', () {}),
                SizedBox(width: 4.w),
                _buildActionButton('share', '3', () {}),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(String iconName, String count, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          CustomIconWidget(
            iconName: iconName,
            size: 4.w,
            color: AppTheme.textSecondaryLight,
          ),
          SizedBox(width: 1.w),
          Text(
            count,
            style: GoogleFonts.inter(
              fontSize: 12.sp,
              color: AppTheme.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(String? timestamp) {
    if (timestamp == null) return '';
    try {
      final dateTime = DateTime.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inMinutes < 60) {
        return '${difference.inMinutes}m';
      } else if (difference.inHours < 24) {
        return '${difference.inHours}h';
      } else {
        return '${difference.inDays}d';
      }
    } catch (e) {
      return '';
    }
  }
}
