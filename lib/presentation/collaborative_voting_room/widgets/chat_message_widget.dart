import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class ChatMessageWidget extends StatelessWidget {
  final Map<String, dynamic> message;
  final Function(String emoji) onReaction;

  const ChatMessageWidget({
    super.key,
    required this.message,
    required this.onReaction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final userName = message['users']?['email']?.split('@')[0] ?? 'User';
    final messageText = message['message'] ?? '';
    final timestamp = message['created_at'] != null
        ? DateTime.parse(message['created_at'])
        : DateTime.now();
    final timeAgo = _getTimeAgo(timestamp);

    return Padding(
      padding: EdgeInsets.only(bottom: 2.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 20.w,
            backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.2),
            child: Text(
              userName[0].toUpperCase(),
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      userName,
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    SizedBox(width: 2.w),
                    Text(
                      timeAgo,
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 0.5.h),
                Text(
                  messageText,
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                SizedBox(height: 1.h),
                _buildReactionBar(theme),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReactionBar(ThemeData theme) {
    final reactions = ['👍', '👎', '❤️', '🤔'];

    return Row(
      children: reactions.map((emoji) {
        return GestureDetector(
          onTap: () => onReaction(emoji),
          child: Container(
            margin: EdgeInsets.only(right: 2.w),
            padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(emoji, style: TextStyle(fontSize: 16.sp)),
          ),
        );
      }).toList(),
    );
  }

  String _getTimeAgo(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}
