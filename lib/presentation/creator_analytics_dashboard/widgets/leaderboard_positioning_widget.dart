import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

class LeaderboardPositioningWidget extends StatelessWidget {
  final Map<String, dynamic> leaderboardData;

  const LeaderboardPositioningWidget({
    super.key,
    required this.leaderboardData,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 10.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Leaderboard Rankings',
            style: GoogleFonts.inter(
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 2.h),
          _buildGlobalRankCard(theme),
          SizedBox(height: 2.h),
          _buildRegionalRankCard(theme),
          SizedBox(height: 2.h),
          _buildFriendsRankCard(theme),
        ],
      ),
    );
  }

  Widget _buildGlobalRankCard(ThemeData theme) {
    final globalRank = leaderboardData['global_rank'] as int? ?? 0;
    final globalChange = leaderboardData['global_rank_change'] as int? ?? 0;
    final globalPercentile =
        leaderboardData['global_percentile'] as double? ?? 0.0;

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary.withAlpha(204),
            theme.colorScheme.secondary.withAlpha(204),
          ],
        ),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.public, color: Colors.white, size: 20.sp),
              SizedBox(width: 2.w),
              Text(
                'Global Leaderboard',
                style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '#$globalRank',
                style: GoogleFonts.inter(
                  fontSize: 32.sp,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: 2.w),
              _buildRankChangeIndicator(globalChange, Colors.white),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Top ${globalPercentile.toStringAsFixed(1)}%',
                    style: GoogleFonts.inter(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'of all users',
                    style: GoogleFonts.inter(
                      fontSize: 10.sp,
                      color: Colors.white70,
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

  Widget _buildRegionalRankCard(ThemeData theme) {
    final regionalRank = leaderboardData['regional_rank'] as int? ?? 0;
    final regionalChange = leaderboardData['regional_rank_change'] as int? ?? 0;
    final region = leaderboardData['region'] as String? ?? 'Region';

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.blue.withAlpha(26),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.blue, width: 2.0),
      ),
      child: Row(
        children: [
          Icon(Icons.location_on, color: Colors.blue, size: 24.sp),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$region Leaderboard',
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                SizedBox(height: 0.5.h),
                Row(
                  children: [
                    Text(
                      '#$regionalRank',
                      style: GoogleFonts.inter(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.blue,
                      ),
                    ),
                    SizedBox(width: 2.w),
                    _buildRankChangeIndicator(regionalChange, Colors.blue),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFriendsRankCard(ThemeData theme) {
    final friendsRank = leaderboardData['friends_rank'] as int? ?? 0;
    final friendsChange = leaderboardData['friends_rank_change'] as int? ?? 0;
    final totalFriends = leaderboardData['total_friends'] as int? ?? 0;

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.green.withAlpha(26),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.green, width: 2.0),
      ),
      child: Row(
        children: [
          Icon(Icons.groups, color: Colors.green, size: 24.sp),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Friends Leaderboard',
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                SizedBox(height: 0.5.h),
                Row(
                  children: [
                    Text(
                      '#$friendsRank',
                      style: GoogleFonts.inter(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.green,
                      ),
                    ),
                    SizedBox(width: 2.w),
                    _buildRankChangeIndicator(friendsChange, Colors.green),
                    const Spacer(),
                    Text(
                      'of $totalFriends',
                      style: GoogleFonts.inter(
                        fontSize: 10.sp,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRankChangeIndicator(int change, Color color) {
    if (change == 0) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
        decoration: BoxDecoration(
          color: Colors.grey.withAlpha(77),
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Text(
          '—',
          style: GoogleFonts.inter(
            fontSize: 10.sp,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      );
    }

    final isPositive = change > 0;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
      decoration: BoxDecoration(
        color: (isPositive ? Colors.green : Colors.red).withAlpha(51),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPositive ? Icons.arrow_upward : Icons.arrow_downward,
            size: 12.sp,
            color: isPositive ? Colors.green : Colors.red,
          ),
          SizedBox(width: 1.w),
          Text(
            change.abs().toString(),
            style: GoogleFonts.inter(
              fontSize: 10.sp,
              fontWeight: FontWeight.w600,
              color: isPositive ? Colors.green : Colors.red,
            ),
          ),
        ],
      ),
    );
  }
}
