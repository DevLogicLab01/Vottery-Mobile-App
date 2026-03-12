import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

/// Widget for individual vote option with selection state and results
class VoteOptionWidget extends StatelessWidget {
  final Map<String, dynamic> option;
  final bool isSelected;
  final bool isSingleSelect;
  final bool showResults;
  final VoidCallback onTap;

  const VoteOptionWidget({
    super.key,
    required this.option,
    required this.isSelected,
    required this.isSingleSelect,
    required this.showResults,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final percentage = option["percentage"] as double;

    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(3.w),
          child: Container(
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: isSelected
                  ? theme.colorScheme.primary.withValues(alpha: 0.1)
                  : theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(3.w),
              border: Border.all(
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outline.withValues(alpha: 0.3),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Selection indicator
                    Container(
                      width: 7.w,
                      height: 7.w,
                      decoration: BoxDecoration(
                        shape: isSingleSelect
                            ? BoxShape.circle
                            : BoxShape.rectangle,
                        borderRadius: isSingleSelect
                            ? null
                            : BorderRadius.circular(1.w),
                        color: isSelected
                            ? theme.colorScheme.primary
                            : Colors.transparent,
                        border: Border.all(
                          color: isSelected
                              ? theme.colorScheme.primary
                              : theme.colorScheme.outline,
                          width: 2,
                        ),
                      ),
                      child: isSelected
                          ? Center(
                              child: CustomIconWidget(
                                iconName: 'check',
                                color: theme.colorScheme.onPrimary,
                                size: 4.w,
                              ),
                            )
                          : null,
                    ),
                    SizedBox(width: 3.w),
                    // Option title
                    Expanded(
                      child: Text(
                        option["title"] as String,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 1.5.h),
                // Option description
                Padding(
                  padding: EdgeInsets.only(left: 10.w),
                  child: Text(
                    option["description"] as String,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                ),
                if (showResults) ...[
                  SizedBox(height: 2.h),
                  // Results bar
                  Padding(
                    padding: EdgeInsets.only(left: 10.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${option["currentVotes"]} votes',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              '${percentage.toStringAsFixed(1)}%',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 1.h),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(1.w),
                          child: SizedBox(
                            height: 1.h,
                            child: LinearProgressIndicator(
                              value: percentage / 100,
                              backgroundColor: theme.colorScheme.outline
                                  .withValues(alpha: 0.2),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                theme.colorScheme.primary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
