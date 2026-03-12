import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import 'package:timeago/timeago.dart' as timeago;

class GamificationNotificationCardWidget extends StatelessWidget {
  final Map<String, dynamic> notification;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const GamificationNotificationCardWidget({
    super.key,
    required this.notification,
    required this.onTap,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final type = notification['notification_type'] as String? ?? 'general';
    final isRead = notification['is_read'] as bool? ?? false;
    final title = notification['title'] as String? ?? 'Notification';
    final body = notification['body'] as String? ?? '';
    final createdAt = notification['created_at'] != null
        ? DateTime.parse(notification['created_at'])
        : DateTime.now();

    return Dismissible(
      key: Key(notification['id'].toString()),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDismiss(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 4.w),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: Card(
        margin: EdgeInsets.only(bottom: 2.h),
        elevation: isRead ? 0 : 2,
        color: isRead ? Colors.grey[100] : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
          side: BorderSide(
            color: isRead
                ? Colors.transparent
                : _getTypeColor(type).withAlpha(77),
            width: 2.0,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12.0),
          child: Padding(
            padding: EdgeInsets.all(4.w),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildIcon(type, isRead),
                SizedBox(width: 3.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: GoogleFonts.inter(
                                fontSize: 14.sp,
                                fontWeight: isRead
                                    ? FontWeight.w500
                                    : FontWeight.w700,
                                color: theme.colorScheme.onSurface,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (!isRead)
                            Container(
                              width: 8.0,
                              height: 8.0,
                              decoration: const BoxDecoration(
                                color: Colors.blue,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      SizedBox(height: 0.5.h),
                      Text(
                        body,
                        style: GoogleFonts.inter(
                          fontSize: 12.sp,
                          color: Colors.grey[700],
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 1.h),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 12.sp,
                            color: Colors.grey[600],
                          ),
                          SizedBox(width: 1.w),
                          Text(
                            timeago.format(createdAt),
                            style: GoogleFonts.inter(
                              fontSize: 10.sp,
                              color: Colors.grey[600],
                            ),
                          ),
                          const Spacer(),
                          _buildActionButton(type, theme),
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

  Widget _buildIcon(String type, bool isRead) {
    final color = isRead ? Colors.grey : _getTypeColor(type);
    final icon = _getTypeIcon(type);

    return Container(
      padding: EdgeInsets.all(2.w),
      decoration: BoxDecoration(
        color: color.withAlpha(51),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 24.sp),
    );
  }

  Widget _buildActionButton(String type, ThemeData theme) {
    final buttonData = _getActionButtonData(type);
    if (buttonData == null) return const SizedBox.shrink();

    return ElevatedButton(
      onPressed: () {
        // Handle action button
        debugPrint('Action: ${buttonData['label']} for $type');
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: _getTypeColor(type),
        padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      ),
      child: Text(
        buttonData['label'] as String,
        style: GoogleFonts.inter(
          fontSize: 10.sp,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'badge_unlocked':
        return Colors.orange;
      case 'streak_maintained':
        return Colors.red;
      case 'leaderboard_change':
        return Colors.blue;
      case 'quest_progress':
        return Colors.green;
      case 'vp_opportunity':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'badge_unlocked':
        return Icons.stars;
      case 'streak_maintained':
        return Icons.local_fire_department;
      case 'leaderboard_change':
        return Icons.leaderboard;
      case 'quest_progress':
        return Icons.flag;
      case 'vp_opportunity':
        return Icons.monetization_on;
      default:
        return Icons.notifications;
    }
  }

  Map<String, dynamic>? _getActionButtonData(String type) {
    switch (type) {
      case 'badge_unlocked':
        return {'label': 'View Badge', 'action': 'view_badge'};
      case 'vp_opportunity':
        return {'label': 'Join Now', 'action': 'join_now'};
      case 'quest_progress':
        return {'label': 'Claim Reward', 'action': 'claim_reward'};
      default:
        return null;
    }
  }
}
