import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../widgets/custom_icon_widget.dart';

class SpendingCardWidget extends StatelessWidget {
  final Map<String, dynamic> option;
  final int currentBalance;
  final VoidCallback onTap;

  const SpendingCardWidget({
    super.key,
    required this.option,
    required this.currentBalance,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final vpCost = option['vpCost'] as int;
    final canAfford = currentBalance >= vpCost;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40.w,
        margin: EdgeInsets.only(right: 3.w),
        padding: EdgeInsets.all(3.w),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: canAfford
                ? theme.colorScheme.secondary.withValues(alpha: 0.3)
                : theme.colorScheme.outline.withValues(alpha: 0.2),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.shadow,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Icon
            Container(
              padding: EdgeInsets.all(2.w),
              decoration: BoxDecoration(
                color: canAfford
                    ? theme.colorScheme.secondary.withValues(alpha: 0.1)
                    : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: CustomIconWidget(
                iconName: option['icon'] ?? 'shopping_cart',
                color: canAfford
                    ? theme.colorScheme.secondary
                    : theme.colorScheme.onSurfaceVariant,
                size: 24,
              ),
            ),

            SizedBox(height: 1.5.h),

            // Title
            Text(
              option['title'] ?? '',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: canAfford
                    ? theme.colorScheme.onSurface
                    : theme.colorScheme.onSurfaceVariant,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            SizedBox(height: 0.5.h),

            // Description
            Text(
              option['description'] ?? '',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            SizedBox(height: 1.h),

            // VP Cost
            Container(
              padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
              decoration: BoxDecoration(
                color: canAfford
                    ? theme.colorScheme.secondary.withValues(alpha: 0.1)
                    : theme.colorScheme.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    vpCost.toString(),
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: canAfford
                          ? theme.colorScheme.secondary
                          : theme.colorScheme.error,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(width: 1.w),
                  Text(
                    'VP',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: canAfford
                          ? theme.colorScheme.secondary
                          : theme.colorScheme.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
