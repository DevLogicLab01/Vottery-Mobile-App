import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

/// Jolt Action Panel - Right-side vertical action buttons
class JoltActionPanelWidget extends StatelessWidget {
  final int likeCount;
  final int commentCount;
  final int shareCount;
  final bool isLiked;
  final VoidCallback onLike;
  final VoidCallback onComment;
  final VoidCallback onShare;
  final VoidCallback onCreatorTap;
  final String? creatorAvatarUrl;

  const JoltActionPanelWidget({
    super.key,
    required this.likeCount,
    required this.commentCount,
    required this.shareCount,
    required this.isLiked,
    required this.onLike,
    required this.onComment,
    required this.onShare,
    required this.onCreatorTap,
    this.creatorAvatarUrl,
  });

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Creator Avatar
        GestureDetector(
          onTap: onCreatorTap,
          child: Container(
            width: 12.w,
            height: 12.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: ClipOval(
              child: creatorAvatarUrl != null
                  ? CustomImageWidget(
                      imageUrl: creatorAvatarUrl!,
                      fit: BoxFit.cover,
                      semanticLabel: 'Creator avatar',
                    )
                  : Container(
                      color: AppTheme.primaryLight,
                      child: Icon(Icons.person, color: Colors.white, size: 6.w),
                    ),
            ),
          ),
        ),
        SizedBox(height: 3.h),

        // Like Button
        _buildActionButton(
          icon: isLiked ? Icons.favorite : Icons.favorite_border,
          count: likeCount,
          onTap: onLike,
          color: isLiked ? Colors.red : Colors.white,
          vpReward: '+5 VP',
        ),
        SizedBox(height: 3.h),

        // Comment Button
        _buildActionButton(
          icon: Icons.comment_outlined,
          count: commentCount,
          onTap: onComment,
          color: Colors.white,
          vpReward: '+10 VP',
        ),
        SizedBox(height: 3.h),

        // Share Button
        _buildActionButton(
          icon: Icons.share_outlined,
          count: shareCount,
          onTap: onShare,
          color: Colors.white,
          vpReward: '+25 VP',
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required int count,
    required VoidCallback onTap,
    required Color color,
    required String vpReward,
  }) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: EdgeInsets.all(2.w),
            decoration: BoxDecoration(
              color: Colors.black.withAlpha(77),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 7.w),
          ),
        ),
        SizedBox(height: 0.5.h),
        Text(
          _formatCount(count),
          style: GoogleFonts.inter(
            fontSize: 11.sp,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        Text(
          vpReward,
          style: GoogleFonts.inter(
            fontSize: 9.sp,
            fontWeight: FontWeight.w500,
            color: AppTheme.vibrantYellow,
          ),
        ),
      ],
    );
  }
}
