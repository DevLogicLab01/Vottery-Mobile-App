import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

class StreakPerformanceWidget extends StatelessWidget {
  final Map<String, dynamic> streakData;

  const StreakPerformanceWidget({super.key, required this.streakData});

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
            'Streak Performance',
            style: GoogleFonts.inter(
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 2.h),
          _buildStreakCard(
            'Voting Streak',
            streakData['voting_streak'] as int? ?? 0,
            streakData['voting_longest'] as int? ?? 0,
            streakData['voting_multiplier'] as double? ?? 1.0,
            Icons.how_to_vote,
            Colors.blue,
            theme,
          ),
          SizedBox(height: 2.h),
          _buildStreakCard(
            'Feed Streak',
            streakData['feed_streak'] as int? ?? 0,
            streakData['feed_longest'] as int? ?? 0,
            streakData['feed_multiplier'] as double? ?? 1.0,
            Icons.feed,
            Colors.green,
            theme,
          ),
          SizedBox(height: 2.h),
          _buildStreakCard(
            'Ad Streak',
            streakData['ad_streak'] as int? ?? 0,
            streakData['ad_longest'] as int? ?? 0,
            streakData['ad_multiplier'] as double? ?? 1.0,
            Icons.ads_click,
            Colors.orange,
            theme,
          ),
          SizedBox(height: 2.h),
          _buildStreakCard(
            'Jolts Streak',
            streakData['jolts_streak'] as int? ?? 0,
            streakData['jolts_longest'] as int? ?? 0,
            streakData['jolts_multiplier'] as double? ?? 1.0,
            Icons.video_library,
            Colors.purple,
            theme,
          ),
        ],
      ),
    );
  }

  Widget _buildStreakCard(
    String title,
    int currentStreak,
    int longestStreak,
    double multiplier,
    IconData icon,
    Color color,
    ThemeData theme,
  ) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withAlpha(51), color.withAlpha(26)],
        ),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: color, width: 2.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(2.w),
                decoration: BoxDecoration(
                  color: color.withAlpha(77),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 20.sp),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      'Current: $currentStreak days',
                      style: GoogleFonts.inter(
                        fontSize: 10.sp,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.local_fire_department,
                      color: Colors.white,
                      size: 16.sp,
                    ),
                    SizedBox(width: 1.w),
                    Text(
                      '${currentStreak}d',
                      style: GoogleFonts.inter(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStreakStat('Longest', '$longestStreak days', theme),
              _buildStreakStat(
                'Multiplier',
                '${multiplier.toStringAsFixed(1)}x VP',
                theme,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStreakStat(String label, String value, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 10.sp, color: Colors.grey[600]),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}
