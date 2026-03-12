import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

class FeedProgressionWidget extends StatelessWidget {
  final Map<String, dynamic>? feedProgression;
  final Map<String, dynamic>? feedStreak;

  const FeedProgressionWidget({
    super.key,
    this.feedProgression,
    this.feedStreak,
  });

  @override
  Widget build(BuildContext context) {
    final levelTier =
        feedProgression?['level_tier'] as String? ?? 'bronze_explorer';
    final totalInteractions =
        feedProgression?['total_interactions'] as int? ?? 0;
    final vpMultiplier = feedProgression?['vp_multiplier'] as double? ?? 1.00;
    final currentStreak = feedStreak?['current_streak'] as int? ?? 0;

    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _getLevelGradient(levelTier),
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Level Badge
              Container(
                padding: EdgeInsets.all(3.w),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(51),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getLevelIcon(levelTier),
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
                      _getLevelTitle(levelTier),
                      style: GoogleFonts.inter(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '$totalInteractions interactions • ${vpMultiplier}x VP',
                      style: GoogleFonts.inter(
                        fontSize: 11.sp,
                        color: Colors.white.withAlpha(230),
                      ),
                    ),
                  ],
                ),
              ),
              // Streak Badge
              if (currentStreak > 0)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(51),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.local_fire_department,
                        color: Colors.orange,
                        size: 18,
                      ),
                      SizedBox(width: 1.w),
                      Text(
                        '$currentStreak',
                        style: GoogleFonts.inter(
                          fontSize: 13.sp,
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
          // Progress to Next Level
          _buildProgressToNextLevel(levelTier, totalInteractions),
        ],
      ),
    );
  }

  Widget _buildProgressToNextLevel(String levelTier, int totalInteractions) {
    final Map<String, int> levelThresholds = {
      'bronze_explorer': 500,
      'silver_engager': 2000,
      'gold_influencer': 999999,
    };

    final nextThreshold = levelThresholds[levelTier] ?? 500;
    if (levelTier == 'gold_influencer') {
      return Container(
        padding: EdgeInsets.all(2.w),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(51),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.emoji_events, color: Colors.white, size: 20),
            SizedBox(width: 2.w),
            Text(
              'Max Level Reached!',
              style: GoogleFonts.inter(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    final progress = (totalInteractions / nextThreshold).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Next Level',
              style: GoogleFonts.inter(
                fontSize: 11.sp,
                color: Colors.white.withAlpha(230),
              ),
            ),
            Text(
              '$totalInteractions / $nextThreshold',
              style: GoogleFonts.inter(
                fontSize: 11.sp,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
        SizedBox(height: 1.h),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.white.withAlpha(77),
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            minHeight: 8,
          ),
        ),
      ],
    );
  }

  List<Color> _getLevelGradient(String levelTier) {
    switch (levelTier) {
      case 'bronze_explorer':
        return [const Color(0xFFCD7F32), const Color(0xFF8B4513)];
      case 'silver_engager':
        return [const Color(0xFFC0C0C0), const Color(0xFF808080)];
      case 'gold_influencer':
        return [const Color(0xFFFFD700), const Color(0xFFFFA500)];
      default:
        return [const Color(0xFF6A11CB), const Color(0xFF2575FC)];
    }
  }

  IconData _getLevelIcon(String levelTier) {
    switch (levelTier) {
      case 'bronze_explorer':
        return Icons.explore;
      case 'silver_engager':
        return Icons.people;
      case 'gold_influencer':
        return Icons.star;
      default:
        return Icons.emoji_events;
    }
  }

  String _getLevelTitle(String levelTier) {
    switch (levelTier) {
      case 'bronze_explorer':
        return 'Bronze Feed Explorer';
      case 'silver_engager':
        return 'Silver Engager';
      case 'gold_influencer':
        return 'Gold Influencer';
      default:
        return 'Feed Explorer';
    }
  }
}
