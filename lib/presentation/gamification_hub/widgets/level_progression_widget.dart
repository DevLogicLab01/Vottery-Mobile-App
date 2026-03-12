import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../widgets/custom_icon_widget.dart';

class LevelProgressionWidget extends StatelessWidget {
  final Map<String, dynamic> tier;
  final bool isUnlocked;
  final bool isCurrent;

  const LevelProgressionWidget({
    super.key,
    required this.tier,
    required this.isUnlocked,
    required this.isCurrent,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: isCurrent
            ? theme.colorScheme.primary.withValues(alpha: 0.1)
            : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCurrent
              ? theme.colorScheme.primary
              : isUnlocked
              ? theme.colorScheme.tertiary.withValues(alpha: 0.3)
              : theme.colorScheme.outline.withValues(alpha: 0.2),
          width: isCurrent ? 2 : 1.5,
        ),
      ),
      child: Row(
        children: [
          // Tier Badge
          Container(
            width: 15.w,
            height: 15.w,
            decoration: BoxDecoration(
              color: isUnlocked
                  ? _getTierColor(tier['tier'])
                  : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CustomIconWidget(
                    iconName: isUnlocked ? 'military_tech' : 'lock',
                    color: isUnlocked
                        ? Colors.white
                        : theme.colorScheme.onSurfaceVariant,
                    size: 20,
                  ),
                  Text(
                    '${tier['tier']}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isUnlocked
                          ? Colors.white
                          : theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),

          SizedBox(width: 4.w),

          // Tier Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      tier['name'],
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isUnlocked
                            ? theme.colorScheme.onSurface
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (isCurrent) ...[
                      SizedBox(width: 2.w),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 2.w,
                          vertical: 0.5.h,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Current',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 9.sp,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                SizedBox(height: 0.5.h),
                Text(
                  '${tier['xpRequired']} XP Required',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                SizedBox(height: 1.h),
                Row(
                  children: [
                    CustomIconWidget(
                      iconName: 'stars',
                      color: theme.colorScheme.tertiary,
                      size: 16,
                    ),
                    SizedBox(width: 1.w),
                    Text(
                      '${tier['vpMultiplier']}x VP Multiplier',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.tertiary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getTierColor(int tier) {
    switch (tier) {
      case 1:
        return const Color(0xFFCD7F32); // Bronze
      case 2:
        return const Color(0xFFC0C0C0); // Silver
      case 3:
        return const Color(0xFFFFD700); // Gold
      case 4:
        return const Color(0xFFE5E4E2); // Platinum
      case 5:
        return const Color(0xFFB9F2FF); // Diamond
      case 6:
        return const Color(0xFF8B00FF); // Master
      case 7:
        return const Color(0xFFFF1493); // Grand Master
      case 8:
        return const Color(0xFFFF4500); // Champion
      case 9:
        return const Color(0xFFFFD700); // Legend
      case 10:
        return const Color(0xFF9400D3); // Elite Master
      default:
        return const Color(0xFFCD7F32);
    }
  }
}
