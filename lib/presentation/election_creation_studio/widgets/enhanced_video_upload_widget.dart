import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sizer/sizer.dart';
import 'package:google_fonts/google_fonts.dart' as google_fonts;

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

/// Enhanced Video Upload Widget with multiple video support
class EnhancedVideoUploadWidget extends StatefulWidget {
  final List<String> videoUrls;
  final Function(List<String>) onVideosChanged;
  final int minWatchSeconds;
  final Function(int) onMinWatchSecondsChanged;
  final int minWatchPercentage;
  final Function(int) onMinWatchPercentageChanged;
  final String enforcementType;
  final Function(String) onEnforcementTypeChanged;
  final bool requireVideoWatch;
  final Function(bool) onRequireVideoWatchChanged;

  const EnhancedVideoUploadWidget({
    super.key,
    required this.videoUrls,
    required this.onVideosChanged,
    required this.minWatchSeconds,
    required this.onMinWatchSecondsChanged,
    required this.minWatchPercentage,
    required this.onMinWatchPercentageChanged,
    required this.enforcementType,
    required this.onEnforcementTypeChanged,
    required this.requireVideoWatch,
    required this.onRequireVideoWatchChanged,
  });

  @override
  State<EnhancedVideoUploadWidget> createState() =>
      _EnhancedVideoUploadWidgetState();
}

class _EnhancedVideoUploadWidgetState extends State<EnhancedVideoUploadWidget> {
  final ImagePicker _imagePicker = ImagePicker();
  final TextEditingController _urlController = TextEditingController();

  void _addVideoFromGallery() async {
    if (widget.videoUrls.length >= 3) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Maximum 3 videos allowed')));
      return;
    }

