import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:timeago/timeago.dart' as timeago;

class NotificationCardWidget extends StatelessWidget {
  final Map<String, dynamic> notification;

  const NotificationCardWidget({super.key, required this.notification});

  @override
  Widget build(BuildContext context) {
    final type = notification['type'] ?? 'unknown';
    final title = notification['title'] ?? 'Notification';
    final body = notification['body'] ?? '';
    final createdAt = DateTime.tryParse(notification['created_at'] ?? '');
    final delivered = notification['delivered'] ?? false;
    final opened = notification['opened'] ?? false;

    return Card(
      margin: EdgeInsets.only(bottom: 2.h),
      child: ListTile(
        leading: _buildIcon(type),
        title: Text(
          title,
          style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 0.5.h),
            Text(
              body,
              style: TextStyle(fontSize: 12.sp),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 0.5.h),
            Row(
              children: [
                if (delivered) Icon(Icons.check, size: 14, color: Colors.green),
                if (opened)
                  Icon(Icons.visibility, size: 14, color: Colors.blue),
                SizedBox(width: 1.w),
                Text(
                  createdAt != null ? timeago.format(createdAt) : 'Unknown',
                  style: TextStyle(fontSize: 11.sp, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }

  Widget _buildIcon(String type) {
    IconData icon;
    Color color;

    switch (type) {
      case 'quest_completion':
        icon = Icons.emoji_events;
        color = Colors.purple;
        break;
      case 'security_alert':
        icon = Icons.security;
        color = Colors.red;
        break;
      case 'vp_reward':
        icon = Icons.monetization_on;
        color = Colors.green;
        break;
      case 'social_interaction':
        icon = Icons.people;
        color = Colors.blue;
        break;
      default:
        icon = Icons.notifications;
        color = Colors.grey;
    }

    return Container(
      padding: EdgeInsets.all(2.w),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: color, size: 24),
    );
  }
}
