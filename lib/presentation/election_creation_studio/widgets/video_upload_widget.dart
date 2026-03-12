import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart' as google_fonts;
import 'package:image_picker/image_picker.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class VideoUploadWidget extends StatelessWidget {
  final String? videoPath;
  final Function(String) onVideoSelected;
  final int minWatchTimeSeconds;
  final Function(int) onMinWatchTimeChanged;
  final bool requireFullWatch;
  final Function(bool) onRequireFullWatchChanged;

  const VideoUploadWidget({
    super.key,
    required this.videoPath,
    required this.onVideoSelected,
    required this.minWatchTimeSeconds,
    required this.onMinWatchTimeChanged,
    required this.requireFullWatch,
    required this.onRequireFullWatchChanged,
  });

  @override
  Widget build(BuildContext context) {
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
            'Election Topic Video (Optional)',
            style: google_fonts.GoogleFonts.inter(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          SizedBox(height: 2.h),
          ElevatedButton.icon(
            onPressed: () async {
              final ImagePicker picker = ImagePicker();
              final XFile? video = await picker.pickVideo(
                source: ImageSource.gallery,
              );
              if (video != null) {
                onVideoSelected(video.path);
              }
            },
            icon: Icon(Icons.videocam, size: 5.w),
            label: Text(videoPath == null ? 'Upload Video' : 'Video Selected'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryLight,
              foregroundColor: Colors.white,
              minimumSize: Size(double.infinity, 6.h),
            ),
          ),
          if (videoPath != null) ...[
            SizedBox(height: 2.h),
            Divider(),
            SizedBox(height: 2.h),
            Text(
              'Minimum Watch Time Requirements',
              style: google_fonts.GoogleFonts.inter(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimaryLight,
              ),
            ),
            SizedBox(height: 1.h),
            SwitchListTile(
              title: Text('Require Full Video Watch'),
              subtitle: Text('Voters must watch entire video'),
              value: requireFullWatch,
              onChanged: onRequireFullWatchChanged,
              contentPadding: EdgeInsets.zero,
            ),
            if (!requireFullWatch) ...[
              SizedBox(height: 1.h),
              Text(
                'Minimum Watch Time (seconds)',
                style: google_fonts.GoogleFonts.inter(
                  fontSize: 12.sp,
                  color: AppTheme.textSecondaryLight,
                ),
              ),
              SizedBox(height: 1.h),
              Row(
                children: [
                  Expanded(
                    child: Slider(
                      value: minWatchTimeSeconds.toDouble(),
                      min: 0,
                      max: 300,
                      divisions: 60,
                      label: '$minWatchTimeSeconds seconds',
                      onChanged: (value) =>
                          onMinWatchTimeChanged(value.toInt()),
                    ),
                  ),
                  SizedBox(width: 2.w),
                  Text(
                    '$minWatchTimeSeconds s',
                    style: google_fonts.GoogleFonts.inter(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryLight,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ],
      ),
    );
  }
}
