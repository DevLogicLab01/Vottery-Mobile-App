import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../../widgets/custom_icon_widget.dart';

/// Next Level Progress Widget
/// Displays current level indicator with XP requirements and progress bar
class NextLevelProgressWidget extends StatelessWidget {
  final Map<String, dynamic>? userLevel;

  const NextLevelProgressWidget({super.key, required this.userLevel});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (userLevel == null) {
      return const SizedBox.shrink();
    }

    final currentLevel = userLevel!['current_level'] as int? ?? 1;
    final currentXP = userLevel!['current_xp'] as int? ?? 0;
    final levelTitle = userLevel!['level_title'] as String? ?? 'Novice';
    final vpMultiplier = userLevel!['vp_multiplier'] as double? ?? 1.0;

    // Calculate XP needed for next level
    final nextLevelXP = _getNextLevelXP(currentLevel);
    final progress = nextLevelXP > 0 ? currentXP / nextLevelXP : 0.0;

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
              Row(
                children: [
                  CustomIconWidget(
                    iconName: 'military_tech',
                    color: theme.colorScheme.primary,
                    size: 28,
                  ),
                  SizedBox(width: 2.w),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Level $currentLevel',
                        style: GoogleFonts.inter(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        levelTitle,
                        style: GoogleFonts.inter(
                          fontSize: 11.sp,
                          color: theme.colorScheme.onSurface.withAlpha(153),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withAlpha(26),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Text(
                  '${vpMultiplier.toStringAsFixed(1)}x VP',
                  style: GoogleFonts.inter(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Progress to Level ${currentLevel + 1}',
                style: GoogleFonts.inter(
                  fontSize: 10.sp,
                  color: theme.colorScheme.onSurface.withAlpha(153),
                ),
              ),
              Text(
                '$currentXP / $nextLevelXP XP',
                style: GoogleFonts.inter(
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          SizedBox(height: 0.5.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(8.0),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 1.h,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(
                theme.colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  int _getNextLevelXP(int currentLevel) {
    // Level XP requirements from gamification_service.dart
    const levelTiers = [
      {'level': 1, 'xp_required': 0},
      {'level': 2, 'xp_required': 100},
      {'level': 3, 'xp_required': 500},
      {'level': 4, 'xp_required': 1000},
      {'level': 5, 'xp_required': 2500},
      {'level': 6, 'xp_required': 5000},
      {'level': 7, 'xp_required': 10000},
      {'level': 8, 'xp_required': 15000},
      {'level': 9, 'xp_required': 25000},
      {'level': 10, 'xp_required': 50000},
    ];

    if (currentLevel >= 10) return 0;

    final nextLevel = levelTiers.firstWhere(
      (tier) => tier['level'] == currentLevel + 1,
      orElse: () => {'xp_required': 0},
    );

    return nextLevel['xp_required'] as int;
  }
}
