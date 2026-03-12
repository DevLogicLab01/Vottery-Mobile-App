import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class ParticipantManagementWidget extends StatelessWidget {
  final List<Participant> participants;
  final Room? room;

  const ParticipantManagementWidget({
    super.key,
    required this.participants,
    this.room,
  });

  @override
  Widget build(BuildContext context) {
    return participants.isEmpty
        ? _buildEmptyState()
        : ListView.builder(
            padding: EdgeInsets.all(4.w),
            itemCount: participants.length,
            itemBuilder: (context, index) {
              return _buildParticipantCard(participants[index]);
            },
          );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 20.w,
            color: AppTheme.textSecondaryLight.withAlpha(128),
          ),
          SizedBox(height: 2.h),
          Text(
            'No participants yet',
            style: TextStyle(
              fontSize: 14.sp,
              color: AppTheme.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParticipantCard(Participant participant) {
    final isMicEnabled = participant.isMicrophoneEnabled();
    final isCameraEnabled = participant.isCameraEnabled();

    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 6.w,
            backgroundColor: AppTheme.primaryLight.withAlpha(26),
            child: Text(
              participant.name.substring(0, 1).toUpperCase() ?? 'U',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w700,
                color: AppTheme.primaryLight,
              ),
            ),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  participant.name ?? 'Unknown',
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimaryLight,
                  ),
                ),
                Text(
                  participant.identity,
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: AppTheme.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
          _buildControlIcon(
            isMicEnabled ? Icons.mic : Icons.mic_off,
            isMicEnabled ? AppTheme.accentLight : AppTheme.errorLight,
          ),
          SizedBox(width: 2.w),
          _buildControlIcon(
            isCameraEnabled ? Icons.videocam : Icons.videocam_off,
            isCameraEnabled ? AppTheme.accentLight : AppTheme.errorLight,
          ),
        ],
      ),
    );
  }

  Widget _buildControlIcon(IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(2.w),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 4.w, color: color),
    );
  }
}
