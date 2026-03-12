import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

class FeedLeaderboardWidget extends StatelessWidget {
  final List<Map<String, dynamic>> leaderboardData;
  final String? currentUserId;

  const FeedLeaderboardWidget({
    super.key,
    required this.leaderboardData,
    this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    if (leaderboardData.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.leaderboard, size: 60, color: Colors.grey[400]),
            SizedBox(height: 2.h),
            Text(
              'No leaderboard data yet',
              style: GoogleFonts.inter(
                fontSize: 14.sp,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(2.w),
      itemCount: leaderboardData.length,
      itemBuilder: (context, index) {
        final entry = leaderboardData[index];
        final rank = index + 1;
        final isCurrentUser = entry['user_id'] == currentUserId;

        return Container(
          margin: EdgeInsets.only(bottom: 2.h),
          padding: EdgeInsets.all(3.w),
          decoration: BoxDecoration(
            color: isCurrentUser
                ? const Color(0xFF6A11CB).withAlpha(26)
                : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isCurrentUser
                  ? const Color(0xFF6A11CB)
                  : Colors.grey[300]!,
              width: isCurrentUser ? 2 : 1,
            ),
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
              // Rank Badge
              Container(
                width: 12.w,
                height: 12.w,
                decoration: BoxDecoration(
                  gradient: _getRankGradient(rank),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: rank <= 3
                      ? Icon(
                          rank == 1
                              ? Icons.emoji_events
                              : rank == 2
                              ? Icons.military_tech
                              : Icons.workspace_premium,
                          color: Colors.white,
                          size: 24,
                        )
                      : Text(
                          '$rank',
                          style: GoogleFonts.inter(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              SizedBox(width: 3.w),
              // User Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry['users']?['full_name'] ?? 'Anonymous User',
                      style: GoogleFonts.inter(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey[800],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${entry['total_interactions'] ?? 0} interactions',
                      style: GoogleFonts.inter(
                        fontSize: 11.sp,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              // VP Earned
              Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.stars, color: Colors.white, size: 14),
                    SizedBox(width: 1.w),
                    Text(
                      '${entry['total_vp_earned'] ?? 0}',
                      style: GoogleFonts.inter(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  LinearGradient _getRankGradient(int rank) {
    switch (rank) {
      case 1:
        return const LinearGradient(
          colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
        );
      case 2:
        return const LinearGradient(
          colors: [Color(0xFFC0C0C0), Color(0xFF808080)],
        );
      case 3:
        return const LinearGradient(
          colors: [Color(0xFFCD7F32), Color(0xFF8B4513)],
        );
      default:
        return const LinearGradient(
          colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
        );
    }
  }
}
