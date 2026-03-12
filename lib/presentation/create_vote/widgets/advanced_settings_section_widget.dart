import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

/// Widget for advanced vote configuration
/// Includes voter restrictions and result visibility settings
class AdvancedSettingsSectionWidget extends StatelessWidget {
  final String selectedRestriction;
  final Function(String) onRestrictionChanged;
  final String selectedVisibility;
  final Function(String) onVisibilityChanged;

  const AdvancedSettingsSectionWidget({
    super.key,
    required this.selectedRestriction,
    required this.onRestrictionChanged,
    required this.selectedVisibility,
    required this.onVisibilityChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CustomIconWidget(
                iconName: 'tune',
                color: theme.colorScheme.primary,
                size: 20,
              ),
              SizedBox(width: 2.w),
              Text(
                'Advanced Settings',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Text(
            'Voter Restrictions',
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 1.h),
          _buildRadioOption(
            context: context,
            value: 'none',
            groupValue: selectedRestriction,
            title: 'No Restrictions',
            subtitle: 'Anyone can vote',
            onChanged: onRestrictionChanged,
          ),
          SizedBox(height: 1.h),
          _buildRadioOption(
            context: context,
            value: 'verified',
            groupValue: selectedRestriction,
            title: 'Verified Users Only',
            subtitle: 'Require biometric verification',
            onChanged: onRestrictionChanged,
          ),
          SizedBox(height: 1.h),
          _buildRadioOption(
            context: context,
            value: 'invited',
            groupValue: selectedRestriction,
            title: 'Invited Users Only',
            subtitle: 'Restrict to specific user list',
            onChanged: onRestrictionChanged,
          ),
          SizedBox(height: 2.h),
          Divider(color: theme.colorScheme.outline),
          SizedBox(height: 2.h),
          Text(
            'Result Visibility',
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 1.h),
          _buildRadioOption(
            context: context,
            value: 'public',
            groupValue: selectedVisibility,
            title: 'Public Results',
            subtitle: 'Visible to everyone after voting ends',
            onChanged: onVisibilityChanged,
          ),
          SizedBox(height: 1.h),
          _buildRadioOption(
            context: context,
            value: 'voters',
            groupValue: selectedVisibility,
            title: 'Voters Only',
            subtitle: 'Only participants can see results',
            onChanged: onVisibilityChanged,
          ),
          SizedBox(height: 1.h),
          _buildRadioOption(
            context: context,
            value: 'creator',
            groupValue: selectedVisibility,
            title: 'Creator Only',
            subtitle: 'Results visible only to vote creator',
            onChanged: onVisibilityChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildRadioOption({
    required BuildContext context,
    required String value,
    required String groupValue,
    required String title,
    required String subtitle,
    required Function(String) onChanged,
  }) {
    final theme = Theme.of(context);
    final isSelected = value == groupValue;

    return InkWell(
      onTap: () => onChanged(value),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: EdgeInsets.all(3.w),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.outline,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
          color: isSelected
              ? theme.colorScheme.primary.withValues(alpha: 0.05)
              : Colors.transparent,
        ),
        child: Row(
          children: [
            Radio<String>(
              value: value,
              groupValue: groupValue,
              onChanged: (val) => onChanged(val!),
            ),
            SizedBox(width: 2.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: isSelected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                  SizedBox(height: 0.5.h),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
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
