import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

class ModerationControlsWidget extends StatefulWidget {
  final String roomId;
  final List<Map<String, dynamic>> participants;
  final Function(String userId) onMuteParticipant;

  const ModerationControlsWidget({
    super.key,
    required this.roomId,
    required this.participants,
    required this.onMuteParticipant,
  });

  @override
  State<ModerationControlsWidget> createState() =>
      _ModerationControlsWidgetState();
}

class _ModerationControlsWidgetState extends State<ModerationControlsWidget> {
  bool _discussionTimerActive = false;
  final int _timerMinutes = 10;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.all(4.w),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Moderation Controls',
                style: GoogleFonts.inter(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              Spacer(),
              IconButton(
                icon: Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          _buildControlCard(
            theme,
            icon: 'timer',
            title: 'Discussion Timer',
            subtitle: _discussionTimerActive
                ? '$_timerMinutes minutes remaining'
                : 'Set time limit for discussion',
            trailing: Switch(
              value: _discussionTimerActive,
              onChanged: (value) {
                setState(() => _discussionTimerActive = value);
              },
            ),
          ),
          SizedBox(height: 2.h),
          _buildControlCard(
            theme,
            icon: 'block',
            title: 'Content Moderation',
            subtitle: 'AI-assisted flagging enabled',
            trailing: Icon(Icons.check_circle, color: Colors.green),
          ),
          SizedBox(height: 2.h),
          _buildControlCard(
            theme,
            icon: 'people',
            title: 'Participant Management',
            subtitle: '${widget.participants.length} active participants',
            trailing: Icon(Icons.chevron_right),
            onTap: () => _showParticipantManagement(),
          ),
          SizedBox(height: 2.h),
          _buildControlCard(
            theme,
            icon: 'lock',
            title: 'Lock Room',
            subtitle: 'Prevent new participants from joining',
            trailing: Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }

  Widget _buildControlCard(
    ThemeData theme, {
    required String icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(3.w),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(2.w),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: CustomIconWidget(
                iconName: icon,
                color: theme.colorScheme.primary,
                size: 24,
              ),
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  SizedBox(height: 0.5.h),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 12.sp,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (trailing != null) trailing,
          ],
        ),
      ),
    );
  }

  void _showParticipantManagement() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Manage Participants'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: widget.participants.length,
            itemBuilder: (context, index) {
              final participant = widget.participants[index];
              final userName =
                  participant['users']?['email']?.split('@')[0] ?? 'User';
              final isMuted = participant['is_muted'] ?? false;

              return ListTile(
                title: Text(userName),
                trailing: TextButton(
                  onPressed: () {
                    widget.onMuteParticipant(participant['user_id']);
                    Navigator.pop(context);
                  },
                  child: Text(isMuted ? 'Unmute' : 'Mute'),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }
}
