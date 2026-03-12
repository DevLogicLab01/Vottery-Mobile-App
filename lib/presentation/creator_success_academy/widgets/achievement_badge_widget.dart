import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class AchievementBadgeWidget extends StatelessWidget {
  final Map<String, dynamic> achievement;
  final bool isUnlocked;

  const AchievementBadgeWidget({
    super.key,
    required this.achievement,
    required this.isUnlocked,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = achievement['achievement_name'] as String? ?? 'Achievement';
    final description = achievement['achievement_description'] as String? ?? '';
    final xpReward = achievement['xp_reward'] as int? ?? 0;
    final badgeUrl = achievement['badge_icon_url'] as String?;

    return Card(
      elevation: isUnlocked ? 3 : 1,
      color: isUnlocked
          ? theme.cardColor
          : theme.colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 20.w,
                  height: 20.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isUnlocked
                        ? Colors.amber.withValues(alpha: 0.2)
                        : Colors.grey.withValues(alpha: 0.2),
                  ),
                ),
                if (badgeUrl != null && isUnlocked)
                  ClipOval(
                    child: CachedNetworkImage(
                      imageUrl: badgeUrl,
                      width: 18.w,
                      height: 18.w,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => CircularProgressIndicator(
                        strokeWidth: 2,
                        color: theme.colorScheme.primary,
                      ),
                      errorWidget: (context, url, error) => Icon(
                        Icons.emoji_events,
                        size: 10.w,
                        color: isUnlocked ? Colors.amber : Colors.grey,
                      ),
                    ),
                  )
                else
                  Icon(
                    isUnlocked ? Icons.emoji_events : Icons.lock,
                    size: 10.w,
                    color: isUnlocked ? Colors.amber : Colors.grey,
                  ),
              ],
            ),
            SizedBox(height: 1.h),
            Text(
              name,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: 11.sp,
                fontWeight: FontWeight.bold,
                color: isUnlocked
                    ? theme.colorScheme.onSurface
                    : theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 0.5.h),
            Text(
              description,
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 9.sp,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 0.5.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
              decoration: BoxDecoration(
                color: isUnlocked
                    ? theme.colorScheme.primaryContainer
                    : theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Text(
                '+$xpReward XP',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 9.sp,
                  fontWeight: FontWeight.bold,
                  color: isUnlocked
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
