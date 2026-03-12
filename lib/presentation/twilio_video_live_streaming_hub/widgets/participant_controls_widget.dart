import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import 'package:livekit_client/livekit_client.dart';

import '../../../theme/app_theme.dart';

class ParticipantControlsWidget extends StatefulWidget {
  final Room? room;

  const ParticipantControlsWidget({super.key, this.room});

  @override
  State<ParticipantControlsWidget> createState() =>
      _ParticipantControlsWidgetState();
}

class _ParticipantControlsWidgetState extends State<ParticipantControlsWidget> {
  bool _isMuted = false;
  bool _isVideoEnabled = true;
  bool _isScreenSharing = false;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.all(4.w),
      children: [
        Text(
          'Participant Controls',
          style: GoogleFonts.inter(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 2.h),
        _buildControlCard(
          'Microphone',
          _isMuted ? 'Muted' : 'Unmuted',
          _isMuted ? Icons.mic_off : Icons.mic,
          _isMuted ? AppTheme.errorLight : AppTheme.accentLight,
          () => setState(() => _isMuted = !_isMuted),
        ),
        _buildControlCard(
          'Camera',
          _isVideoEnabled ? 'Enabled' : 'Disabled',
          _isVideoEnabled ? Icons.videocam : Icons.videocam_off,
          _isVideoEnabled ? AppTheme.accentLight : AppTheme.errorLight,
          () => setState(() => _isVideoEnabled = !_isVideoEnabled),
        ),
        _buildControlCard(
          'Screen Share',
          _isScreenSharing ? 'Sharing' : 'Not Sharing',
          _isScreenSharing ? Icons.stop_screen_share : Icons.screen_share,
          _isScreenSharing ? AppTheme.warningLight : AppTheme.primaryLight,
          () => setState(() => _isScreenSharing = !_isScreenSharing),
        ),
        SizedBox(height: 2.h),
        _buildInfoCard(),
      ],
    );
  }

  Widget _buildControlCard(
    String title,
    String status,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: color.withAlpha(26),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Icon(icon, color: color, size: 6.w),
          ),
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
                  ),
                ),
                Text(
                  status,
                  style: GoogleFonts.inter(fontSize: 11.sp, color: color),
                ),
              ],
            ),
          ),
          Switch(
            value: title == 'Microphone'
                ? !_isMuted
                : title == 'Camera'
                ? _isVideoEnabled
                : _isScreenSharing,
            onChanged: (_) => onTap(),
            activeThumbColor: color,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.primaryLight.withAlpha(26),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'LiveKit Integration',
            style: GoogleFonts.inter(
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            'Real-time video conferencing with participant controls, screen sharing, and recording capabilities.',
            style: GoogleFonts.inter(
              fontSize: 11.sp,
              color: AppTheme.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }
}
