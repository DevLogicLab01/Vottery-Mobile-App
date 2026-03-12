import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

class FeedEngagementLeaderboardWidget extends StatelessWidget {
  final List<Map<String, dynamic>> topEngagers;

  const FeedEngagementLeaderboardWidget({super.key, required this.topEngagers});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF1E1E2E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      margin: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.leaderboard,
                  color: Color(0xFFFFD700),
                  size: 20,
                ),
                SizedBox(width: 2.w),
                Text(
                  'Feed Leaderboard',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(
                  'This Week',
                  style: GoogleFonts.inter(
                    color: Colors.white54,
                    fontSize: 10.sp,
                  ),
                ),
              ],
            ),
            SizedBox(height: 1.5.h),
            if (topEngagers.isEmpty)
              Center(
                child: Text(
                  'No leaderboard data',
                  style: GoogleFonts.inter(
                    color: Colors.white38,
                    fontSize: 11.sp,
                  ),
                ),
              )
            else
              ...topEngagers.take(5).toList().asMap().entries.map((entry) {
                final rank = entry.key + 1;
                final user = entry.value;
                final rankColors = [
                  const Color(0xFFFFD700),
                  const Color(0xFFC0C0C0),
                  const Color(0xFFCD7F32),
                  Colors.white54,
                  Colors.white54,
                ];
                final rankColor = rankColors[entry.key];

                return Padding(
                  padding: EdgeInsets.only(bottom: 1.h),
                  child: Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: rankColor.withAlpha(30),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '#$rank',
                            style: GoogleFonts.inter(
                              color: rankColor,
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 2.w),
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: const Color(0xFF6C63FF),
                        child: Text(
                          (user['username']?.toString() ?? 'U')
                              .substring(0, 1)
                              .toUpperCase(),
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      SizedBox(width: 2.w),
                      Expanded(
                        child: Text(
                          user['username']?.toString() ?? 'Anonymous',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 12.sp,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '${user['feed_vp_earned'] ?? 0} VP',
                        style: GoogleFonts.inter(
                          color: const Color(0xFFFFD700),
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}