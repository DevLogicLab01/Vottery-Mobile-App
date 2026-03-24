import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class NotificationCategoryFilterWidget extends StatelessWidget {
  final Set<String> activeFilters;
  final Function(Set<String>) onFilterChanged;
  final Function(String) onClearCategory;

  const NotificationCategoryFilterWidget({
    super.key,
    required this.activeFilters,
    required this.onFilterChanged,
    required this.onClearCategory,
  });

  final Map<String, Map<String, dynamic>> _categories = const {
    'votes': {
      'label': 'Votes',
      'icon': Icons.how_to_vote,
      'color': Colors.blue,
    },
    'messages': {
      'label': 'Messages',
      'icon': Icons.message,
      'color': Colors.green,
    },
    'achievements': {
      'label': 'Achievements',
      'icon': Icons.emoji_events,
      'color': Colors.amber,
    },
    'elections': {
      'label': 'Elections',
      'icon': Icons.campaign,
      'color': Colors.purple,
    },
    'campaigns': {
      'label': 'Campaigns',
      'icon': Icons.business,
      'color': Colors.orange,
    },
    'payments': {
      'label': 'Payments',
      'icon': Icons.credit_card,
      'color': Colors.teal,
    },
  };

  void _toggleFilter(String category) {
    final newFilters = Set<String>.from(activeFilters);
    if (newFilters.contains(category)) {
      newFilters.remove(category);
    } else {
      newFilters.add(category);
    }
    onFilterChanged(newFilters);
  }

  void _showCategoryOptions(BuildContext context, String category) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: EdgeInsets.all(4.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.clear_all, color: Colors.red),
              title: Text(
                'Clear all ${_categories[category]!['label']} notifications',
              ),
              onTap: () {
                Navigator.pop(context);
                onClearCategory(category);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 1.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 0.5.h),
            child: Text(
              'Filter by Category',
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
          ),
          SizedBox(
            height: 6.h,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories.keys.elementAt(index);
                final categoryData = _categories[category]!;
                final isActive = activeFilters.contains(category);

                return Padding(
                  padding: EdgeInsets.only(right: 2.w),
                  child: GestureDetector(
                    onTap: () => _toggleFilter(category),
                    onLongPress: () => _showCategoryOptions(context, category),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 3.w,
                        vertical: 1.h,
                      ),
                      decoration: BoxDecoration(
                        color: isActive
                            ? (categoryData['color'] as Color).withAlpha(26)
                            : Colors.grey[200],
                        borderRadius: BorderRadius.circular(20.0),
                        border: Border.all(
                          color: isActive
                              ? categoryData['color'] as Color
                              : Colors.transparent,
                          width: 2.0,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            categoryData['icon'] as IconData,
                            size: 4.w,
                            color: isActive
                                ? categoryData['color'] as Color
                                : Colors.grey,
                          ),
                          SizedBox(width: 1.5.w),
                          Text(
                            categoryData['label'] as String,
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: isActive
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isActive
                                  ? categoryData['color'] as Color
                                  : Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
