import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

class GamificationScoreSummaryWidget extends StatelessWidget {
  final Map<String, dynamic> gamificationData;

  const GamificationScoreSummaryWidget({
    super.key,
    required this.gamificationData,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final lifetimeVP = gamificationData['lifetime_vp'] as int? ?? 0;
    final currentLevel = gamificationData['current_level'] as int? ?? 1;
    final currentLevelTitle =
        gamificationData['level_title'] as String? ?? 'Novice';
    final currentXP = gamificationData['current_xp'] as int? ?? 0;
    final nextLevelXP = gamificationData['next_level_xp'] as int? ?? 100;
    final engagementScore = gamificationData['engagement_score'] as int? ?? 0;

    final progress = nextLevelXP > 0
        ? (currentXP / nextLevelXP).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
        ),
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(26),
            blurRadius: 10.0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Gamification Overview',
            style: GoogleFonts.inter(
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 2.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatCard(
                'Lifetime VP',
                lifetimeVP.toString(),
                Icons.stars,
                theme,
              ),
              _buildStatCard(
                'Current Level',
                currentLevel.toString(),
                Icons.trending_up,
                theme,
              ),
              _buildStatCard(
                'Engagement',
                '$engagementScore/100',
                Icons.assessment,
                theme,
              ),
            ],
          ),
          SizedBox(height: 3.h),
          Container(
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(51),
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Level $currentLevel: $currentLevelTitle',
                      style: GoogleFonts.inter(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '$currentXP / $nextLevelXP XP',
                      style: GoogleFonts.inter(
                        fontSize: 12.sp,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 1.h),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 1.5.h,
                    backgroundColor: Colors.white.withAlpha(77),
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                SizedBox(height: 1.h),
                Text(
                  'Next level: ${_getNextLevelTitle(currentLevel)}',
                  style: GoogleFonts.inter(
                    fontSize: 10.sp,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 2.h),
          _buildEngagementScoreBar(engagementScore, theme),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    ThemeData theme,
  ) {
    return Container(
      width: 28.w,
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(51),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 24.sp),
          SizedBox(height: 1.h),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 18.sp,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.inter(fontSize: 10.sp, color: Colors.white70),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildEngagementScoreBar(int score, ThemeData theme) {
    final scoreColor = _getEngagementColor(score);
    final scoreLabel = _getEngagementLabel(score);

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(51),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Engagement Score',
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                decoration: BoxDecoration(
                  color: scoreColor.withAlpha(77),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Text(
                  scoreLabel,
                  style: GoogleFonts.inter(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(8.0),
            child: LinearProgressIndicator(
              value: score / 100,
              minHeight: 1.5.h,
              backgroundColor: Colors.white.withAlpha(77),
              valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
            ),
          ),
        ],
      ),
    );
  }

  Color _getEngagementColor(int score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.blue;
    if (score >= 40) return Colors.orange;
    return Colors.red;
  }

  String _getEngagementLabel(int score) {
    if (score >= 80) return 'Excellent';
    if (score >= 60) return 'Good';
    if (score >= 40) return 'Average';
    return 'Needs Improvement';
  }

  String _getNextLevelTitle(int currentLevel) {
    final levels = [
      'Novice',
      'Bronze Voter',
      'Bronze Participant',
      'Bronze Activist',
      'Silver Contributor',
      'Silver Leader',
      'Gold Advocate',
      'Gold Expert',
      'Platinum Champion',
      'Elite Master',
    ];

    if (currentLevel < levels.length) {
      return levels[currentLevel];
    }
    return 'Max Level';
  }
}
