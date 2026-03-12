import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import 'package:intl/intl.dart';

import '../../../theme/app_theme.dart';

class GamificationNotificationCardWidget extends StatelessWidget {
  final Map<String, dynamic> notification;
  final VoidCallback onTap;
  final VoidCallback onDismiss;
  final Function(String) onAction;

  const GamificationNotificationCardWidget({
    super.key,
    required this.notification,
    required this.onTap,
    required this.onDismiss,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final type = notification['notification_type'] as String? ?? 'achievement';
    final isRead = notification['is_read'] as bool? ?? false;
    final title = notification['title'] as String? ?? '';
    final body = notification['body'] as String? ?? '';
    final createdAt = notification['created_at'] != null
        ? DateTime.parse(notification['created_at'])
        : DateTime.now();
    final timeAgo = _formatTimeAgo(createdAt);

    return Dismissible(
      key: Key(notification['id']),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDismiss(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 4.w),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Icon(Icons.delete, color: Colors.white, size: 6.w),
      ),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: EdgeInsets.only(bottom: 2.h),
          padding: EdgeInsets.all(3.w),
          decoration: BoxDecoration(
            color: isRead ? Colors.white : AppTheme.primaryLight.withAlpha(13),
            borderRadius: BorderRadius.circular(12.0),
            border: Border.all(
              color: isRead
                  ? Colors.grey[300]!
                  : AppTheme.primaryLight.withAlpha(77),
              width: isRead ? 1 : 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(13),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _buildIcon(type),
                  SizedBox(width: 3.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.inter(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimaryLight,
                          ),
                        ),
                        SizedBox(height: 0.5.h),
                        Text(
                          body,
                          style: GoogleFonts.inter(
                            fontSize: 11.sp,
                            color: AppTheme.textSecondaryLight,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (!isRead)
                    Container(
                      width: 2.w,
                      height: 2.w,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryLight,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
              SizedBox(height: 1.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    timeAgo,
                    style: GoogleFonts.inter(
                      fontSize: 10.sp,
                      color: AppTheme.textSecondaryLight,
                    ),
                  ),
                  if (notification['action_buttons'] != null)
                    _buildActionButtons(notification['action_buttons']),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIcon(String type) {
    IconData icon;
    Color color;

    switch (type) {
      case 'achievement':
        icon = Icons.emoji_events;
        color = AppTheme.vibrantYellow;
        break;
      case 'streak':
        icon = Icons.local_fire_department;
        color = Colors.orange;
        break;
      case 'leaderboard':
        icon = Icons.leaderboard;
        color = AppTheme.primaryLight;
        break;
      case 'quest':
        icon = Icons.flag;
        color = Colors.green;
        break;
      case 'vp_opportunity':
        icon = Icons.stars;
        color = Colors.purple;
        break;
      default:
        icon = Icons.notifications;
        color = Colors.grey;
    }

    return Container(
      padding: EdgeInsets.all(2.w),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: Icon(icon, color: color, size: 6.w),
    );
  }

  Widget _buildActionButtons(dynamic actionButtons) {
    if (actionButtons is! List) return const SizedBox.shrink();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: (actionButtons).map((button) {
        final label = button['label'] as String? ?? 'Action';
        final action = button['action'] as String? ?? '';

        return Padding(
          padding: EdgeInsets.only(left: 2.w),
          child: ElevatedButton(
            onPressed: () => onAction(action),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryLight,
              padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.8.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
            ),
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 10.sp,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM d').format(dateTime);
    }
  }
}
