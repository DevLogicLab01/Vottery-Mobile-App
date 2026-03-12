import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../widgets/custom_icon_widget.dart';

class AchievementGridWidget extends StatelessWidget {
  final List<Map<String, dynamic>> userAchievements;
  final List<Map<String, dynamic>> allAchievements;

  const AchievementGridWidget({
    super.key,
    required this.userAchievements,
    required this.allAchievements,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final unlockedIds = userAchievements
        .map((a) => a['achievement_id'])
        .toSet();

    if (allAchievements.isEmpty) {
      return _buildEmptyState(theme);
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 3.w,
        mainAxisSpacing: 2.h,
        childAspectRatio: 0.85,
      ),
      itemCount: allAchievements.length,
      itemBuilder: (context, index) {
        final achievement = allAchievements[index];
        final isUnlocked = unlockedIds.contains(achievement['id']);

        return GestureDetector(
          onTap: () =>
              _showAchievementDetails(context, achievement, isUnlocked),
          child: Container(
            padding: EdgeInsets.all(2.w),
            decoration: BoxDecoration(
              color: isUnlocked
                  ? theme.colorScheme.tertiary.withValues(alpha: 0.1)
                  : theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isUnlocked
                    ? theme.colorScheme.tertiary
                    : theme.colorScheme.outline.withValues(alpha: 0.2),
                width: 1.5,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(3.w),
                  decoration: BoxDecoration(
                    color: isUnlocked
                        ? theme.colorScheme.tertiary
                        : theme.colorScheme.onSurfaceVariant.withValues(
                            alpha: 0.2,
                          ),
                    shape: BoxShape.circle,
                  ),
                  child: CustomIconWidget(
                    iconName: achievement['icon'] ?? 'emoji_events',
                    color: isUnlocked
                        ? theme.colorScheme.onTertiary
                        : theme.colorScheme.onSurfaceVariant,
                    size: 28,
                  ),
                ),
                SizedBox(height: 1.h),
                Text(
                  achievement['name'] ?? 'Achievement',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isUnlocked
                        ? theme.colorScheme.onSurface
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Center(
        child: Column(
          children: [
            CustomIconWidget(
              iconName: 'emoji_events',
              color: theme.colorScheme.onSurfaceVariant,
              size: 48,
            ),
            SizedBox(height: 2.h),
            Text(
              'No achievements available yet',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAchievementDetails(
    BuildContext context,
    Map<String, dynamic> achievement,
    bool isUnlocked,
  ) {
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(2.w),
              decoration: BoxDecoration(
                color: isUnlocked
                    ? theme.colorScheme.tertiary
                    : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: CustomIconWidget(
                iconName: achievement['icon'] ?? 'emoji_events',
                color: isUnlocked
                    ? theme.colorScheme.onTertiary
                    : theme.colorScheme.onSurfaceVariant,
                size: 24,
              ),
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: Text(
                achievement['name'] ?? 'Achievement',
                style: theme.textTheme.titleMedium,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              achievement['description'] ?? 'No description available',
              style: theme.textTheme.bodyMedium,
            ),
            SizedBox(height: 2.h),
            if (achievement['bonus_multiplier'] != null) ...[
              Row(
                children: [
                  CustomIconWidget(
                    iconName: 'stars',
                    color: theme.colorScheme.tertiary,
                    size: 16,
                  ),
                  SizedBox(width: 2.w),
                  Text(
                    'Bonus: ${achievement['bonus_multiplier']}x VP',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.tertiary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
            SizedBox(height: 1.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
              decoration: BoxDecoration(
                color: isUnlocked
                    ? theme.colorScheme.tertiary.withValues(alpha: 0.1)
                    : theme.colorScheme.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CustomIconWidget(
                    iconName: isUnlocked ? 'check_circle' : 'lock',
                    color: isUnlocked
                        ? theme.colorScheme.tertiary
                        : theme.colorScheme.error,
                    size: 16,
                  ),
                  SizedBox(width: 2.w),
                  Text(
                    isUnlocked ? 'Unlocked' : 'Locked',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isUnlocked
                          ? theme.colorScheme.tertiary
                          : theme.colorScheme.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
