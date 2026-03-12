import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import '../../../theme/app_theme.dart';

/// Filter selection bar for Moments
class FilterSelectionBarWidget extends StatelessWidget {
  final String selectedFilter;
  final Function(String) onFilterSelected;

  const FilterSelectionBarWidget({
    super.key,
    required this.selectedFilter,
    required this.onFilterSelected,
  });

  static const List<Map<String, dynamic>> filters = [
    {'name': 'None', 'color': null},
    {'name': 'Vintage', 'color': Color(0xFFD4A574)},
    {'name': 'Warm', 'color': Color(0xFFFF8C42)},
    {'name': 'Cool', 'color': Color(0xFF4ECDC4)},
    {'name': 'B&W', 'color': Color(0xFF808080)},
    {'name': 'Vivid', 'color': Color(0xFFFF6B6B)},
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 10.h,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 3.w),
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = selectedFilter == filter['name'];
          return GestureDetector(
            onTap: () => onFilterSelected(filter['name']),
            child: Container(
              margin: EdgeInsets.only(right: 2.w),
              child: Column(
                children: [
                  Container(
                    width: 14.w,
                    height: 7.h,
                    decoration: BoxDecoration(
                      color: filter['color'] ?? Colors.grey.withAlpha(50),
                      borderRadius: BorderRadius.circular(8.0),
                      border: Border.all(
                        color: isSelected
                            ? AppTheme.primaryLight
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: isSelected
                        ? Icon(Icons.check, color: Colors.white, size: 5.w)
                        : null,
                  ),
                  SizedBox(height: 0.3.h),
                  Text(
                    filter['name'],
                    style: GoogleFonts.inter(
                      fontSize: 9.sp,
                      color: isSelected
                          ? AppTheme.primaryLight
                          : AppTheme.textSecondaryLight,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
