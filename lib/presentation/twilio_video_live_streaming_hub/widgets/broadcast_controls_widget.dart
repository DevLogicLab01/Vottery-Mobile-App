import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class BroadcastControlsWidget extends StatelessWidget {
  final bool isStreaming;
  final VoidCallback onStartStream;
  final VoidCallback onStopStream;
  final Room? room;

  const BroadcastControlsWidget({
    super.key,
    required this.isStreaming,
    required this.onStartStream,
    required this.onStopStream,
    this.room,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Broadcast Controls',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          SizedBox(height: 3.h),
          _buildStreamStatusCard(),
          SizedBox(height: 3.h),
          _buildQualitySettings(),
          SizedBox(height: 3.h),
          _buildNetworkStatus(),
        ],
      ),
    );
  }

  Widget _buildStreamStatusCard() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isStreaming
              ? [AppTheme.accentLight, Color(0xFF059669)]
              : [AppTheme.textSecondaryLight, AppTheme.borderLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        children: [
          Icon(
            isStreaming ? Icons.videocam : Icons.videocam_off,
            size: 15.w,
            color: Colors.white,
          ),
          SizedBox(height: 2.h),
          Text(
            isStreaming ? 'Stream Active' : 'Stream Offline',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            isStreaming
                ? 'Broadcasting to viewers'
                : 'Ready to start streaming',
            style: TextStyle(
              fontSize: 11.sp,
              color: Colors.white.withAlpha(204),
            ),
          ),
          SizedBox(height: 3.h),
          ElevatedButton(
            onPressed: isStreaming ? onStopStream : onStartStream,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: isStreaming
                  ? AppTheme.errorLight
                  : AppTheme.accentLight,
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
            ),
            child: Text(
              isStreaming ? 'Stop Stream' : 'Start Stream',
              style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQualitySettings() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Stream Quality',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          SizedBox(height: 2.h),
          _buildQualityOption('1080p HD', '1920x1080', true),
          _buildQualityOption('720p', '1280x720', false),
          _buildQualityOption('480p', '854x480', false),
        ],
      ),
    );
  }

  Widget _buildQualityOption(String label, String resolution, bool selected) {
    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: selected
            ? AppTheme.primaryLight.withAlpha(26)
            : AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(
          color: selected ? AppTheme.primaryLight : AppTheme.borderLight,
          width: selected ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            selected ? Icons.check_circle : Icons.circle_outlined,
            size: 5.w,
            color: selected
                ? AppTheme.primaryLight
                : AppTheme.textSecondaryLight,
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimaryLight,
                  ),
                ),
                Text(
                  resolution,
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: AppTheme.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNetworkStatus() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Network Status',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          SizedBox(height: 2.h),
          _buildNetworkMetric('Connection', 'Excellent', AppTheme.accentLight),
          _buildNetworkMetric('Latency', '45ms', AppTheme.secondaryLight),
          _buildNetworkMetric('Bitrate', '2.5 Mbps', AppTheme.primaryLight),
        ],
      ),
    );
  }

  Widget _buildNetworkMetric(String label, String value, Color color) {
    return Padding(
      padding: EdgeInsets.only(bottom: 2.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11.sp,
              color: AppTheme.textSecondaryLight,
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
            decoration: BoxDecoration(
              color: color.withAlpha(26),
              borderRadius: BorderRadius.circular(6.0),
            ),
            child: Text(
              value,
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
