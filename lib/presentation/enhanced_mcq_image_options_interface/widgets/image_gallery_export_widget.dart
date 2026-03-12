import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:google_fonts/google_fonts.dart' as google_fonts;

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class ImageGalleryExportWidget extends StatefulWidget {
  final List<Map<String, dynamic>> questions;

  const ImageGalleryExportWidget({super.key, required this.questions});

  @override
  State<ImageGalleryExportWidget> createState() =>
      _ImageGalleryExportWidgetState();
}

class _ImageGalleryExportWidgetState extends State<ImageGalleryExportWidget> {
  String _exportFormat = 'zip';
  bool _includeVotingResults = true;
  bool _isExporting = false;

  int _getTotalImages() {
    int count = 0;
    for (var question in widget.questions) {
      final options = List<Map<String, dynamic>>.from(question['options']);
      count += options.where((opt) => opt['image_url'] != null).length;
    }
    return count;
  }

  Future<void> _exportGallery() async {
    setState(() => _isExporting = true);

    // Simulate export process
    await Future.delayed(const Duration(seconds: 3));

    setState(() => _isExporting = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gallery exported successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalImages = _getTotalImages();

    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildExportHeader(totalImages),
          SizedBox(height: 2.h),
          _buildExportSettings(),
          SizedBox(height: 2.h),
          _buildImageGalleryPreview(),
          SizedBox(height: 2.h),
          _buildExportButton(totalImages),
        ],
      ),
    );
  }

  Widget _buildExportHeader(int totalImages) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.accentLight.withAlpha(26),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Row(
        children: [
          Icon(Icons.photo_library, color: AppTheme.accentLight, size: 8.w),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Image Gallery Export',
                  style: google_fonts.GoogleFonts.inter(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryLight,
                  ),
                ),
                SizedBox(height: 0.5.h),
                Text(
                  '$totalImages images across ${widget.questions.length} questions',
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExportSettings() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Export Settings',
              style: google_fonts.GoogleFonts.inter(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 2.h),
            DropdownButtonFormField<String>(
              initialValue: _exportFormat,
              decoration: InputDecoration(
                labelText: 'Export Format',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                prefixIcon: Icon(Icons.file_download, size: 5.w),
              ),
              items: [
                DropdownMenuItem(value: 'zip', child: Text('ZIP Archive')),
                DropdownMenuItem(value: 'pdf', child: Text('PDF Document')),
                DropdownMenuItem(value: 'json', child: Text('JSON with URLs')),
              ],
              onChanged: (value) {
                setState(() {
                  _exportFormat = value!;
                });
              },
            ),
            SizedBox(height: 2.h),
            SwitchListTile(
              title: Text(
                'Include Voting Results',
                style: TextStyle(fontSize: 12.sp),
              ),
              subtitle: Text(
                'Export with vote counts and analytics',
                style: TextStyle(fontSize: 10.sp, color: Colors.grey.shade600),
              ),
              value: _includeVotingResults,
              onChanged: (value) {
                setState(() {
                  _includeVotingResults = value;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageGalleryPreview() {
    final allImages = <Map<String, dynamic>>[];

    for (var i = 0; i < widget.questions.length; i++) {
      final question = widget.questions[i];
      final options = List<Map<String, dynamic>>.from(question['options']);

      for (var j = 0; j < options.length; j++) {
        if (options[j]['image_url'] != null) {
          allImages.add({
            'question_index': i,
            'option_index': j,
            'image_url': options[j]['image_url'],
            'text': options[j]['text'],
            'alt_text': options[j]['alt_text'],
          });
        }
      }
    }

    if (allImages.isEmpty) {
      return Card(
        elevation: 2,
        child: Padding(
          padding: EdgeInsets.all(8.w),
          child: Column(
            children: [
              Icon(Icons.image_not_supported, size: 15.w, color: Colors.grey),
              SizedBox(height: 2.h),
              Text(
                'No images to export',
                style: TextStyle(fontSize: 12.sp, color: Colors.grey),
              ),
              SizedBox(height: 1.h),
              Text(
                'Add images to options in the Question Builder tab',
                style: TextStyle(fontSize: 10.sp, color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Gallery Preview',
              style: google_fonts.GoogleFonts.inter(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 2.h),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 2.w,
                mainAxisSpacing: 2.h,
                childAspectRatio: 1,
              ),
              itemCount: allImages.length,
              itemBuilder: (context, index) {
                final image = allImages[index];
                return Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8.0),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(8.0),
                          ),
                          child: Container(
                            color: Colors.grey.shade200,
                            child: Icon(Icons.image, size: 8.w),
                          ),
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.all(1.w),
                        child: Text(
                          'Q${image['question_index'] + 1} - O${image['option_index'] + 1}',
                          style: TextStyle(
                            fontSize: 8.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExportButton(int totalImages) {
    return ElevatedButton.icon(
      onPressed: totalImages > 0 && !_isExporting ? _exportGallery : null,
      icon: _isExporting
          ? SizedBox(
              width: 5.w,
              height: 5.w,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            )
          : Icon(Icons.download, size: 5.w),
      label: Text(
        _isExporting ? 'Exporting...' : 'Export Gallery',
        style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.accentLight,
        foregroundColor: Colors.white,
        minimumSize: Size(double.infinity, 6.h),
        disabledBackgroundColor: Colors.grey.shade400,
      ),
    );
  }
}
