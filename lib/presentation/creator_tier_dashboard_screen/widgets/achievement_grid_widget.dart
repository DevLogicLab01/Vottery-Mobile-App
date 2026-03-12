import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../../theme/app_theme.dart';

class AchievementGridWidget extends StatelessWidget {
  final List<Map<String, dynamic>> achievements;
  final List<Map<String, dynamic>> userAchievements;
  final Function(Map<String, dynamic>) onAchievementTap;

  const AchievementGridWidget({
    super.key,
    required this.achievements,
    required this.userAchievements,
    required this.onAchievementTap,
  });

  bool _isUnlocked(String achievementId) {
    return userAchievements.any((ua) => ua['achievement_id'] == achievementId);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Achievements',
          style: GoogleFonts.inter(
            fontSize: 16.sp,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimaryLight,
          ),
        ),
        SizedBox(height: 2.h),
        GridView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 3.w,
            mainAxisSpacing: 2.h,
            childAspectRatio: 1.2,
          ),
          itemCount: achievements.length,
          itemBuilder: (context, index) {
            final achievement = achievements[index];
            final isUnlocked = _isUnlocked(achievement['id']);

            return GestureDetector(
              onTap: () => onAchievementTap(achievement),
              child: Container(
                padding: EdgeInsets.all(3.w),
                decoration: BoxDecoration(
                  color: isUnlocked
                      ? AppTheme.primaryLight.withValues(alpha: 0.1)
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12.0),
                  border: Border.all(
                    color: isUnlocked
                        ? AppTheme.primaryLight
                        : Colors.grey.shade300,
                    width: isUnlocked ? 2 : 1,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _getAchievementIcon(achievement['achievement_type']),
                      size: 12.w,
                      color: isUnlocked
                          ? AppTheme.primaryLight
                          : Colors.grey.shade400,
                    ),
                    SizedBox(height: 1.h),
                    Text(
                      achievement['title'] ?? '',
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w600,
                        color: isUnlocked
                            ? AppTheme.textPrimaryLight
                            : Colors.grey.shade600,
                      ),
                    ),
                    SizedBox(height: 0.5.h),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 2.w,
                        vertical: 0.5.h,
                      ),
                      decoration: BoxDecoration(
                        color: isUnlocked
                            ? Colors.amber.shade100
                            : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: Text(
                        '${achievement['vp_reward'] ?? 0} VP',
                        style: GoogleFonts.inter(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w700,
                          color: isUnlocked
                              ? Colors.amber.shade700
                              : Colors.grey.shade500,
                        ),
                      ),
                    ),
                    if (!isUnlocked)
                      Padding(
                        padding: EdgeInsets.only(top: 0.5.h),
                        child: Icon(
                          Icons.lock,
                          size: 5.w,
                          color: Colors.grey.shade400,
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  IconData _getAchievementIcon(String? type) {
    switch (type) {
      case 'first_election_created':
        return Icons.create;
      case 'first_1000_votes':
        return Icons.how_to_vote;
      case 'first_payout':
        return Icons.payments;
      case '100_elections_created':
        return Icons.workspace_premium;
      case 'top_earner_monthly':
        return Icons.emoji_events;
      case 'viral_content':
        return Icons.trending_up;
      default:
        return Icons.star;
    }
  }
}
