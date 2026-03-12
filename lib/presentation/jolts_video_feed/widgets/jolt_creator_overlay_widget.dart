import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

/// Jolt Creator Overlay - Bottom overlay with creator info and description
class JoltCreatorOverlayWidget extends StatelessWidget {
  final Map<String, dynamic> jolt;
  final VoidCallback onFollowTap;

  const JoltCreatorOverlayWidget({
    super.key,
    required this.jolt,
    required this.onFollowTap,
  });

  @override
  Widget build(BuildContext context) {
    final creator = jolt['creator'] as Map<String, dynamic>? ?? {};
    final creatorName =
        creator['full_name'] as String? ??
        creator['username'] as String? ??
        'Creator';
    final title = jolt['title'] as String? ?? '';
    final description = jolt['description'] as String? ?? '';

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Colors.black.withAlpha(204)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Creator Name with Follow Button
          Row(
            children: [
              Text(
                '@$creatorName',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: 3.w),
              GestureDetector(
                onTap: onFollowTap,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 4.w,
                    vertical: 0.5.h,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryLight,
                    borderRadius: BorderRadius.circular(4.0),
                  ),
                  child: Text(
                    'Follow',
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),

          // Video Title
          if (title.isNotEmpty)
            Text(
              title,
              style: TextStyle(
                fontSize: 15.sp,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          if (title.isNotEmpty) SizedBox(height: 1.h),

          // Description with Hashtags
          if (description.isNotEmpty)
            Text(
              description,
              style: TextStyle(
                fontSize: 13.sp,
                color: Colors.white.withAlpha(230),
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          SizedBox(height: 1.h),

          // Trending Hashtags
          Wrap(
            spacing: 2.w,
            runSpacing: 0.5.h,
            children: [
              _buildHashtag('#Vottery'),
              _buildHashtag('#Jolts'),
              _buildHashtag('#Trending'),
            ],
          ),
          SizedBox(height: 1.h),

          // Background Music Attribution
          Row(
            children: [
              Icon(Icons.music_note, color: Colors.white, size: 4.w),
              SizedBox(width: 2.w),
              Expanded(
                child: Text(
                  'Original Audio',
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: Colors.white.withAlpha(204),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHashtag(String hashtag) {
    return Text(
      hashtag,
      style: TextStyle(
        fontSize: 12.sp,
        fontWeight: FontWeight.w600,
        color: AppTheme.vibrantYellow,
      ),
    );
  }
}
