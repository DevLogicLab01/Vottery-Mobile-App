import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../../widgets/custom_icon_widget.dart';

/// Achievement Progress Widget
/// Displays badge unlock timeline with completion status and next milestone indicators
class AchievementProgressWidget extends StatelessWidget {
  final List<Map<String, dynamic>> achievements;

  const AchievementProgressWidget({super.key, required this.achievements});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final unlockedCount = achievements
        .where((a) => a['is_unlocked'] == true)
        .length;
    final totalCount = achievements.length;

    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Achievements',
                style: GoogleFonts.inter(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              Text(
                '$unlockedCount / $totalCount',
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(8.0),
            child: LinearProgressIndicator(
              value: totalCount > 0 ? unlockedCount / totalCount : 0,
              minHeight: 1.h,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(
                theme.colorScheme.primary,
              ),
            ),
          ),
          SizedBox(height: 2.h),
          SizedBox(
            height: 12.h,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: achievements.take(10).length,
              itemBuilder: (context, index) {
                final achievement = achievements[index];
                return _buildAchievementBadge(achievement, theme);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementBadge(
    Map<String, dynamic> achievement,
    ThemeData theme,
  ) {
    final isUnlocked = achievement['is_unlocked'] as bool? ?? false;
    final title = achievement['achievement_title'] as String? ?? 'Achievement';
    final iconName = achievement['icon_name'] as String? ?? 'emoji_events';

    return Container(
      width: 20.w,
      margin: EdgeInsets.only(right: 3.w),
      child: Column(
        children: [
          Container(
            width: 15.w,
            height: 15.w,
            decoration: BoxDecoration(
              color: isUnlocked
                  ? theme.colorScheme.primary.withAlpha(51)
                  : theme.colorScheme.surfaceContainerHighest,
              shape: BoxShape.circle,
              border: Border.all(
                color: isUnlocked
                    ? theme.colorScheme.primary
                    : theme.dividerColor,
                width: 2,
              ),
            ),
            child: Center(
              child: CustomIconWidget(
                iconName: iconName,
                color: isUnlocked
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface.withAlpha(77),
                size: 28,
              ),
            ),
          ),
          SizedBox(height: 0.5.h),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 9.sp,
              color: isUnlocked
                  ? theme.colorScheme.onSurface
                  : theme.colorScheme.onSurface.withAlpha(128),
              fontWeight: isUnlocked ? FontWeight.w600 : FontWeight.normal,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
