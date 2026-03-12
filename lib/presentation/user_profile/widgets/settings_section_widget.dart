import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

/// Settings section widget displaying grouped settings with title.
/// Supports both navigation items and toggle switches.
class SettingsSectionWidget extends StatelessWidget {
  final String title;
  final List<Map<String, dynamic>> items;

  const SettingsSectionWidget({
    super.key,
    required this.title,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(horizontal: 4.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title
          Padding(
            padding: EdgeInsets.fromLTRB(4.w, 2.h, 4.w, 1.h),
            child: Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.primary,
              ),
            ),
          ),

          // Settings Items
          ...items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final isLast = index == items.length - 1;

            return Column(
              children: [
                _buildSettingItem(context, item),
                if (!isLast)
                  Divider(
                    height: 1,
                    thickness: 1,
                    indent: 16.w,
                    color: theme.colorScheme.outline.withValues(alpha: 0.2),
                  ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSettingItem(BuildContext context, Map<String, dynamic> item) {
    final theme = Theme.of(context);
    final hasToggle = item.containsKey('value') && item.containsKey('onToggle');
    final hasNavigation = item.containsKey('onTap');

    return InkWell(
      onTap: hasNavigation && !hasToggle ? () => item['onTap']() : null,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
        child: Row(
          children: [
            // Icon
            Container(
              width: 10.w,
              height: 10.w,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: CustomIconWidget(
                  iconName: item['icon'],
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
              ),
            ),

            SizedBox(width: 3.w),

            // Title and Subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['title'],
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  if (item['subtitle'] != null) ...[
                    SizedBox(height: 0.5.h),
                    Text(
                      item['subtitle'],
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            SizedBox(width: 2.w),

            // Toggle Switch or Navigation Arrow
            hasToggle
                ? Switch(
                    value: item['value'] ?? false,
                    onChanged: (value) {
                      if (item['onToggle'] != null) {
                        item['onToggle'](value);
                      }
                    },
                    activeThumbColor: theme.colorScheme.primary,
                  )
                : hasNavigation
                ? CustomIconWidget(
                    iconName: 'chevron_right',
                    color: theme.colorScheme.onSurfaceVariant,
                    size: 20,
                  )
                : const SizedBox.shrink(),
          ],
        ),
      ),
    );
  }
}
