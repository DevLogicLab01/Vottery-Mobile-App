import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart' as theme;
import '../../../widgets/custom_image_widget.dart';

/// Enhanced Jolt Card Widget
/// Video thumbnail with play icon, creator avatar, engagement metrics, trending indicator
class JoltCardWidget extends StatefulWidget {
  final Map<String, dynamic> jolt;
  final VoidCallback onTap;

  const JoltCardWidget({super.key, required this.jolt, required this.onTap});

  @override
  State<JoltCardWidget> createState() => _JoltCardWidgetState();
}

class _JoltCardWidgetState extends State<JoltCardWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _playController;
  final bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _playController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _playController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final jolt = widget.jolt;
    final creator = jolt['creator'] as Map<String, dynamic>?;
    final thumbnailUrl =
        jolt['thumbnail_url'] as String? ??
        'https://images.pexels.com/photos/1181671/pexels-photo-1181671.jpeg';
    final title = jolt['title'] as String? ?? 'Trending Jolt';
    final views = jolt['view_count'] as int? ?? 0;
    final likes = jolt['like_count'] as int? ?? 0;
    final isTrending = (jolt['trending_score'] as num? ?? 0) > 50;
    final hashtags =
        (jolt['hashtags'] as List?)?.cast<String>() ?? ['#trending'];

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20.0),
          color: Colors.black,
        ),
        child: Stack(
          children: [
            // Thumbnail
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20.0),
                child: CustomImageWidget(
                  imageUrl: thumbnailUrl,
                  fit: BoxFit.cover,
                  semanticLabel: 'Jolt video thumbnail: $title',
                ),
              ),
            ),
            // Gradient overlay
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20.0),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withAlpha(100),
                      Colors.transparent,
                      Colors.black.withAlpha(200),
                    ],
                    stops: const [0.0, 0.4, 1.0],
                  ),
                ),
              ),
            ),
            // Top row: trending badge + creator avatar
            Positioned(
              top: 2.h,
              left: 3.w,
              right: 3.w,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (isTrending)
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 2.5.w,
                        vertical: 0.5.h,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF4757),
                        borderRadius: BorderRadius.circular(20.0),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF4757).withAlpha(100),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('🔥', style: TextStyle(fontSize: 9.sp)),
                          SizedBox(width: 1.w),
                          Text(
                            'TRENDING',
                            style: GoogleFonts.inter(
                              fontSize: 8.sp,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    const SizedBox.shrink(),
                  // Creator avatar
                  Stack(
                    children: [
                      Container(
                        width: 9.w,
                        height: 9.w,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: theme.AppThemeColors.electricGold,
                            width: 2,
                          ),
                        ),
                        child: ClipOval(
                          child: creator?['avatar'] != null
                              ? CustomImageWidget(
                                  imageUrl: creator!['avatar'] as String,
                                  fit: BoxFit.cover,
                                  semanticLabel: 'Creator avatar',
                                )
                              : Container(
                                  color: theme.AppThemeColors.electricGold
                                      .withAlpha(80),
                                  child: Icon(
                                    Icons.person,
                                    color: Colors.white,
                                    size: 4.w,
                                  ),
                                ),
                        ),
                      ),
                      if (creator?['verified'] == true)
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            width: 3.5.w,
                            height: 3.5.w,
                            decoration: const BoxDecoration(
                              color: Color(0xFF1DA1F2),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.verified,
                              color: Colors.white,
                              size: 2.5.w,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            // Center play button
            Center(
              child: AnimatedBuilder(
                animation: _playController,
                builder: (context, child) {
                  return Container(
                    width: 14.w,
                    height: 14.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withAlpha(
                        (180 + (_playController.value * 50)).toInt(),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withAlpha(
                            (60 + (_playController.value * 60).toInt()),
                          ),
                          blurRadius: 16,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.play_arrow_rounded,
                      color: Colors.black,
                      size: 8.w,
                    ),
                  );
                },
              ),
            ),
            // Bottom: title, hashtags, metrics
            Positioned(
              bottom: 2.h,
              left: 3.w,
              right: 3.w,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      shadows: [Shadow(color: Colors.black, blurRadius: 4)],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 0.5.h),
                  Wrap(
                    spacing: 1.w,
                    children: hashtags
                        .take(3)
                        .map(
                          (tag) => Text(
                            tag.startsWith('#') ? tag : '#$tag',
                            style: GoogleFonts.inter(
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w600,
                              color: theme.AppThemeColors.electricGold,
                            ),
                          ),
                        )
                        .toList(),
                  ),
                  SizedBox(height: 0.8.h),
                  Row(
                    children: [
                      _buildMetric(
                        Icons.visibility_rounded,
                        _formatCount(views),
                      ),
                      SizedBox(width: 3.w),
                      _buildMetric(Icons.favorite_rounded, _formatCount(likes)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetric(IconData icon, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white.withAlpha(200), size: 3.5.w),
        SizedBox(width: 0.8.w),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 10.sp,
            fontWeight: FontWeight.w600,
            color: Colors.white.withAlpha(220),
          ),
        ),
      ],
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return count.toString();
  }
}
