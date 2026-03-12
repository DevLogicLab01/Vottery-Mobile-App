import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

/// Widget for basic vote information section
/// Contains title and description input fields
class BasicInfoSectionWidget extends StatelessWidget {
  final TextEditingController titleController;
  final TextEditingController descriptionController;
  final String? titleError;
  final String? descriptionError;

  const BasicInfoSectionWidget({
    super.key,
    required this.titleController,
    required this.descriptionController,
    this.titleError,
    this.descriptionError,
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
                iconName: 'info_outline',
                color: theme.colorScheme.primary,
                size: 20,
              ),
              SizedBox(width: 2.w),
              Text(
                'Basic Information',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          TextField(
            controller: titleController,
            maxLength: 100,
            keyboardType: TextInputType.text,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: 'Vote Title *',
              hintText: 'Enter a clear, concise title',
              errorText: titleError,
              counterText: '${titleController.text.length}/100',
              prefixIcon: Padding(
                padding: EdgeInsets.all(3.w),
                child: CustomIconWidget(
                  iconName: 'title',
                  color: theme.colorScheme.onSurfaceVariant,
                  size: 20,
                ),
              ),
            ),
            style: theme.textTheme.bodyLarge,
          ),
          SizedBox(height: 2.h),
          TextField(
            controller: descriptionController,
            maxLength: 500,
            maxLines: 4,
            keyboardType: TextInputType.multiline,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: 'Description *',
              hintText: 'Provide details about this vote',
              errorText: descriptionError,
              counterText: '${descriptionController.text.length}/500',
              alignLabelWithHint: true,
              prefixIcon: Padding(
                padding: EdgeInsets.only(top: 3.w, left: 3.w, right: 3.w),
                child: CustomIconWidget(
                  iconName: 'description',
                  color: theme.colorScheme.onSurfaceVariant,
                  size: 20,
                ),
              ),
            ),
            style: theme.textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }
}