    final XFile? video = await _imagePicker.pickVideo(
      source: ImageSource.gallery,
    );
    if (video != null) {
      final newUrls = List<String>.from(widget.videoUrls);
      newUrls.add(video.path);
      widget.onVideosChanged(newUrls);
    }
  }

  void _addVideoFromUrl() {
    if (widget.videoUrls.length >= 3) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Maximum 3 videos allowed')));
      return;
    }

    if (_urlController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Please enter video URL')));
      return;
    }

    final newUrls = List<String>.from(widget.videoUrls);
    newUrls.add(_urlController.text.trim());
    widget.onVideosChanged(newUrls);
    _urlController.clear();
  }

  void _removeVideo(int index) {
    final newUrls = List<String>.from(widget.videoUrls);
    newUrls.removeAt(index);
    widget.onVideosChanged(newUrls);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.backgroundLight,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.video_library,
                color: AppTheme.primaryLight,
                size: 6.w,
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: Text(
                  'Video Watch Requirement (Optional)',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryLight,
                  ),
                ),
              ),
              Switch(
                value: widget.requireVideoWatch,
                onChanged: widget.onRequireVideoWatchChanged,
                activeThumbColor: AppTheme.accentLight,
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Text(
            widget.requireVideoWatch
                ? 'Voters must watch video(s) before voting'
                : 'Video watch is optional for this election',
            style: TextStyle(fontSize: 11.sp, color: Colors.grey.shade600),
          ),
          if (widget.requireVideoWatch) ...[
            SizedBox(height: 2.h),
            Divider(),
            SizedBox(height: 2.h),
            _buildVideoList(),
            SizedBox(height: 2.h),
            _buildAddVideoButtons(),
            SizedBox(height: 2.h),
            _buildEnforcementSettings(),
          ],
        ],
      ),
    );
  }

  Widget _buildVideoList() {
    if (widget.videoUrls.isEmpty) {
      return Container(
        padding: EdgeInsets.all(3.w),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8.0),
          border: Border.all(
            color: Colors.grey.shade300,
            style: BorderStyle.solid,
          ),
        ),
        child: Center(
          child: Text(
            'No videos added yet',
            style: TextStyle(fontSize: 11.sp, color: Colors.grey.shade600),
          ),
        ),
      );
    }

    return Column(
      children: widget.videoUrls.asMap().entries.map((entry) {
        final index = entry.key;
        final url = entry.value;
        return Card(
          margin: EdgeInsets.only(bottom: 1.h),
          child: ListTile(
            leading: Icon(Icons.video_file, color: AppTheme.primaryLight),
            title: Text(
              'Video ${index + 1}',
              style: google_fonts.GoogleFonts.inter(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              url.length > 40 ? '${url.substring(0, 40)}...' : url,
              style: google_fonts.GoogleFonts.inter(fontSize: 10.sp),
              overflow: TextOverflow.ellipsis,
            ),
            trailing: IconButton(
              icon: Icon(Icons.delete, color: Colors.red),
              onPressed: () => _removeVideo(index),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAddVideoButtons() {
    return Column(
      children: [
        ElevatedButton.icon(
          onPressed: _addVideoFromGallery,
          icon: Icon(Icons.videocam, size: 5.w),
          label: Text('Upload Video from Gallery'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryLight,
            foregroundColor: Colors.white,
            minimumSize: Size(double.infinity, 6.h),
          ),
        ),
        SizedBox(height: 1.h),
        Text(
          'OR',
          style: google_fonts.GoogleFonts.inter(
            fontSize: 11.sp,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade600,
          ),
        ),
        SizedBox(height: 1.h),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _urlController,
                decoration: InputDecoration(
                  labelText: 'YouTube/Vimeo URL',
                  border: OutlineInputBorder(),
                  hintText: 'https://youtube.com/watch?v=...',
                ),
              ),
            ),
            SizedBox(width: 2.w),
            ElevatedButton(
              onPressed: _addVideoFromUrl,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentLight,
                foregroundColor: Colors.white,
                minimumSize: Size(20.w, 6.h),
              ),
              child: Text('Add'),
            ),
          ],
        ),
        SizedBox(height: 1.h),
        Text(
          'Maximum 3 videos allowed',
          style: google_fonts.GoogleFonts.inter(
            fontSize: 10.sp,
            color: Colors.grey.shade600,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  Widget _buildEnforcementSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Watch Time Enforcement',
          style: google_fonts.GoogleFonts.inter(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimaryLight,
          ),
        ),
        SizedBox(height: 1.h),
        DropdownButtonFormField<String>(
          initialValue: widget.enforcementType,
          decoration: InputDecoration(
            labelText: 'Enforcement Type',
            border: OutlineInputBorder(),
          ),
          items: [
            DropdownMenuItem(
              value: 'seconds',
              child: Text('Minimum Watch Time (Seconds)'),
            ),
            DropdownMenuItem(
              value: 'percentage',
              child: Text('Minimum Watch Percentage'),
            ),
          ],
          onChanged: (value) {
            if (value != null) {
              widget.onEnforcementTypeChanged(value);
            }
          },
        ),
        SizedBox(height: 2.h),
        if (widget.enforcementType == 'seconds') ...[
          Text(
            'Minimum Watch Time: ${widget.minWatchSeconds} seconds',
            style: google_fonts.GoogleFonts.inter(
              fontSize: 12.sp,
              color: AppTheme.textSecondaryLight,
            ),
          ),
          Slider(
            value: widget.minWatchSeconds.toDouble(),
            min: 0,
            max: 300,
            divisions: 60,
            label: '${widget.minWatchSeconds}s',
            onChanged: (value) =>
                widget.onMinWatchSecondsChanged(value.toInt()),
          ),
        ] else ...[
          Text(
            'Minimum Watch Percentage: ${widget.minWatchPercentage}%',
            style: google_fonts.GoogleFonts.inter(
              fontSize: 12.sp,
              color: AppTheme.textSecondaryLight,
            ),
          ),
          Slider(
            value: widget.minWatchPercentage.toDouble(),
            min: 0,
            max: 100,
            divisions: 20,
            label: '${widget.minWatchPercentage}%',
            onChanged: (value) =>
                widget.onMinWatchPercentageChanged(value.toInt()),
          ),
        ],
      ],
    );
  }
}
