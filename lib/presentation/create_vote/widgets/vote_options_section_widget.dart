import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

/// Widget for managing vote options
/// Supports add, remove, and reorder operations
class VoteOptionsSectionWidget extends StatelessWidget {
  final List<TextEditingController> optionControllers;
  final VoidCallback onAddOption;
  final Function(int) onRemoveOption;
  final Function(int, int) onReorderOption;
  final List<String?> optionErrors;

  const VoteOptionsSectionWidget({
    super.key,
    required this.optionControllers,
    required this.onAddOption,
    required this.onRemoveOption,
    required this.onReorderOption,
    required this.optionErrors,
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  CustomIconWidget(
                    iconName: 'ballot',
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                  SizedBox(width: 2.w),
                  Text(
                    'Vote Options',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Text(
                '${optionControllers.length} options',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: optionControllers.length,
            onReorder: onReorderOption,
            itemBuilder: (context, index) {
              return Dismissible(
                key: ValueKey('option_$index'),
                direction: optionControllers.length > 2
                    ? DismissDirection.endToStart
                    : DismissDirection.none,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: EdgeInsets.only(right: 4.w),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: CustomIconWidget(
                    iconName: 'delete',
                    color: theme.colorScheme.error,
                    size: 24,
                  ),
                ),
                confirmDismiss: (direction) async {
                  if (optionControllers.length <= 2) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Minimum 2 options required'),
                        backgroundColor: theme.colorScheme.error,
                      ),
                    );
                    return false;
                  }
                  return true;
                },
                onDismissed: (direction) => onRemoveOption(index),
                child: Container(
                  margin: EdgeInsets.only(bottom: 1.5.h),
                  child: Row(
                    children: [
                      CustomIconWidget(
                        iconName: 'drag_handle',
                        color: theme.colorScheme.onSurfaceVariant,
                        size: 20,
                      ),
                      SizedBox(width: 2.w),
                      Expanded(
                        child: TextField(
                          controller: optionControllers[index],
                          maxLength: 100,
                          decoration: InputDecoration(
                            labelText: 'Option ${index + 1} *',
                            hintText: 'Enter option text',
                            errorText: optionErrors.length > index
                                ? optionErrors[index]
                                : null,
                            counterText: '',
                            prefixIcon: Padding(
                              padding: EdgeInsets.all(3.w),
                              child: CustomIconWidget(
                                iconName: 'radio_button_unchecked',
                                color: theme.colorScheme.onSurfaceVariant,
                                size: 18,
                              ),
                            ),
                            suffixIcon: optionControllers.length > 2
                                ? IconButton(
                                    icon: CustomIconWidget(
                                      iconName: 'close',
                                      color: theme.colorScheme.error,
                                      size: 20,
                                    ),
                                    onPressed: () => onRemoveOption(index),
                                  )
                                : null,
                          ),
                          style: theme.textTheme.bodyLarge,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          SizedBox(height: 1.h),
          if (optionControllers.length < 10)
            OutlinedButton.icon(
              onPressed: onAddOption,
              icon: CustomIconWidget(
                iconName: 'add',
                color: theme.colorScheme.primary,
                size: 20,
              ),
              label: Text('Add Option'),
              style: OutlinedButton.styleFrom(
                minimumSize: Size(double.infinity, 6.h),
              ),
            ),
          if (optionControllers.length >= 10)
            Text(
              'Maximum 10 options allowed',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }
}
