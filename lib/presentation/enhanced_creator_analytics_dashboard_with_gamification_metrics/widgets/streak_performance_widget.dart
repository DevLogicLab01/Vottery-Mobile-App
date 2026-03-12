import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../../theme/app_theme.dart';

class StreakPerformanceWidget extends StatelessWidget {
  final Map<String, dynamic> streakData;

  const StreakPerformanceWidget({super.key, required this.streakData});

  @override
  Widget build(BuildContext context) {
    final votingStreak = streakData['voting_streak'] as int? ?? 0;
    final feedStreak = streakData['feed_streak'] as int? ?? 0;
    final adStreak = streakData['ad_streak'] as int? ?? 0;
    final joltsStreak = streakData['jolts_streak'] as int? ?? 0;
    final longestVotingStreak =
        streakData['longest_voting_streak'] as int? ?? 0;
    final streakMultiplier = streakData['streak_multiplier'] as double? ?? 1.0;

    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Streak multiplier header
          Container(
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.orange, Colors.deepOrange],
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
                      'Streak Multiplier',
                      style: GoogleFonts.inter(
                        fontSize: 12.sp,
                        color: Colors.white70,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 0.5.h),
                    Text(
                      '${streakMultiplier.toStringAsFixed(1)}x',
                      style: GoogleFonts.inter(
                        fontSize: 20.sp,
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                Icon(
                  Icons.local_fire_department,
                  color: Colors.white,
                  size: 10.w,
                ),
              ],
            ),
          ),
          SizedBox(height: 3.h),

          // Current streaks
          Text(
            'Current Streaks',
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          SizedBox(height: 2.h),
          _buildStreakCard(
            'Voting Streak',
            votingStreak,
            longestVotingStreak,
            Icons.how_to_vote,
            AppTheme.primaryLight,
          ),
          SizedBox(height: 2.h),
          _buildStreakCard(
            'Feed Streak',
            feedStreak,
            feedStreak,
            Icons.feed,
            Colors.green,
          ),
          SizedBox(height: 2.h),
          _buildStreakCard(
            'Ad Streak',
            adStreak,
            adStreak,
            Icons.ads_click,
            Colors.orange,
          ),
          SizedBox(height: 2.h),
          _buildStreakCard(
            'Jolts Streak',
            joltsStreak,
            joltsStreak,
            Icons.video_library,
            Colors.purple,
          ),
          SizedBox(height: 3.h),

          // Streak tips
          Container(
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: Colors.blue.withAlpha(26),
              borderRadius: BorderRadius.circular(12.0),
              border: Border.all(color: Colors.blue, width: 1),
            ),
            child: Row(
              children: [
                Icon(Icons.lightbulb, color: Colors.blue, size: 6.w),
                SizedBox(width: 3.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Streak Tips',
                        style: GoogleFonts.inter(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue,
                        ),
                      ),
                      SizedBox(height: 0.5.h),
                      Text(
                        'Maintain daily activity to increase your streak multiplier and earn bonus VP!',
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
      ),
    );
  }

  Widget _buildStreakCard(
    String title,
    int currentStreak,
    int longestStreak,
    IconData icon,
    Color color,
  ) {
    final progress = longestStreak > 0 ? currentStreak / longestStreak : 0.0;

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
      child: Column(
        children: [
          Row(
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
                      'Longest: $longestStreak days',
                      style: GoogleFonts.inter(
                        fontSize: 10.sp,
                        color: AppTheme.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  Icon(Icons.local_fire_department, color: color, size: 5.w),
                  SizedBox(width: 1.w),
                  Text(
                    '$currentStreak',
                    style: GoogleFonts.inter(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 2.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(10.0),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 1.h,
            ),
          ),
        ],
      ),
    );
  }
}
