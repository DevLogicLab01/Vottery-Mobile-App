import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class RecordingManagementWidget extends StatefulWidget {
  final bool isStreaming;
  final Room? room;

  const RecordingManagementWidget({
    super.key,
    required this.isStreaming,
    this.room,
  });

  @override
  State<RecordingManagementWidget> createState() =>
      _RecordingManagementWidgetState();
}

class _RecordingManagementWidgetState extends State<RecordingManagementWidget> {
  bool _isRecording = false;
  final List<Map<String, dynamic>> _recordings = [
    {
      'id': '1',
      'title': 'Election Debate - March 15',
      'duration': '1:45:32',
      'size': '2.4 GB',
      'date': DateTime.now().subtract(const Duration(days: 2)),
    },
    {
      'id': '2',
      'title': 'Town Hall Meeting',
      'duration': '0:58:12',
      'size': '1.1 GB',
      'date': DateTime.now().subtract(const Duration(days: 5)),
    },
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRecordingControls(),
          SizedBox(height: 3.h),
          Text(
            'Recorded Streams',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          SizedBox(height: 2.h),
          ..._recordings.map((recording) => _buildRecordingCard(recording)),
        ],
      ),
    );
  }

  Widget _buildRecordingControls() {
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
            'Recording Controls',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              Icon(
                _isRecording
                    ? Icons.fiber_manual_record
                    : Icons.radio_button_unchecked,
                size: 6.w,
                color: _isRecording
                    ? AppTheme.errorLight
                    : AppTheme.textSecondaryLight,
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Text(
                  _isRecording ? 'Recording in progress' : 'Not recording',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: AppTheme.textPrimaryLight,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: widget.isStreaming
                    ? () {
                        setState(() => _isRecording = !_isRecording);
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isRecording
                      ? AppTheme.errorLight
                      : AppTheme.accentLight,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    horizontal: 4.w,
                    vertical: 1.5.h,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                child: Text(
                  _isRecording ? 'Stop' : 'Start',
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecordingCard(Map<String, dynamic> recording) {
    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(3.w),
                decoration: BoxDecoration(
                  color: AppTheme.primaryLight.withAlpha(26),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Icon(
                  Icons.play_circle_outline,
                  size: 6.w,
                  color: AppTheme.primaryLight,
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recording['title'] as String,
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimaryLight,
                      ),
                    ),
                    SizedBox(height: 0.5.h),
                    Text(
                      _formatDate(recording['date'] as DateTime),
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
          SizedBox(height: 2.h),
          Row(
            children: [
              _buildInfoChip(
                Icons.access_time,
                recording['duration'] as String,
              ),
              SizedBox(width: 2.w),
              _buildInfoChip(Icons.storage, recording['size'] as String),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(6.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 3.w, color: AppTheme.textSecondaryLight),
          SizedBox(width: 1.w),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.sp,
              color: AppTheme.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.month}/${date.day}/${date.year}';
    }
  }
}
