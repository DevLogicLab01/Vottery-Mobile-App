import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

/// Widget for vote settings configuration
/// Includes deadline, privacy, and voting options
class SettingsSectionWidget extends StatelessWidget {
  final DateTime? selectedDeadline;
  final VoidCallback onSelectDeadline;
  final bool anonymousVoting;
  final Function(bool) onAnonymousChanged;
  final bool realTimeResults;
  final Function(bool) onRealTimeResultsChanged;
  final bool multiSelect;
  final Function(bool) onMultiSelectChanged;

  const SettingsSectionWidget({
    super.key,
    required this.selectedDeadline,
    required this.onSelectDeadline,
    required this.anonymousVoting,
    required this.onAnonymousChanged,
    required this.realTimeResults,
    required this.onRealTimeResultsChanged,
    required this.multiSelect,
    required this.onMultiSelectChanged,
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
                iconName: 'settings',
                color: theme.colorScheme.primary,
                size: 20,
              ),
              SizedBox(width: 2.w),
              Text(
                'Vote Settings',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          InkWell(
            onTap: onSelectDeadline,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                border: Border.all(color: theme.colorScheme.outline),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  CustomIconWidget(
                    iconName: 'calendar_today',
                    color: theme.colorScheme.onSurfaceVariant,
                    size: 20,
                  ),
                  SizedBox(width: 3.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Voting Deadline *',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        SizedBox(height: 0.5.h),
                        Text(
                          selectedDeadline != null
                              ? '${selectedDeadline!.month}/${selectedDeadline!.day}/${selectedDeadline!.year} ${selectedDeadline!.hour.toString().padLeft(2, '0')}:${selectedDeadline!.minute.toString().padLeft(2, '0')}'
                              : 'Select date and time',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: selectedDeadline != null
                                ? theme.colorScheme.onSurface
                                : theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  CustomIconWidget(
                    iconName: 'arrow_forward_ios',
                    color: theme.colorScheme.onSurfaceVariant,
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 2.h),
          _buildToggleSetting(
            context: context,
            icon: 'visibility_off',
            title: 'Anonymous Voting',
            subtitle: 'Hide voter identities from results',
            value: anonymousVoting,
            onChanged: onAnonymousChanged,
          ),
          SizedBox(height: 1.5.h),
          _buildToggleSetting(
            context: context,
            icon: 'show_chart',
            title: 'Real-time Results',
            subtitle: 'Show live vote counts to participants',
            value: realTimeResults,
            onChanged: onRealTimeResultsChanged,
          ),
          SizedBox(height: 1.5.h),
          _buildToggleSetting(
            context: context,
            icon: 'check_box',
            title: 'Multiple Selection',
            subtitle: 'Allow voters to select multiple options',
            value: multiSelect,
            onChanged: onMultiSelectChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildToggleSetting({
    required BuildContext context,
    required String icon,
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outline),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          CustomIconWidget(
            iconName: icon,
            color: theme.colorScheme.onSurfaceVariant,
            size: 20,
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w500,
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
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}
