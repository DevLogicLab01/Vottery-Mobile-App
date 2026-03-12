import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../services/nft_achievement_service.dart';
import '../../../services/vp_service.dart';

class TierProgressionDashboardWidget extends StatefulWidget {
  final Map<String, dynamic> currentTier;
  final VoidCallback onRefresh;

  const TierProgressionDashboardWidget({
    super.key,
    required this.currentTier,
    required this.onRefresh,
  });

  @override
  State<TierProgressionDashboardWidget> createState() =>
      _TierProgressionDashboardWidgetState();
}

class _TierProgressionDashboardWidgetState
    extends State<TierProgressionDashboardWidget> {
  final VPService _vpService = VPService.instance;
  int _currentVP = 0;

  @override
  void initState() {
    super.initState();
    _loadVPBalance();
  }

  Future<void> _loadVPBalance() async {
    final balance = await _vpService.getVPBalance();
    if (mounted) {
      setState(() {
        _currentVP = balance?['total_vp'] as int? ?? 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tiers = NFTAchievementService.achievementTiers;

    return ListView(
      padding: EdgeInsets.all(4.w),
      children: [
        // Current VP display
        Container(
          padding: EdgeInsets.all(4.w),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.colorScheme.primary,
                theme.colorScheme.primary.withValues(alpha: 0.7),
              ],
            ),
            borderRadius: BorderRadius.circular(16.0),
          ),
          child: Column(
            children: [
              Text(
                'Your Total VP',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onPrimary.withValues(alpha: 0.8),
                ),
              ),
              SizedBox(height: 1.h),
              Text(
                '$_currentVP VP',
                style: theme.textTheme.displaySmall?.copyWith(
                  color: theme.colorScheme.onPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: 3.h),

        // Tier progression cards
        ...tiers.map((tier) {
          final tierName = tier['tier'] as String;
          final minVP = tier['min_vp'] as int;
          final maxVP = tier['max_vp'] as int;
          final tierColor = Color(tier['color'] as int);
          final rarity = tier['rarity'] as String;

          final isUnlocked = _currentVP >= minVP;
          final isCurrent = _currentVP >= minVP && _currentVP < maxVP;
          final progress = isCurrent
              ? (_currentVP - minVP) / (maxVP - minVP)
              : isUnlocked
              ? 1.0
              : 0.0;

          return Container(
            margin: EdgeInsets.only(bottom: 2.h),
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: isUnlocked
                  ? theme.colorScheme.surfaceContainerHighest
                  : theme.colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(16.0),
              border: Border.all(
                color: isCurrent
                    ? tierColor
                    : theme.colorScheme.outline.withValues(alpha: 0.2),
                width: isCurrent ? 2 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Tier icon
                    Container(
                      width: 12.w,
                      height: 12.w,
                      decoration: BoxDecoration(
                        color: tierColor.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Icon(
                          isUnlocked ? Icons.check_circle : Icons.lock,
                          color: tierColor,
                          size: 24,
                        ),
                      ),
                    ),

                    SizedBox(width: 3.w),

                    // Tier info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tierName,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: isUnlocked
                                  ? theme.colorScheme.onSurface
                                  : theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          SizedBox(height: 0.5.h),
                          Row(
                            children: [
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 2.w,
                                  vertical: 0.5.h,
                                ),
                                decoration: BoxDecoration(
                                  color: tierColor.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                child: Text(
                                  rarity,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: tierColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              SizedBox(width: 2.w),
                              Text(
                                '$minVP - ${maxVP == 999999999 ? "∞" : maxVP} VP',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Status badge
                    if (isCurrent)
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 2.w,
                          vertical: 0.5.h,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: Text(
                          'CURRENT',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),

                if (isCurrent) ...[
                  SizedBox(height: 2.h),

                  // Progress bar
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Progress to next tier',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          Text(
                            '${(progress * 100).toStringAsFixed(1)}%',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 1.h),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8.0),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 8,
                          backgroundColor:
                              theme.colorScheme.surfaceContainerHighest,
                          valueColor: AlwaysStoppedAnimation<Color>(tierColor),
                        ),
                      ),
                      SizedBox(height: 0.5.h),
                      Text(
                        '${maxVP - _currentVP} VP needed',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          );
        }),
      ],
    );
  }
}
