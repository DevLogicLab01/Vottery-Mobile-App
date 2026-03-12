import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../theme/app_theme.dart';

class SocialProofElectionCardWidget extends StatelessWidget {
  final Map<String, dynamic> election;
  final VoidCallback onVote;
  final VoidCallback onViewFriends;

  const SocialProofElectionCardWidget({
    super.key,
    required this.election,
    required this.onVote,
    required this.onViewFriends,
  });

  @override
  Widget build(BuildContext context) {
    final friendsVoted = election['friends_voted'] as List<dynamic>? ?? [];
    final totalFriendVotes = election['total_friend_votes'] as int? ?? 0;
    final participationPercentage =
        election['friend_participation_percentage'] as double? ?? 0.0;

    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: AppTheme.primaryLight.withAlpha(51),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.shadowLight,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            election['title'] ?? 'Election',
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            'by ${election['creator'] ?? 'Unknown'}',
            style: GoogleFonts.inter(
              fontSize: 11.sp,
              color: AppTheme.textSecondaryLight,
            ),
          ),
          SizedBox(height: 2.h),
          // Friends Who Voted Avatar Stack
          if (friendsVoted.isNotEmpty) _buildAvatarStack(friendsVoted),
          SizedBox(height: 1.h),
          // Vote Count Badge
          _buildVoteCountBadge(totalFriendVotes),
          SizedBox(height: 1.h),
          // Participation Percentage
          _buildParticipationBar(participationPercentage),
          SizedBox(height: 2.h),
          // Action Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: onVote,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryLight,
                    minimumSize: Size(0, 5.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  child: Text(
                    'Vote Now',
                    style: GoogleFonts.inter(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 2.w),
              OutlinedButton(
                onPressed: onViewFriends,
                style: OutlinedButton.styleFrom(
                  minimumSize: Size(0, 5.h),
                  side: BorderSide(color: AppTheme.primaryLight),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                child: Text(
                  'View Friends',
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryLight,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarStack(List<dynamic> friends) {
    final displayCount = friends.length > 5 ? 5 : friends.length;
    final overflowCount = friends.length > 5 ? friends.length - 5 : 0;

    return GestureDetector(
      onTap: onViewFriends,
      child: Row(
        children: [
          SizedBox(
            width: (displayCount * 6.w) + (overflowCount > 0 ? 6.w : 0),
            height: 8.w,
            child: Stack(
              children: [
                ...List.generate(displayCount, (index) {
                  return Positioned(
                    left: index * 6.w,
                    child: Container(
                      width: 8.w,
                      height: 8.w,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: ClipOval(
                        child: CachedNetworkImage(
                          imageUrl: friends[index]['avatar'] ?? '',
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: AppTheme.surfaceLight,
                            child: Icon(
                              Icons.person,
                              size: 4.w,
                              color: AppTheme.textSecondaryLight,
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: AppTheme.surfaceLight,
                            child: Icon(
                              Icons.person,
                              size: 4.w,
                              color: AppTheme.textSecondaryLight,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
                if (overflowCount > 0)
                  Positioned(
                    left: displayCount * 6.w,
                    child: Container(
                      width: 8.w,
                      height: 8.w,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.primaryLight,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: Center(
                        child: Text(
                          '+$overflowCount',
                          style: GoogleFonts.inter(
                            fontSize: 9.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(width: 2.w),
          Text(
            'Friends who voted',
            style: GoogleFonts.inter(
              fontSize: 11.sp,
              color: AppTheme.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVoteCountBadge(int count) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.5.h),
      decoration: BoxDecoration(
        color: AppTheme.accentLight.withAlpha(26),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.people, size: 4.w, color: AppTheme.accentLight),
          SizedBox(width: 1.w),
          Text(
            '$count friends voted',
            style: GoogleFonts.inter(
              fontSize: 11.sp,
              fontWeight: FontWeight.w600,
              color: AppTheme.accentLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParticipationBar(double percentage) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Friend Participation',
              style: GoogleFonts.inter(
                fontSize: 11.sp,
                color: AppTheme.textSecondaryLight,
              ),
            ),
            Text(
              '${percentage.toStringAsFixed(0)}%',
              style: GoogleFonts.inter(
                fontSize: 11.sp,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryLight,
              ),
            ),
          ],
        ),
        SizedBox(height: 0.5.h),
        ClipRRect(
          borderRadius: BorderRadius.circular(4.0),
          child: LinearProgressIndicator(
            value: percentage / 100,
            minHeight: 0.8.h,
            backgroundColor: AppTheme.borderLight,
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryLight),
          ),
        ),
      ],
    );
  }
}
