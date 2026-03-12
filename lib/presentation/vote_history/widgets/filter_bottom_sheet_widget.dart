import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class FilterBottomSheetWidget extends StatefulWidget {
  final Map<String, dynamic> activeFilters;
  final Function(Map<String, dynamic>) onApplyFilters;
  final VoidCallback onResetFilters;

  const FilterBottomSheetWidget({
    super.key,
    required this.activeFilters,
    required this.onApplyFilters,
    required this.onResetFilters,
  });

  @override
  State<FilterBottomSheetWidget> createState() =>
      _FilterBottomSheetWidgetState();
}

class _FilterBottomSheetWidgetState extends State<FilterBottomSheetWidget> {
  late Map<String, dynamic> _tempFilters;

  @override
  void initState() {
    super.initState();
    _tempFilters = Map.from(widget.activeFilters);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: EdgeInsets.symmetric(vertical: 1.h),
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurfaceVariant.withValues(
                  alpha: 0.4,
                ),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              child: Row(
                children: [
                  Text(
                    'Filter Votes',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      widget.onResetFilters();
                      Navigator.pop(context);
                    },
                    child: Text(
                      'Reset',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Divider(color: theme.colorScheme.outline.withValues(alpha: 0.2)),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFilterSection(
                      title: 'Date Range',
                      options: [
                        {'value': 'all', 'label': 'All Time'},
                        {'value': 'week', 'label': 'Last Week'},
                        {'value': 'month', 'label': 'Last Month'},
                        {'value': 'year', 'label': 'Last Year'},
                      ],
                      selectedValue: _tempFilters['dateRange'] as String,
                      onChanged: (value) {
                        setState(() => _tempFilters['dateRange'] = value);
                      },
                      theme: theme,
                    ),
                    SizedBox(height: 3.h),
                    _buildFilterSection(
                      title: 'Vote Type',
                      options: [
                        {'value': 'all', 'label': 'All Types'},
                        {'value': 'community', 'label': 'Community'},
                        {'value': 'government', 'label': 'Government'},
                        {'value': 'infrastructure', 'label': 'Infrastructure'},
                        {'value': 'election', 'label': 'Election'},
                      ],
                      selectedValue: _tempFilters['voteType'] as String,
                      onChanged: (value) {
                        setState(() => _tempFilters['voteType'] = value);
                      },
                      theme: theme,
                    ),
                    SizedBox(height: 3.h),
                    _buildFilterSection(
                      title: 'Outcome',
                      options: [
                        {'value': 'all', 'label': 'All Outcomes'},
                        {'value': 'won', 'label': 'Won'},
                        {'value': 'lost', 'label': 'Lost'},
                        {'value': 'tied', 'label': 'Tied'},
                      ],
                      selectedValue: _tempFilters['outcome'] as String,
                      onChanged: (value) {
                        setState(() => _tempFilters['outcome'] = value);
                      },
                      theme: theme,
                    ),
                    SizedBox(height: 3.h),
                  ],
                ),
              ),
            ),
            Container(
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.shadow,
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 1.8.h),
                        side: BorderSide(color: theme.colorScheme.outline),
                      ),
                      child: Text(
                        'Cancel',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 3.w),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        widget.onApplyFilters(_tempFilters);
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 1.8.h),
                      ),
                      child: Text(
                        'Apply Filters',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterSection({
    required String title,
    required List<Map<String, String>> options,
    required String selectedValue,
    required Function(String) onChanged,
    required ThemeData theme,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 1.5.h),
        Wrap(
          spacing: 2.w,
          runSpacing: 1.h,
          children: options.map((option) {
            final isSelected = selectedValue == option['value'];
            return InkWell(
              onTap: () => onChanged(option['value']!),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.2.h),
                decoration: BoxDecoration(
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.surface,
                  border: Border.all(
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outline.withValues(alpha: 0.5),
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  option['label']!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isSelected
                        ? theme.colorScheme.onPrimary
                        : theme.colorScheme.onSurface,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
