import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class TierProgressionWidget extends StatelessWidget {
  final List<Map<String, dynamic>> tiers;
  final Map<String, dynamic>? currentProgress;

  const TierProgressionWidget({
    super.key,
    required this.tiers,
    this.currentProgress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentTier =
        currentProgress?['current_tier'] as String? ?? 'beginner';
    final totalXp = currentProgress?['total_xp'] as int? ?? 0;

    return Column(
      children: tiers.map((tier) {
        final tierLevel = tier['tier_level'] as String;
        final tierName = tier['tier_name'] as String;
        final xpRequired = tier['xp_required'] as int;
        final tierOrder = tier['tier_order'] as int;

        final isCurrentTier = tierLevel == currentTier;
        final isCompleted =
            totalXp >= xpRequired &&
            tierOrder < _getCurrentTierOrder(currentTier, tiers);
        final isLocked = totalXp < xpRequired;

        return _buildTierCard(
          theme,
          tierName,
          tierLevel,
          xpRequired,
          isCurrentTier,
          isCompleted,
          isLocked,
          totalXp,
        );
      }).toList(),
    );
  }

  Widget _buildTierCard(
    ThemeData theme,
    String tierName,
    String tierLevel,
    int xpRequired,
    bool isCurrentTier,
    bool isCompleted,
    bool isLocked,
    int totalXp,
  ) {
    Color cardColor;
    IconData icon;

    if (isCompleted) {
      cardColor = Colors.green;
      icon = Icons.check_circle;
    } else if (isCurrentTier) {
      cardColor = theme.colorScheme.primary;
      icon = Icons.play_circle_filled;
    } else {
      cardColor = Colors.grey;
      icon = Icons.lock;
    }

    return Card(
      elevation: isCurrentTier ? 4 : 2,
      margin: EdgeInsets.only(bottom: 2.h),
      color: isCurrentTier ? cardColor.withValues(alpha: 0.1) : theme.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
        side: isCurrentTier
            ? BorderSide(color: cardColor, width: 2)
            : BorderSide.none,
      ),
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Row(
          children: [
            Container(
              width: 15.w,
              height: 15.w,
              decoration: BoxDecoration(
                color: cardColor.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 8.w, color: cardColor),
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tierName,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                      color: isCurrentTier ? cardColor : null,
                    ),
                  ),
                  SizedBox(height: 0.5.h),
                  Text(
                    'Required XP: $xpRequired',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 10.sp,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (isCurrentTier) ...[
                    SizedBox(height: 1.h),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8.0),
                      child: LinearProgressIndicator(
                        value: totalXp / xpRequired,
                        minHeight: 0.8.h,
                        backgroundColor:
                            theme.colorScheme.surfaceContainerHighest,
                        valueColor: AlwaysStoppedAnimation<Color>(cardColor),
                      ),
                    ),
                    SizedBox(height: 0.5.h),
                    Text(
                      '$totalXp / $xpRequired XP',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 9.sp,
                        color: cardColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  int _getCurrentTierOrder(
    String currentTier,
    List<Map<String, dynamic>> tiers,
  ) {
    final tier = tiers.firstWhere(
      (t) => t['tier_level'] == currentTier,
      orElse: () => {'tier_order': 1},
    );
    return tier['tier_order'] as int;
  }
}
