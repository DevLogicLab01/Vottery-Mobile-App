import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

/// VP reward preview widget showing base VP and streak multipliers
class VPRewardPreviewWidget extends StatelessWidget {
  final int baseVP;
  final double streakMultiplier;

  const VPRewardPreviewWidget({
    super.key,
    required this.baseVP,
    required this.streakMultiplier,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalVP = (baseVP * streakMultiplier).round();

    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.tertiary.withValues(alpha: 0.1),
            theme.colorScheme.secondary.withValues(alpha: 0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: theme.colorScheme.tertiary.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // VP icon
          Container(
            padding: EdgeInsets.all(2.w),
            decoration: BoxDecoration(
              color: theme.colorScheme.tertiary,
              shape: BoxShape.circle,
            ),
            child: CustomIconWidget(
              iconName: 'stars',
              color: theme.colorScheme.onPrimary,
              size: 24,
            ),
          ),

          SizedBox(width: 3.w),

          // VP details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Voting Reward',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 0.5.h),
                Row(
                  children: [
                    Text(
                      '$totalVP VP',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: theme.colorScheme.tertiary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (streakMultiplier > 1.0) ...[
                      SizedBox(width: 2.w),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 2.w,
                          vertical: 0.5.h,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.tertiary,
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CustomIconWidget(
                              iconName: 'local_fire_department',
                              color: theme.colorScheme.onPrimary,
                              size: 12,
                            ),
                            SizedBox(width: 1.w),
                            Text(
                              '${streakMultiplier}x',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                if (streakMultiplier > 1.0) ...[
                  SizedBox(height: 0.5.h),
                  Text(
                    'Base: $baseVP VP × ${streakMultiplier}x streak bonus',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
