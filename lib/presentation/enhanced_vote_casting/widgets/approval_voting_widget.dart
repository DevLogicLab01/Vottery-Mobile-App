import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

/// Approval voting widget with multi-select checkboxes
class ApprovalVotingWidget extends StatelessWidget {
  final List<Map<String, dynamic>> options;
  final Set<String> approvedOptions;
  final Function(String, bool) onApprovalChanged;

  const ApprovalVotingWidget({
    super.key,
    required this.options,
    required this.approvedOptions,
    required this.onApprovalChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Select all options you approve:',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.5.h),
                decoration: BoxDecoration(
                  color: theme.colorScheme.tertiary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${approvedOptions.length} selected',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.tertiary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 2.h),
        ...options.map((option) => _buildOptionCard(context, option)),
      ],
    );
  }

  Widget _buildOptionCard(BuildContext context, Map<String, dynamic> option) {
    final theme = Theme.of(context);
    final isApproved = approvedOptions.contains(option['id']);

    return GestureDetector(
      onTap: () => onApprovalChanged(option['id'], !isApproved),
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
        padding: EdgeInsets.all(3.w),
        decoration: BoxDecoration(
          color: isApproved
              ? theme.colorScheme.tertiary.withValues(alpha: 0.1)
              : theme.colorScheme.surface,
          border: Border.all(
            color: isApproved
                ? theme.colorScheme.tertiary
                : theme.colorScheme.outline.withValues(alpha: 0.3),
            width: isApproved ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Row(
          children: [
            // Checkbox
            Container(
              width: 6.w,
              height: 6.w,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4.0),
                border: Border.all(
                  color: isApproved
                      ? theme.colorScheme.tertiary
                      : theme.colorScheme.outline,
                  width: 2,
                ),
                color: isApproved
                    ? theme.colorScheme.tertiary
                    : Colors.transparent,
              ),
              child: isApproved
                  ? Center(
                      child: CustomIconWidget(
                        iconName: 'check',
                        color: theme.colorScheme.onPrimary,
                        size: 16,
                      ),
                    )
                  : null,
            ),

            SizedBox(width: 3.w),

            // Option content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    option['title'],
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  if (option['description'] != null) ...[
                    SizedBox(height: 0.5.h),
                    Text(
                      option['description'],
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
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
}
