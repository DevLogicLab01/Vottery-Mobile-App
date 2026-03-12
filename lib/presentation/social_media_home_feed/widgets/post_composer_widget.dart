import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

/// Post composer widget for creating new posts with media upload
class PostComposerWidget extends StatefulWidget {
  final Function(String content, List<String> mediaUrls) onPost;

  const PostComposerWidget({super.key, required this.onPost});

  @override
  State<PostComposerWidget> createState() => _PostComposerWidgetState();
}

class _PostComposerWidgetState extends State<PostComposerWidget> {
  final TextEditingController _contentController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  final List<String> _selectedMediaUrls = [];
  bool _isPosting = false;

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
      );
      if (image != null) {
        setState(() {
          _selectedMediaUrls.add(image.path);
        });
      }
    } catch (e) {
      debugPrint('Pick image error: $e');
    }
  }

  Future<void> _handlePost() async {
    if (_contentController.text.trim().isEmpty) return;

    setState(() => _isPosting = true);
    await widget.onPost(_contentController.text, _selectedMediaUrls);
    setState(() => _isPosting = false);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: EdgeInsets.all(4.w),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.close, size: 6.w),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Text(
                      'Create Post',
                      style: GoogleFonts.inter(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  TextButton(
                    onPressed: _isPosting ? null : _handlePost,
                    child: _isPosting
                        ? SizedBox(
                            width: 5.w,
                            height: 5.w,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppTheme.primaryLight,
                            ),
                          )
                        : Text(
                            'Post',
                            style: GoogleFonts.inter(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primaryLight,
                            ),
                          ),
                  ),
                ],
              ),
            ),

            Divider(height: 1),

            // Content Input
            Padding(
              padding: EdgeInsets.all(4.w),
              child: TextField(
                controller: _contentController,
                maxLines: 6,
                decoration: InputDecoration(
                  hintText: "What's on your mind?",
                  border: InputBorder.none,
                  hintStyle: GoogleFonts.inter(
                    fontSize: 14.sp,
                    color: AppTheme.textSecondaryLight,
                  ),
                ),
                style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  color: AppTheme.textPrimaryLight,
                ),
              ),
            ),

            // Media Preview
            if (_selectedMediaUrls.isNotEmpty)
              Container(
                height: 20.h,
                margin: EdgeInsets.symmetric(horizontal: 4.w),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _selectedMediaUrls.length,
                  itemBuilder: (context, index) {
                    return Container(
                      width: 30.w,
                      margin: EdgeInsets.only(right: 2.w),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8.0),
                        image: DecorationImage(
                          image: NetworkImage(_selectedMediaUrls[index]),
                          fit: BoxFit.cover,
                        ),
                      ),
                      child: Stack(
                        children: [
                          Positioned(
                            top: 1.w,
                            right: 1.w,
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedMediaUrls.removeAt(index);
                                });
                              },
                              child: Container(
                                padding: EdgeInsets.all(1.w),
                                decoration: BoxDecoration(
                                  color: Colors.black.withAlpha(128),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.close,
                                  size: 4.w,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

            SizedBox(height: 2.h),

            // Action Buttons
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
              child: Row(
                children: [
                  _buildActionButton(
                    icon: Icons.photo_library,
                    label: 'Photo',
                    onTap: _pickImage,
                  ),
                  SizedBox(width: 3.w),
                  _buildActionButton(
                    icon: Icons.videocam,
                    label: 'Video',
                    onTap: () {},
                  ),
                  SizedBox(width: 3.w),
                  _buildActionButton(
                    icon: Icons.how_to_vote,
                    label: 'Election',
                    onTap: () {},
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 1.5.h),
          decoration: BoxDecoration(
            color: AppTheme.surfaceLight,
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 5.w, color: AppTheme.primaryLight),
              SizedBox(width: 2.w),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimaryLight,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
