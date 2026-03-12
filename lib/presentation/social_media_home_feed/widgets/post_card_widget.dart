import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class PostCardWidget extends StatefulWidget {
  final Map<String, dynamic> post;
  final Function(String) onLike;
  final Function(String) onComment;
  final Function(String) onShare;

  const PostCardWidget({
    super.key,
    required this.post,
    required this.onLike,
    required this.onComment,
    required this.onShare,
  });

  @override
  State<PostCardWidget> createState() => _PostCardWidgetState();
}

class _PostCardWidgetState extends State<PostCardWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _likeAnimationController;
  late Animation<double> _likeAnimation;
  bool _isLiked = false;

  @override
  void initState() {
    super.initState();
    _likeAnimationController = AnimationController(
      duration: Duration(milliseconds: 400),
      vsync: this,
    );
    _likeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _likeAnimationController,
        curve: Curves.elasticOut,
      ),
    );
  }

  @override
  void dispose() {
    _likeAnimationController.dispose();
    super.dispose();
  }

  void _handleDoubleTap() {
    if (!_isLiked) {
      setState(() => _isLiked = true);
      _likeAnimationController.forward().then((_) {
        _likeAnimationController.reverse();
      });
      widget.onLike(widget.post['id'] as String);
    }
  }

  @override
  Widget build(BuildContext context) {
    final author = widget.post['author'] as Map<String, dynamic>? ?? {};
    final authorName = author['full_name'] as String? ?? 'User';
    final content = widget.post['content'] as String? ?? '';
    final imageUrl = widget.post['image_url'] as String?;
    final likeCount = widget.post['like_count'] as int? ?? 0;
    final commentCount = widget.post['comment_count'] as int? ?? 0;
    final shareCount = widget.post['share_count'] as int? ?? 0;
    final createdAt = widget.post['created_at'] as String?;

    return Container(
      margin: EdgeInsets.symmetric(vertical: 1.h),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: AppTheme.borderLight, width: 1),
          bottom: BorderSide(color: AppTheme.borderLight, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Post Header
          Padding(
            padding: EdgeInsets.all(3.w),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 5.w,
                  backgroundColor: AppTheme.primaryLight.withAlpha(26),
                  child: Text(
                    authorName[0].toUpperCase(),
                    style: GoogleFonts.inter(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryLight,
                    ),
                  ),
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        authorName,
                        style: GoogleFonts.inter(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimaryLight,
                        ),
                      ),
                      Text(
                        _formatTime(createdAt),
                        style: GoogleFonts.inter(
                          fontSize: 11.sp,
                          color: AppTheme.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.more_horiz,
                    size: 5.w,
                    color: AppTheme.textSecondaryLight,
                  ),
                  onPressed: () {},
                ),
              ],
            ),
          ),

          // Post Content
          if (content.isNotEmpty)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
              child: Text(
                content,
                style: GoogleFonts.inter(
                  fontSize: 13.sp,
                  color: AppTheme.textPrimaryLight,
                ),
              ),
            ),

          // Post Image with Double-Tap to Like
          if (imageUrl != null)
            GestureDetector(
              onDoubleTap: _handleDoubleTap,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomImageWidget(
                    imageUrl: imageUrl,
                    width: double.infinity,
                    height: 50.h,
                    fit: BoxFit.cover,
                    semanticLabel: 'Post image',
                  ),
                  ScaleTransition(
                    scale: _likeAnimation,
                    child: Icon(
                      Icons.favorite,
                      size: 20.w,
                      color: Colors.white.withAlpha(230),
                    ),
                  ),
                ],
              ),
            ),

          // Engagement Stats
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
            child: Row(
              children: [
                Text(
                  '$likeCount likes',
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimaryLight,
                  ),
                ),
                SizedBox(width: 3.w),
                Text(
                  '$commentCount comments',
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    color: AppTheme.textSecondaryLight,
                  ),
                ),
                SizedBox(width: 3.w),
                Text(
                  '$shareCount shares',
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    color: AppTheme.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),

          Divider(height: 1, color: AppTheme.borderLight),

          // Action Buttons
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildActionButton(
                  icon: _isLiked ? Icons.favorite : Icons.favorite_border,
                  label: 'Like',
                  color: _isLiked ? Colors.red : AppTheme.textSecondaryLight,
                  onTap: () {
                    setState(() => _isLiked = !_isLiked);
                    widget.onLike(widget.post['id'] as String);
                  },
                ),
                _buildActionButton(
                  icon: Icons.comment_outlined,
                  label: 'Comment',
                  color: AppTheme.textSecondaryLight,
                  onTap: () => widget.onComment(widget.post['id'] as String),
                ),
                _buildActionButton(
                  icon: Icons.share_outlined,
                  label: 'Share',
                  color: AppTheme.textSecondaryLight,
                  onTap: () => widget.onShare(widget.post['id'] as String),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
        child: Row(
          children: [
            Icon(icon, size: 5.w, color: color),
            SizedBox(width: 2.w),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(String? timestamp) {
    if (timestamp == null) return '';
    try {
      final dateTime = DateTime.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inMinutes < 60) {
        return '${difference.inMinutes}m';
      } else if (difference.inHours < 24) {
        return '${difference.inHours}h';
      } else {
        return '${difference.inDays}d';
      }
    } catch (e) {
      return '';
    }
  }
}
