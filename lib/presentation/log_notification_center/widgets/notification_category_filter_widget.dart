import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class NotificationCategoryFilterWidget extends StatelessWidget {
  final List<String> categories;
  final String selectedCategory;
  final Function(String) onCategorySelected;

  const NotificationCategoryFilterWidget({
    super.key,
    required this.categories,
    required this.selectedCategory,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 7.h,
      padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
      color: Colors.grey[50],
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = category == selectedCategory;

          return Padding(
            padding: EdgeInsets.only(right: 2.w),
            child: FilterChip(
              label: Text(
                category.replaceAll('_', ' ').toUpperCase(),
                style: TextStyle(fontSize: 10.sp),
              ),
              selected: isSelected,
              selectedColor: _getCategoryColor(category),
              backgroundColor: Colors.grey[200],
              onSelected: (selected) {
                onCategorySelected(category);
              },
            ),
          );
        },
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'security':
        return Colors.red[300]!;
      case 'system':
        return Colors.blue[300]!;
      case 'performance':
        return Colors.orange[300]!;
      case 'fraud_detection':
        return Colors.purple[300]!;
      default:
        return Colors.green[300]!;
    }
  }
}
