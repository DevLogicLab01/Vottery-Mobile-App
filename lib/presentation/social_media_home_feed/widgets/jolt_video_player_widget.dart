import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import 'package:video_player/video_player.dart';

import '../../../core/app_export.dart';

/// Jolt video player widget with autoplay and engagement metrics
class JoltVideoPlayerWidget extends StatefulWidget {
  final Map<String, dynamic> jolt;
  final Function(String) onLike;
  final Function(String) onShare;
  final Function(String) onComment;

  const JoltVideoPlayerWidget({
    super.key,
    required this.jolt,
    required this.onLike,
    required this.onShare,
    required this.onComment,
  });

  @override
  State<JoltVideoPlayerWidget> createState() => _JoltVideoPlayerWidgetState();
}

class _JoltVideoPlayerWidgetState extends State<JoltVideoPlayerWidget> {
  VideoPlayerController? _controller;
  bool _isPlaying = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    final videoUrl = widget.jolt['video_url'] as String?;
    if (videoUrl == null) return;

    try {
      _controller = VideoPlayerController.networkUrl(Uri.parse(videoUrl));
      await _controller!.initialize();
      setState(() => _isInitialized = true);
      _controller!.setLooping(true);
    } catch (e) {
      debugPrint('Video initialization error: $e');
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    if (_controller == null) return;

    setState(() {
      if (_controller!.value.isPlaying) {
        _controller!.pause();
        _isPlaying = false;
      } else {
        _controller!.play();
        _isPlaying = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final creator = widget.jolt['creator'] as Map<String, dynamic>? ?? {};
    final creatorName = creator['full_name'] as String? ?? 'Creator';
    final title = widget.jolt['title'] as String? ?? 'Jolt Video';
    final thumbnailUrl =
        widget.jolt['thumbnail_url'] as String? ??
        'https://images.pexels.com/photos/1550337/pexels-photo-1550337.jpeg';
    final viewCount = widget.jolt['view_count'] as int? ?? 0;
    final likeCount = widget.jolt['like_count'] as int? ?? 0;
    final duration = widget.jolt['duration_seconds'] as int? ?? 0;

    return Container(
      margin: EdgeInsets.symmetric(vertical: 1.h),
      height: 70.h,
      decoration: BoxDecoration(color: Colors.black),
      child: Stack(
        children: [
          // Video Player or Thumbnail
          if (_isInitialized && _controller != null)
            GestureDetector(
              onTap: _togglePlayPause,
              child: Center(
                child: AspectRatio(
                  aspectRatio: _controller!.value.aspectRatio,
                  child: VideoPlayer(_controller!),
                ),
              ),
            )
          else
            CustomImageWidget(
              imageUrl: thumbnailUrl,
              height: 70.h,
              width: double.infinity,
              fit: BoxFit.cover,
              semanticLabel: 'Jolt video thumbnail',
            ),

          // Gradient Overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black.withAlpha(179)],
              ),
            ),
          ),

          // Play/Pause Button
          if (!_isPlaying)
            Center(
              child: GestureDetector(
                onTap: _togglePlayPause,
                child: Container(
                  padding: EdgeInsets.all(4.w),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(77),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.play_arrow,
                    size: 12.w,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

          // Content Overlay
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Padding(
              padding: EdgeInsets.all(3.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Creator Info
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 4.w,
                        backgroundColor: Colors.white.withAlpha(51),
                        child: Text(
                          creatorName.isNotEmpty
                              ? creatorName[0].toUpperCase()
                              : '',
                          style: GoogleFonts.inter(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      SizedBox(width: 2.w),
                      Text(
                        creatorName,
                        style: GoogleFonts.inter(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 1.h),

                  // Title
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 1.h),

                  // Engagement Metrics
                  Row(
                    children: [
                      Icon(
                        Icons.visibility,
                        size: 4.w,
                        color: Colors.white.withAlpha(230),
                      ),
                      SizedBox(width: 1.w),
                      Text(
                        _formatCount(viewCount),
                        style: GoogleFonts.inter(
                          fontSize: 12.sp,
                          color: Colors.white.withAlpha(230),
                        ),
                      ),
                      SizedBox(width: 4.w),
                      Icon(
                        Icons.favorite,
                        size: 4.w,
                        color: Colors.white.withAlpha(230),
                      ),
                      SizedBox(width: 1.w),
                      Text(
                        _formatCount(likeCount),
                        style: GoogleFonts.inter(
                          fontSize: 12.sp,
                          color: Colors.white.withAlpha(230),
                        ),
                      ),
                      Spacer(),
                      Text(
                        '${duration}s',
                        style: GoogleFonts.inter(
                          fontSize: 12.sp,
                          color: Colors.white.withAlpha(230),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Action Buttons (Right Side)
          Positioned(
            right: 3.w,
            bottom: 20.h,
            child: Column(
              children: [
                _buildActionButton(
                  Icons.favorite_border,
                  () => widget.onLike(widget.jolt['id'] as String),
                  '+5 VP',
                ),
                SizedBox(height: 3.h),
                _buildActionButton(
                  Icons.comment_outlined,
                  () => widget.onComment(widget.jolt['id'] as String),
                  '+25 VP',
                ),
                SizedBox(height: 3.h),
                _buildActionButton(
                  Icons.share_outlined,
                  () => widget.onShare(widget.jolt['id'] as String),
                  '+10 VP',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    IconData icon,
    VoidCallback onTap,
    String vpReward,
  ) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: Container(
            padding: EdgeInsets.all(2.5.w),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(51),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 6.w, color: Colors.white),
          ),
        ),
        SizedBox(height: 0.5.h),
        Text(
          vpReward,
          style: GoogleFonts.inter(
            fontSize: 10.sp,
            fontWeight: FontWeight.w600,
            color: AppTheme.vibrantYellow,
          ),
        ),
      ],
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }
}
