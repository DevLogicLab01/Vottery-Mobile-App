import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class SavedSearchesWidget extends StatelessWidget {
  final List<String> savedSearches;
  final Function(String) onSearchTap;
  final Function(String) onRemove;

  const SavedSearchesWidget({
    super.key,
    required this.savedSearches,
    required this.onSearchTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.bookmark,
              size: 16.sp,
              color: Theme.of(context).primaryColor,
            ),
            SizedBox(width: 2.w),
            Text(
              'Saved Searches',
              style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        SizedBox(height: 1.h),
        Wrap(
          spacing: 2.w,
          runSpacing: 1.h,
          children: savedSearches.map((search) {
            return Chip(
              label: Text(search),
              onDeleted: () => onRemove(search),
              deleteIcon: const Icon(Icons.close, size: 16),
              backgroundColor: Theme.of(context).primaryColor.withAlpha(26),
              labelStyle: TextStyle(fontSize: 12.sp),
              avatar: Icon(
                Icons.search,
                size: 14.sp,
                color: Theme.of(context).primaryColor,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
