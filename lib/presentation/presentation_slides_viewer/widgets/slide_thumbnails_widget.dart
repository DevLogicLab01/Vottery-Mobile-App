import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

/// Slide thumbnails widget for quick navigation
class SlideThumbnailsWidget extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final Function(int) onPageSelected;
  final VoidCallback onClose;

  const SlideThumbnailsWidget({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.onPageSelected,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      color: theme.colorScheme.surface.withValues(alpha: 0.95),
      child: Column(
        children: [
          // Header
          Container(
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: theme.colorScheme.outline.withValues(alpha: 0.2),
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Slides',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                IconButton(
                  onPressed: onClose,
                  icon: const Icon(Icons.close),
                  iconSize: 18.sp,
                ),
              ],
            ),
          ),

          // Thumbnails list
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.all(2.w),
              itemCount: totalPages,
              itemBuilder: (context, index) {
                final pageNumber = index + 1;
                final isSelected = pageNumber == currentPage;

                return InkWell(
                  onTap: () => onPageSelected(pageNumber),
                  child: Container(
                    margin: EdgeInsets.only(bottom: 2.w),
                    padding: EdgeInsets.all(2.w),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? theme.colorScheme.primaryContainer.withValues(
                              alpha: 0.5,
                            )
                          : theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(8.0),
                      border: Border.all(
                        color: isSelected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.outline.withValues(alpha: 0.3),
                        width: isSelected ? 2.0 : 1.0,
                      ),
                    ),
                    child: Column(
                      children: [
                        Container(
                          height: 12.h,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(4.0),
                          ),
                          child: Center(
                            child: Icon(
                              Icons.image_outlined,
                              size: 24.sp,
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.3,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 1.w),
                        Text(
                          'Slide $pageNumber',
                          style: TextStyle(
                            fontSize: 11.sp,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ],
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
