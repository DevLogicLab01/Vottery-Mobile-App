import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../widgets/custom_icon_widget.dart';

/// Real-time Notifications Widget
/// Displays VP gains, badge unlocks, level-ups with celebration animations
class RealTimeNotificationsWidget extends StatelessWidget {
  final List<Map<String, dynamic>> notifications;

  const RealTimeNotificationsWidget({super.key, required this.notifications});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (notifications.isEmpty) {
      return _buildEmptyState(theme);
    }

    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        children: notifications.take(5).map((notification) {
          return _buildNotificationItem(notification, theme);
        }).toList(),
      ),
    );
  }

  Widget _buildNotificationItem(
    Map<String, dynamic> notification,
    ThemeData theme,
  ) {
    final type = notification['notification_type'] as String? ?? 'vp_gain';
    final message = notification['message'] as String? ?? '';
    final createdAt = DateTime.parse(
      notification['created_at'] as String? ?? DateTime.now().toIso8601String(),
    );

    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(2.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Row(
        children: [
          _buildNotificationIcon(type, theme),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message,
                  style: GoogleFonts.inter(
                    fontSize: 11.sp,
                    color: theme.colorScheme.onSurface,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 0.5.h),
                Text(
                  timeago.format(createdAt),
                  style: GoogleFonts.inter(
                    fontSize: 9.sp,
                    color: theme.colorScheme.onSurface.withAlpha(128),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationIcon(String type, ThemeData theme) {
    String iconName;
    Color iconColor;

    switch (type) {
      case 'vp_gain':
        iconName = 'stars';
        iconColor = Colors.amber;
        break;
      case 'badge_unlock':
        iconName = 'emoji_events';
        iconColor = Colors.purple;
        break;
      case 'level_up':
        iconName = 'trending_up';
        iconColor = Colors.green;
        break;
      case 'achievement':
        iconName = 'military_tech';
        iconColor = Colors.blue;
        break;
      default:
        iconName = 'notifications';
        iconColor = theme.colorScheme.primary;
    }

    return Container(
      padding: EdgeInsets.all(2.w),
      decoration: BoxDecoration(
        color: iconColor.withAlpha(26),
        shape: BoxShape.circle,
      ),
      child: CustomIconWidget(iconName: iconName, color: iconColor, size: 24),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomIconWidget(
              iconName: 'notifications_none',
              color: theme.colorScheme.onSurface.withAlpha(77),
              size: 40,
            ),
            SizedBox(height: 1.h),
            Text(
              'No Recent Activity',
              style: GoogleFonts.inter(
                fontSize: 12.sp,
                color: theme.colorScheme.onSurface.withAlpha(153),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
