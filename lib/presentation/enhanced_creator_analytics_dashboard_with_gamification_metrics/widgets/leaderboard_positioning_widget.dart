import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../../theme/app_theme.dart';

class LeaderboardPositioningWidget extends StatelessWidget {
  final Map<String, dynamic> leaderboardData;

  const LeaderboardPositioningWidget({
    super.key,
    required this.leaderboardData,
  });

  @override
  Widget build(BuildContext context) {
    final globalRank = leaderboardData['global_rank'] as int?;
    final regionalRank = leaderboardData['regional_rank'] as int?;
    final friendsRank = leaderboardData['friends_rank'] as int?;
    final rankChange = leaderboardData['rank_change'] as int? ?? 0;
    final percentile = leaderboardData['percentile'] as int? ?? 0;

    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Percentile header
          Container(
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.primaryLight, AppTheme.accentLight],
              ),
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your Percentile',
                      style: GoogleFonts.inter(
                        fontSize: 12.sp,
                        color: Colors.white70,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 0.5.h),
                    Row(
                      children: [
                        Text(
                          'Top $percentile%',
                          style: GoogleFonts.inter(
                            fontSize: 20.sp,
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (rankChange != 0) ...[
                          SizedBox(width: 2.w),
                          Icon(
                            rankChange > 0
                                ? Icons.arrow_upward
                                : Icons.arrow_downward,
                            color: rankChange > 0 ? Colors.green : Colors.red,
                            size: 5.w,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
                Icon(Icons.leaderboard, color: Colors.white, size: 10.w),
              ],
            ),
          ),
          SizedBox(height: 3.h),

          // Global leaderboard
          Text(
            'Leaderboard Rankings',
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          SizedBox(height: 2.h),
          _buildRankCard(
            'Global Leaderboard',
            globalRank,
            rankChange,
            Icons.public,
            AppTheme.primaryLight,
          ),
          SizedBox(height: 2.h),
          _buildRankCard(
            'Regional Leaderboard',
            regionalRank,
            0,
            Icons.location_on,
            Colors.orange,
          ),
          SizedBox(height: 2.h),
          _buildRankCard(
            'Friends Leaderboard',
            friendsRank,
            0,
            Icons.people,
            Colors.green,
          ),
          SizedBox(height: 3.h),

          // Rank change trend
          if (rankChange != 0) ...[
            Container(
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: rankChange > 0
                    ? Colors.green.withAlpha(26)
                    : Colors.red.withAlpha(26),
                borderRadius: BorderRadius.circular(12.0),
                border: Border.all(
                  color: rankChange > 0 ? Colors.green : Colors.red,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    rankChange > 0 ? Icons.trending_up : Icons.trending_down,
                    color: rankChange > 0 ? Colors.green : Colors.red,
                    size: 6.w,
                  ),
                  SizedBox(width: 3.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          rankChange > 0
                              ? 'You moved up ${rankChange.abs()} positions!'
                              : 'You moved down ${rankChange.abs()} positions',
                          style: GoogleFonts.inter(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                            color: rankChange > 0 ? Colors.green : Colors.red,
                          ),
                        ),
                        SizedBox(height: 0.5.h),
                        Text(
                          rankChange > 0
                              ? 'Keep up the great work!'
                              : 'Stay active to improve your rank',
                          style: GoogleFonts.inter(
                            fontSize: 10.sp,
                            color: AppTheme.textSecondaryLight,
                          ),
                        ),
                      ],
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

  Widget _buildRankCard(
    String title,
    int? rank,
    int rankChange,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(2.w),
            decoration: BoxDecoration(
              color: color.withAlpha(26),
              borderRadius: BorderRadius.circular(10.0),
            ),
            child: Icon(icon, color: color, size: 6.w),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimaryLight,
                  ),
                ),
                SizedBox(height: 0.5.h),
                Text(
                  rank != null ? 'Rank #$rank' : 'Not ranked yet',
                  style: GoogleFonts.inter(
                    fontSize: 10.sp,
                    color: AppTheme.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
          if (rank != null)
            Row(
              children: [
                Text(
                  '#$rank',
                  style: GoogleFonts.inter(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                if (rankChange != 0) ...[
                  SizedBox(width: 1.w),
                  Icon(
                    rankChange > 0 ? Icons.arrow_upward : Icons.arrow_downward,
                    color: rankChange > 0 ? Colors.green : Colors.red,
                    size: 4.w,
                  ),
                  Text(
                    '${rankChange.abs()}',
                    style: GoogleFonts.inter(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                      color: rankChange > 0 ? Colors.green : Colors.red,
                    ),
                  ),
                ],
              ],
            ),
        ],
      ),
    );
  }
}
