import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

class DemographicFilterWidget extends StatelessWidget {
  final bool showDemographics;
  final String selectedTimePeriod;
  final ValueChanged<bool> onDemographicsChanged;
  final ValueChanged<String?> onTimePeriodChanged;

  const DemographicFilterWidget({
    super.key,
    required this.showDemographics,
    required this.selectedTimePeriod,
    required this.onDemographicsChanged,
    required this.onTimePeriodChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CustomIconWidget(
                iconName: 'people',
                color: theme.colorScheme.primary,
                size: 20,
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: Text(
                  'Show Demographics',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Switch(
                value: showDemographics,
                onChanged: onDemographicsChanged,
                activeThumbColor: theme.colorScheme.primary,
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              CustomIconWidget(
                iconName: 'schedule',
                color: theme.colorScheme.primary,
                size: 20,
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: Text(
                  'Time Period',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 3.w),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: theme.colorScheme.outline.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: DropdownButton<String>(
                  value: selectedTimePeriod,
                  underline: const SizedBox.shrink(),
                  icon: CustomIconWidget(
                    iconName: 'arrow_drop_down',
                    color: theme.colorScheme.onSurface,
                    size: 24,
                  ),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                  items:
                      [
                        'All Time',
                        'Last 24 Hours',
                        'Last 7 Days',
                        'Last 30 Days',
                      ].map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                  onChanged: onTimePeriodChanged,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
