import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:file_picker/file_picker.dart';

import '../../../services/presentation_slides_service.dart';
import '../../../theme/app_theme.dart';

/// Slide upload widget for uploading PDF/PowerPoint files
class SlideUploadWidget extends StatefulWidget {
  final String electionId;
  final VoidCallback onUploaded;

  const SlideUploadWidget({
    super.key,
    required this.electionId,
    required this.onUploaded,
  });

  @override
  State<SlideUploadWidget> createState() => _SlideUploadWidgetState();
}

class _SlideUploadWidgetState extends State<SlideUploadWidget> {
  final PresentationSlidesService _slidesService =
      PresentationSlidesService.instance;

  bool _isUploading = false;

  Future<void> _uploadDeck() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.bytes != null) {
          setState(() => _isUploading = true);

          final deck = await _slidesService.uploadDeckFile(
            electionId: widget.electionId,
            fileName: file.name,
            fileBytes: file.bytes!,
            fileType: 'pdf',
          );

          setState(() => _isUploading = false);

          if (deck != null && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Presentation uploaded successfully'),
                backgroundColor: AppTheme.accentLight,
              ),
            );
            widget.onUploaded();
          }
        }
      }
    } catch (e) {
      setState(() => _isUploading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to upload presentation'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Container(
        margin: EdgeInsets.all(4.w),
        padding: EdgeInsets.all(6.w),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.upload_file,
              size: 48.sp,
              color: theme.colorScheme.primary,
            ),
            SizedBox(height: 2.h),
            Text(
              'Upload Presentation',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              'Upload PDF slides to share with voters',
              style: TextStyle(
                fontSize: 13.sp,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 3.h),
            SizedBox(
              width: double.infinity,
              height: 6.h,
              child: ElevatedButton.icon(
                onPressed: _isUploading ? null : _uploadDeck,
                icon: _isUploading
                    ? SizedBox(
                        height: 16.sp,
                        width: 16.sp,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2.0,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : const Icon(Icons.upload),
                label: Text(
                  _isUploading ? 'Uploading...' : 'Choose PDF File',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentLight,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                ),
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              'Supported format: PDF (max 50MB)',
              style: TextStyle(
                fontSize: 11.sp,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
