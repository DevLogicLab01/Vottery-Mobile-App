import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class TemplateFilterWidget extends StatelessWidget {
  final String title;
  final List<String> options;
  final String selectedOption;
  final Function(String) onOptionSelected;

  const TemplateFilterWidget({
    super.key,
    required this.title,
    required this.options,
    required this.selectedOption,
    required this.onOptionSelected,
  });

  String _formatLabel(String option) {
    if (option == 'all') return 'All';
    return option
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
        ),
        SizedBox(
          height: 5.h,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            itemCount: options.length,
            itemBuilder: (context, index) {
              final option = options[index];
              final isSelected = option == selectedOption;

              return Padding(
                padding: EdgeInsets.only(right: 2.w),
                child: FilterChip(
                  label: Text(_formatLabel(option)),
                  selected: isSelected,
                  onSelected: (_) => onOptionSelected(option),
                  backgroundColor: Colors.grey[200],
                  selectedColor: AppTheme.accentLight,
                  labelStyle: TextStyle(
                    fontSize: 12.sp,
                    color: isSelected ? Colors.white : Colors.grey[700],
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
