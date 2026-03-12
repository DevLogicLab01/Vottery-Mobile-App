import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class UnifiedNotificationCardWidget extends StatelessWidget {
  final Map<String, dynamic> notification;
  final bool isSelectionMode;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onDismiss;

  const UnifiedNotificationCardWidget({
    super.key,
    required this.notification,
    required this.isSelectionMode,
    required this.isSelected,
    required this.onTap,
    required this.onLongPress,
    required this.onDismiss,
  });

  Map<String, dynamic> _getCategoryStyle(String type) {
    switch (type) {
      case 'votes':
        return {'icon': Icons.how_to_vote, 'color': Colors.blue};
      case 'messages':
        return {'icon': Icons.message, 'color': Colors.green};
      case 'achievements':
        return {'icon': Icons.emoji_events, 'color': Colors.amber};
      case 'elections':
        return {'icon': Icons.campaign, 'color': Colors.purple};
      case 'campaigns':
        return {'icon': Icons.business, 'color': Colors.orange};
      default:
        return {'icon': Icons.notifications, 'color': Colors.grey};
    }
  }

  @override
  Widget build(BuildContext context) {
    final type = notification['notification_type'] as String? ?? 'general';
    final isRead = notification['is_read'] as bool? ?? false;
    final title = notification['title'] as String? ?? 'Notification';
    final body = notification['body'] as String? ?? '';
    final createdAt = notification['created_at'] != null
        ? DateTime.parse(notification['created_at'])
        : DateTime.now();
    final priority = notification['priority'] as String? ?? 'normal';

    final categoryStyle = _getCategoryStyle(type);
    final categoryColor = categoryStyle['color'] as Color;
    final categoryIcon = categoryStyle['icon'] as IconData;

    return Dismissible(
      key: Key(notification['id'].toString()),
      direction: isSelectionMode
          ? DismissDirection.none
          : DismissDirection.endToStart,
      onDismissed: (_) => onDismiss(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 4.w),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: Card(
        margin: EdgeInsets.only(bottom: 2.h),
        elevation: isRead ? 0 : 2,
        color: isSelected
            ? AppTheme.accentLight.withAlpha(26)
            : (isRead ? Colors.grey[100] : Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
          side: isSelected
              ? BorderSide(color: AppTheme.accentLight, width: 2.0)
              : BorderSide.none,
        ),
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: BorderRadius.circular(12.0),
          child: Padding(
            padding: EdgeInsets.all(3.w),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Selection Checkbox or Icon
                if (isSelectionMode)
                  Padding(
                    padding: EdgeInsets.only(right: 3.w),
                    child: Icon(
                      isSelected
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      color: isSelected ? AppTheme.accentLight : Colors.grey,
                      size: 6.w,
                    ),
                  )
                else
                  Container(
                    padding: EdgeInsets.all(2.w),
                    decoration: BoxDecoration(
                      color: categoryColor.withAlpha(26),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Icon(categoryIcon, color: categoryColor, size: 5.w),
                  ),

                SizedBox(width: 3.w),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title Row
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: isRead
                                    ? FontWeight.normal
                                    : FontWeight.bold,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (!isRead && !isSelectionMode)
                            Container(
                              width: 8.0,
                              height: 8.0,
                              decoration: BoxDecoration(
                                color: categoryColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      SizedBox(height: 0.5.h),

                      // Body
                      Text(
                        body,
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.grey[700],
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 1.h),

                      // Footer Row
                      Row(
                        children: [
                          // Priority Badge
                          if (priority == 'high' || priority == 'urgent')
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 2.w,
                                vertical: 0.3.h,
                              ),
                              decoration: BoxDecoration(
                                color: priority == 'urgent'
                                    ? Colors.red
                                    : Colors.orange,
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              child: Text(
                                priority.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 9.sp,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),

                          if (priority == 'high' || priority == 'urgent')
                            SizedBox(width: 2.w),

                          // Timestamp
                          Text(
                            timeago.format(createdAt),
                            style: TextStyle(
                              fontSize: 11.sp,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
