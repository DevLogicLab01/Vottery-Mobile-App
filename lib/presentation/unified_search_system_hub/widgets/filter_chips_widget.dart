import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class FilterChipsWidget extends StatelessWidget {
  final String selectedFilter;
  final Function(String) onFilterChanged;
  final String selectedSort;
  final Function(String) onSortChanged;

  const FilterChipsWidget({
    super.key,
    required this.selectedFilter,
    required this.onFilterChanged,
    required this.selectedSort,
    required this.onSortChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 1.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip(context, 'All', 'all'),
                SizedBox(width: 2.w),
                _buildFilterChip(context, 'Posts', 'posts'),
                SizedBox(width: 2.w),
                _buildFilterChip(context, 'Users', 'users'),
                SizedBox(width: 2.w),
                _buildFilterChip(context, 'Groups', 'groups'),
                SizedBox(width: 2.w),
                _buildFilterChip(context, 'Elections', 'elections'),
              ],
            ),
          ),
          SizedBox(height: 1.h),
          // Sort chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                Text('Sort by:', style: TextStyle(fontSize: 12.sp)),
                SizedBox(width: 2.w),
                _buildSortChip(context, 'Relevance', 'relevance'),
                SizedBox(width: 2.w),
                _buildSortChip(context, 'Recent', 'recent'),
                SizedBox(width: 2.w),
                _buildSortChip(context, 'Popular', 'popular'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(BuildContext context, String label, String value) {
    final isSelected = selectedFilter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onFilterChanged(value),
      backgroundColor: Theme.of(context).cardColor,
      selectedColor: Theme.of(context).primaryColor.withAlpha(51),
      checkmarkColor: Theme.of(context).primaryColor,
    );
  }

  Widget _buildSortChip(BuildContext context, String label, String value) {
    final isSelected = selectedSort == value;
    return ChoiceChip(
      label: Text(label, style: TextStyle(fontSize: 12.sp)),
      selected: isSelected,
      onSelected: (_) => onSortChanged(value),
      backgroundColor: Theme.of(context).cardColor,
      selectedColor: Theme.of(context).primaryColor.withAlpha(51),
    );
  }
}
