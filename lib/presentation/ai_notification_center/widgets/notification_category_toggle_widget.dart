import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class NotificationCategoryToggle extends StatelessWidget {
  final Set<String> activeFilters;
  final Function(Set<String>) onFilterChanged;

  const NotificationCategoryToggle({
    super.key,
    required this.activeFilters,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.5.h),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 4.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildFilterChip(
            label: 'Security Alerts',
            icon: Icons.security,
            color: Colors.red,
            filterKey: 'security',
          ),
          SizedBox(width: 2.w),
          _buildFilterChip(
            label: 'AI Recommendations',
            icon: Icons.lightbulb,
            color: Colors.blue,
            filterKey: 'recommendations',
          ),
          SizedBox(width: 2.w),
          _buildFilterChip(
            label: 'Quest Updates',
            icon: Icons.emoji_events,
            color: Colors.green,
            filterKey: 'quests',
          ),
        ],
      ),
    );
  }

  dynamic _buildFilterChip({
    required String label,
    required dynamic icon,
    required dynamic color,
    required String filterKey,
  }) {
    final isActive = activeFilters.contains(filterKey);
    return Expanded(
      child: FilterChip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16.sp, color: isActive ? Colors.white : color),
            SizedBox(width: 1.w),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 11.sp,
                  color: isActive ? Colors.white : Colors.black87,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        selected: isActive,
        selectedColor: color,
        backgroundColor: color.withAlpha(26),
        onSelected: (selected) {
          final newFilters = Set<String>.from(activeFilters);
          if (selected) {
            newFilters.add(filterKey);
          } else {
            newFilters.remove(filterKey);
          }
          onFilterChanged(newFilters);
        },
      ),
    );
  }
}
