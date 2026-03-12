import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../services/auth_service.dart';

class EnhancedMessageBubbleWidget extends StatelessWidget {
  final Map<String, dynamic> message;
  final VoidCallback onLongPress;

  const EnhancedMessageBubbleWidget({
    super.key,
    required this.message,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authService = AuthService.instance;
    final isCurrentUser = message['sender_id'] == authService.currentUser?.id;
    final messageType = message['message_type'] ?? 'text';
    final content = message['content'] ?? '';
    final createdAt = DateTime.parse(message['created_at']);

    return GestureDetector(
      onLongPress: onLongPress,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 1.h),
        child: Row(
          mainAxisAlignment: isCurrentUser
              ? MainAxisAlignment.end
              : MainAxisAlignment.start,
          children: [
            if (!isCurrentUser) ...[
              CircleAvatar(
                radius: 4.w,
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Text(
                  content[0].toUpperCase(),
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
              SizedBox(width: 2.w),
            ],
            Flexible(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
                decoration: BoxDecoration(
                  color: isCurrentUser
                      ? theme.colorScheme.primary
                      : theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(4.w),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (messageType == 'voice') ...[
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.play_arrow,
                            color: isCurrentUser
                                ? theme.colorScheme.onPrimary
                                : theme.colorScheme.onSurface,
                          ),
                          SizedBox(width: 2.w),
                          Text(
                            'Voice message',
                            style: TextStyle(
                              fontSize: 13.sp,
                              color: isCurrentUser
                                  ? theme.colorScheme.onPrimary
                                  : theme.colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ] else if (messageType == 'media') ...[
                      Icon(
                        Icons.image,
                        color: isCurrentUser
                            ? theme.colorScheme.onPrimary
                            : theme.colorScheme.onSurface,
                        size: 10.w,
                      ),
                    ] else ...[
                      Text(
                        content,
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: isCurrentUser
                              ? theme.colorScheme.onPrimary
                              : theme.colorScheme.onSurface,
                        ),
                      ),
                    ],
                    SizedBox(height: 0.5.h),
                    Text(
                      timeago.format(createdAt),
                      style: TextStyle(
                        fontSize: 10.sp,
                        color: isCurrentUser
                            ? theme.colorScheme.onPrimary.withValues(alpha: 0.7)
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
