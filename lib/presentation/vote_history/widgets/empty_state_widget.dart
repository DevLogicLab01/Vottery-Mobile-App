import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

class EmptyStateWidget extends StatelessWidget {
  final bool hasActiveFilters;
  final bool hasSearchQuery;
  final VoidCallback onClearFilters;

  const EmptyStateWidget({
    super.key,
    required this.hasActiveFilters,
    required this.hasSearchQuery,
    required this.onClearFilters,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 8.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 40.w,
              height: 40.w,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: CustomIconWidget(
                  iconName: hasActiveFilters || hasSearchQuery
                      ? 'search_off'
                      : 'history',
                  color: theme.colorScheme.primary,
                  size: 60,
                ),
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              hasActiveFilters || hasSearchQuery
                  ? 'No Matching Votes Found'
                  : 'No Voting History Yet',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 2.h),
            Text(
              hasActiveFilters || hasSearchQuery
                  ? 'Try adjusting your filters or search query to find what you\'re looking for.'
                  : 'Your voting history will appear here once you participate in votes.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            if (hasActiveFilters || hasSearchQuery) ...[
              SizedBox(height: 4.h),
              ElevatedButton.icon(
                onPressed: onClearFilters,
                icon: CustomIconWidget(
                  iconName: 'clear_all',
                  color: theme.colorScheme.onPrimary,
                  size: 20,
                ),
                label: Text(
                  'Clear Filters',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(
                    horizontal: 6.w,
                    vertical: 1.8.h,
                  ),
                ),
              ),
            ] else ...[
              SizedBox(height: 4.h),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(
                    context,
                    rootNavigator: true,
                  ).pushNamed('/vote-dashboard');
                },
                icon: CustomIconWidget(
                  iconName: 'how_to_vote',
                  color: theme.colorScheme.onPrimary,
                  size: 20,
                ),
                label: Text(
                  'Browse Votes',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(
                    horizontal: 6.w,
                    vertical: 1.8.h,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
