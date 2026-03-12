import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

/// Jolt video card with autoplay preview and engagement metrics
class JoltVideoCardWidget extends StatelessWidget {
  final Map<String, dynamic> jolt;
  final Function(String) onLike;
  final Function(String) onShare;
  final Function(String) onComment;

  const JoltVideoCardWidget({
    super.key,
    required this.jolt,
    required this.onLike,
    required this.onShare,
    required this.onComment,
  });

  @override
  Widget build(BuildContext context) {
    final creator = jolt['creator'] as Map<String, dynamic>?;
    final creatorName =
        creator?['full_name'] as String? ??
        creator?['email'] as String? ??
        'Creator';
    final title = jolt['title'] as String? ?? 'Jolt Video';
    final thumbnailUrl =
        jolt['thumbnail_url'] as String? ??
        'https://images.pexels.com/photos/1550337/pexels-photo-1550337.jpeg';
    final viewCount = jolt['view_count'] as int? ?? 0;
    final likeCount = jolt['like_count'] as int? ?? 0;
    final duration = jolt['duration_seconds'] as int? ?? 0;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Stack(
        children: [
          // Video thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(12.0),
            child: CustomImageWidget(
              imageUrl: thumbnailUrl,
              height: 50.h,
              width: double.infinity,
              fit: BoxFit.cover,
              semanticLabel: 'Jolt video thumbnail showing $title',
            ),
          ),

          // Gradient overlay
          Container(
            height: 50.h,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12.0),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black.withAlpha(179)],
              ),
            ),
          ),

          // Content overlay
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Padding(
              padding: EdgeInsets.all(3.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Creator info
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

                  // Engagement metrics
                  Row(
                    children: [
                      _buildMetric('visibility', _formatCount(viewCount)),
                      SizedBox(width: 4.w),
                      _buildMetric('favorite', _formatCount(likeCount)),
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

          // Action buttons (right side)
          Positioned(
            right: 3.w,
            bottom: 15.h,
            child: Column(
              children: [
                _buildActionButton(
                  'favorite',
                  () => onLike(jolt['id'] as String),
                  '+5 VP',
                ),
                SizedBox(height: 2.h),
                _buildActionButton(
                  'share',
                  () => onShare(jolt['id'] as String),
                  '+10 VP',
                ),
                SizedBox(height: 2.h),
                _buildActionButton(
                  'comment',
                  () => onComment(jolt['id'] as String),
                  '+25 VP',
                ),
              ],
            ),
          ),

          // Play button
          Center(
            child: Container(
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(77),
                shape: BoxShape.circle,
              ),
              child: CustomIconWidget(
                iconName: 'play_arrow',
                size: 10.w,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetric(String iconName, String count) {
    return Row(
      children: [
        CustomIconWidget(
          iconName: iconName,
          size: 4.w,
          color: Colors.white.withAlpha(230),
        ),
        SizedBox(width: 1.w),
        Text(
          count,
          style: GoogleFonts.inter(
            fontSize: 12.sp,
            color: Colors.white.withAlpha(230),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(
    String iconName,
    VoidCallback onTap,
    String vpReward,
  ) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: Container(
            padding: EdgeInsets.all(2.w),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(51),
              shape: BoxShape.circle,
            ),
            child: CustomIconWidget(
              iconName: iconName,
              size: 6.w,
              color: Colors.white,
            ),
          ),
        ),
        SizedBox(height: 0.5.h),
        Text(
          vpReward,
          style: GoogleFonts.inter(
            fontSize: 10.sp,
            fontWeight: FontWeight.w600,
            color: AppTheme.accentLight,
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
