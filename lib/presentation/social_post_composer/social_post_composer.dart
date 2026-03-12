import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/enhanced_analytics_service.dart';
import '../../services/social_service.dart';
import '../../services/supabase_service.dart';
import '../../services/vp_service.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/error_boundary_wrapper.dart';

class SocialPostComposer extends StatefulWidget {
  const SocialPostComposer({super.key});

  @override
  State<SocialPostComposer> createState() => _SocialPostComposerState();
}

class _SocialPostComposerState extends State<SocialPostComposer> {
  final TextEditingController _contentController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  final SocialService _socialService = SocialService.instance;
  final VPService _vpService = VPService.instance;

  String _selectedPostType = 'text';
  List<XFile> _selectedMedia = [];
  List<String> _hashtags = [];
  String _privacyLevel = 'public';
  bool _isPosting = false;
  int _characterCount = 0;
  int _estimatedVP = 5;

  final int _maxCharacters = 500;

  @override
  void initState() {
    super.initState();
    _contentController.addListener(_updateCharacterCount);
    EnhancedAnalyticsService.instance.trackScreenView(
      screenName: 'Social Post Composer',
      screenClass: 'SocialPostComposer',
    );
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  void _updateCharacterCount() {
    setState(() {
      _characterCount = _contentController.text.length;
      _estimatedVP = _calculateEstimatedVP();
    });
  }

  int _calculateEstimatedVP() {
    int baseVP = 5;
    if (_selectedPostType == 'image') baseVP += 3;
    if (_selectedPostType == 'video') baseVP += 5;
    if (_hashtags.isNotEmpty) baseVP += _hashtags.length * 2;
    if (_characterCount > 100) baseVP += 2;
    return baseVP;
  }

  Future<void> _pickMedia() async {
    try {
      if (_selectedPostType == 'image') {
        final List<XFile> images = await _imagePicker.pickMultiImage();
        if (images.isNotEmpty) {
          setState(() {
            _selectedMedia.addAll(images.take(4 - _selectedMedia.length));
          });
        }
      } else if (_selectedPostType == 'video') {
        final XFile? video = await _imagePicker.pickVideo(
          source: ImageSource.gallery,
        );
        if (video != null) {
          setState(() {
            _selectedMedia = [video];
          });
        }
      }
    } catch (e) {
      debugPrint('Pick media error: $e');
    }
  }

  void _removeMedia(int index) {
    setState(() {
      _selectedMedia.removeAt(index);
    });
  }

  void _extractHashtags() {
    final text = _contentController.text;
    final hashtagRegex = RegExp(r'#\w+');
    final matches = hashtagRegex.allMatches(text);
    setState(() {
      _hashtags = matches.map((m) => m.group(0)!).toList();
    });
  }

  Future<void> _handlePost() async {
    if (_contentController.text.trim().isEmpty && _selectedMedia.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please add content or media to your post'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isPosting = true);

    try {
      _extractHashtags();

      // Upload media if any
      List<String> mediaUrls = [];
      if (_selectedMedia.isNotEmpty) {
        for (final media in _selectedMedia) {
          final fileName =
              '${DateTime.now().millisecondsSinceEpoch}_${media.name}';
          final bytes = await media.readAsBytes();

          final uploadPath = await SupabaseService.instance.client.storage
              .from('social-media')
              .uploadBinary('posts/$fileName', bytes);

          final publicUrl = SupabaseService.instance.client.storage
              .from('social-media')
              .getPublicUrl('posts/$fileName');

          mediaUrls.add(publicUrl);
        }
      }

      // Create post
      await SupabaseService.instance.client.from('social_posts').insert({
        'author_id': SupabaseService.instance.client.auth.currentUser!.id,
        'post_type': _selectedPostType,
        'content': _contentController.text,
        'media_urls': mediaUrls,
        'hashtags': _hashtags,
        'privacy_level': _privacyLevel,
        'status': 'published',
      });

      // Award VP
      await _vpService.awardSocialVP('post_creation', 'new_post');

      // Track analytics
      await EnhancedAnalyticsService.instance.trackPostCreation(
        postType: _selectedPostType,
        hasMedia: mediaUrls.isNotEmpty,
        hashtagCount: _hashtags.length,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Post published! +$_estimatedVP VP earned'),
            backgroundColor: AppTheme.accentLight,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      debugPrint('Post creation error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create post. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPosting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ErrorBoundaryWrapper(
      screenName: 'SocialPostComposer',
      child: Scaffold(
        backgroundColor: AppTheme.backgroundLight,
        appBar: CustomAppBar(
          leading: Padding(
            padding: EdgeInsets.only(left: 4.w),
            child: IconButton(
              icon: CustomIconWidget(
                iconName: 'close',
                size: 6.w,
                color: AppTheme.textPrimaryLight,
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          title: 'Create Post',
          actions: [
            Padding(
              padding: EdgeInsets.only(right: 4.w),
              child: TextButton(
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
            ),
          ],
        ),
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Post Type Selector
              Container(
                padding: EdgeInsets.all(4.w),
                color: Colors.white,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Post Type',
                      style: GoogleFonts.inter(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimaryLight,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Row(
                      children: [
                        _buildPostTypeChip('text', 'Text', Icons.text_fields),
                        SizedBox(width: 2.w),
                        _buildPostTypeChip('image', 'Image', Icons.image),
                        SizedBox(width: 2.w),
                        _buildPostTypeChip('video', 'Video', Icons.videocam),
                      ],
                    ),
                  ],
                ),
              ),

              SizedBox(height: 1.h),

              // Content Input
              Container(
                padding: EdgeInsets.all(4.w),
                color: Colors.white,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _contentController,
                      maxLines: 8,
                      maxLength: _maxCharacters,
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '$_characterCount / $_maxCharacters',
                          style: GoogleFonts.inter(
                            fontSize: 11.sp,
                            color: _characterCount > _maxCharacters * 0.9
                                ? Colors.red
                                : AppTheme.textSecondaryLight,
                          ),
                        ),
                        if (_hashtags.isNotEmpty)
                          Text(
                            '${_hashtags.length} hashtags',
                            style: GoogleFonts.inter(
                              fontSize: 11.sp,
                              color: AppTheme.primaryLight,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              SizedBox(height: 1.h),

              // Media Upload Section
              if (_selectedPostType != 'text')
                Container(
                  padding: EdgeInsets.all(4.w),
                  color: Colors.white,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Media',
                            style: GoogleFonts.inter(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimaryLight,
                            ),
                          ),
                          TextButton.icon(
                            onPressed: _pickMedia,
                            icon: Icon(Icons.add_photo_alternate, size: 5.w),
                            label: Text('Add'),
                          ),
                        ],
                      ),
                      if (_selectedMedia.isNotEmpty) SizedBox(height: 2.h),
                      if (_selectedMedia.isNotEmpty)
                        SizedBox(
                          height: 20.h,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _selectedMedia.length,
                            itemBuilder: (context, index) {
                              return Container(
                                width: 30.w,
                                margin: EdgeInsets.only(right: 2.w),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8.0),
                                  color: AppTheme.borderLight,
                                ),
                                child: Stack(
                                  children: [
                                    if (!kIsWeb)
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(
                                          8.0,
                                        ),
                                        child: Image.file(
                                          File(_selectedMedia[index].path),
                                          width: 30.w,
                                          height: 20.h,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    Positioned(
                                      top: 1.w,
                                      right: 1.w,
                                      child: GestureDetector(
                                        onTap: () => _removeMedia(index),
                                        child: Container(
                                          padding: EdgeInsets.all(1.w),
                                          decoration: BoxDecoration(
                                            color: Colors.black54,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            Icons.close,
                                            color: Colors.white,
                                            size: 4.w,
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
                    ],
                  ),
                ),

              SizedBox(height: 1.h),

              // Privacy Controls
              Container(
                padding: EdgeInsets.all(4.w),
                color: Colors.white,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Privacy',
                      style: GoogleFonts.inter(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimaryLight,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Row(
                      children: [
                        _buildPrivacyChip('public', 'Public', Icons.public),
                        SizedBox(width: 2.w),
                        _buildPrivacyChip('friends', 'Friends', Icons.people),
                        SizedBox(width: 2.w),
                        _buildPrivacyChip('private', 'Private', Icons.lock),
                      ],
                    ),
                  ],
                ),
              ),

              SizedBox(height: 1.h),

              // VP Earning Preview
              Container(
                padding: EdgeInsets.all(4.w),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.primaryLight, AppTheme.accentLight],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.stars, color: Colors.white, size: 6.w),
                    SizedBox(width: 3.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Estimated VP Reward',
                            style: GoogleFonts.inter(
                              fontSize: 12.sp,
                              color: Colors.white70,
                            ),
                          ),
                          Text(
                            '+$_estimatedVP VP',
                            style: GoogleFonts.inter(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPostTypeChip(String type, String label, IconData icon) {
    final isSelected = _selectedPostType == type;
    return GestureDetector(
      onTap: () => setState(() => _selectedPostType = type),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryLight : AppTheme.borderLight,
          borderRadius: BorderRadius.circular(20.0),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 4.w,
              color: isSelected ? Colors.white : AppTheme.textSecondaryLight,
            ),
            SizedBox(width: 1.w),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12.sp,
                color: isSelected ? Colors.white : AppTheme.textSecondaryLight,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrivacyChip(String level, String label, IconData icon) {
    final isSelected = _privacyLevel == level;
    return GestureDetector(
      onTap: () => setState(() => _privacyLevel = level),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.accentLight : AppTheme.borderLight,
          borderRadius: BorderRadius.circular(20.0),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 4.w,
              color: isSelected ? Colors.white : AppTheme.textSecondaryLight,
            ),
            SizedBox(width: 1.w),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12.sp,
                color: isSelected ? Colors.white : AppTheme.textSecondaryLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
