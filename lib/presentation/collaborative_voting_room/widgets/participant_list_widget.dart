import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class ParticipantListWidget extends StatelessWidget {
  final List<Map<String, dynamic>> participants;
  final bool isCreator;
  final Function(String userId)? onMute;

  const ParticipantListWidget({
    super.key,
    required this.participants,
    this.isCreator = false,
    this.onMute,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(
                'Participants',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              Spacer(),
              Text(
                '${participants.length} active',
                style: TextStyle(
                  fontSize: 13.sp,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          ListView.builder(
            shrinkWrap: true,
            itemCount: participants.length,
            itemBuilder: (context, index) {
              final participant = participants[index];
              final userName =
                  participant['users']?['email']?.split('@')[0] ?? 'User';
              final isMuted = participant['is_muted'] ?? false;

              return ListTile(
                leading: Stack(
                  children: [
                    CircleAvatar(
                      backgroundColor: theme.colorScheme.primary.withValues(
                        alpha: 0.2,
                      ),
                      child: Text(
                        userName[0].toUpperCase(),
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 12.w,
                        height: 12.w,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: theme.colorScheme.surface,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                title: Text(
                  userName,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                subtitle: isMuted
                    ? Text(
                        'Muted',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: theme.colorScheme.error,
                        ),
                      )
                    : null,
                trailing: isCreator
                    ? IconButton(
                        icon: Icon(
                          isMuted ? Icons.mic_off : Icons.mic,
                          color: isMuted
                              ? theme.colorScheme.error
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                        onPressed: () => onMute?.call(participant['user_id']),
                      )
                    : null,
              );
            },
          ),
        ],
      ),
    );
  }
}
