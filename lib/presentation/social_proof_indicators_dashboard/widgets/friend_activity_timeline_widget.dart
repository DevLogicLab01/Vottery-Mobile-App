import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../../theme/app_theme.dart';

class FriendActivityTimelineWidget extends StatelessWidget {
  final List<Map<String, dynamic>> elections;

  const FriendActivityTimelineWidget({super.key, required this.elections});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.all(4.w),
      children: [
        Text(
          'Recent Friend Activity',
          style: GoogleFonts.inter(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 2.h),
        ...elections.expand((election) {
          final friendsVoted =
              election['friends_voted'] as List<dynamic>? ?? [];
          return friendsVoted.map(
            (friend) => _buildActivityItem(friend, election),
          );
        }),
      ],
    );
  }

  Widget _buildActivityItem(
    Map<String, dynamic> friend,
    Map<String, dynamic> election,
  ) {
    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundImage: NetworkImage(friend['avatar'] ?? ''),
            radius: 6.w,
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  friend['name'] ?? 'Unknown',
                  style: GoogleFonts.inter(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 0.5.h),
                Text(
                  'voted on ${election['title'] ?? 'Election'}',
                  style: GoogleFonts.inter(
                    fontSize: 11.sp,
                    color: AppTheme.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.check_circle, color: AppTheme.accentLight, size: 5.w),
        ],
      ),
    );
  }
}
