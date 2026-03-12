import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

class AdStreakWidget extends StatelessWidget {
  final Map<String, dynamic>? adStreak;

  const AdStreakWidget({super.key, this.adStreak});

  @override
  Widget build(BuildContext context) {
    final currentStreak = adStreak?['current_streak'] as int? ?? 0;
    final longestStreak = adStreak?['longest_streak'] as int? ?? 0;
    final streakMultiplier = adStreak?['streak_multiplier'] as double? ?? 2.00;

    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFF6B6B), Color(0xFFFF8E53)],
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(2.w),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(51),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.local_fire_department,
              color: Colors.white,
              size: 32,
            ),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ad Voting Streak',
                  style: GoogleFonts.inter(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                Text(
                  '$currentStreak days • ${streakMultiplier}x VP multiplier',
                  style: GoogleFonts.inter(
                    fontSize: 11.sp,
                    color: Colors.white.withAlpha(230),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(51),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                Text(
                  'Best',
                  style: GoogleFonts.inter(
                    fontSize: 9.sp,
                    color: Colors.white.withAlpha(204),
                  ),
                ),
                Text(
                  '$longestStreak',
                  style: GoogleFonts.inter(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
