import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart' as app_theme;
import '../../../widgets/custom_image_widget.dart';

/// Enhanced Recommended Group Card Widget
/// Cover image, member count, activity, mutual members, elections, topics, trending badge
class RecommendedGroupCardWidget extends StatelessWidget {
  final Map<String, dynamic> group;
  final VoidCallback? onSwipeRight;
  final VoidCallback? onSwipeLeft;

  const RecommendedGroupCardWidget({
    super.key,
    required this.group,
    this.onSwipeRight,
    this.onSwipeLeft,
  });

  @override
  Widget build(BuildContext context) {
    final name = group['name'] as String? ?? 'Group';
    final description = group['description'] as String? ?? '';
    final imageUrl =
        group['image_url'] as String? ??
        'https://images.pexels.com/photos/3184291/pexels-photo-3184291.jpeg';
    final memberCount = group['member_count'] as int? ?? 0;
    final isActive = group['is_active'] as bool? ?? true;
    final mutualMembers = group['mutual_members'] as int? ?? 0;
    final activeElections = group['active_elections_count'] as int? ?? 0;
    final isTrending = group['is_trending'] as bool? ?? false;
    final topics = (group['top_topics'] as List?)?.cast<String>() ?? [];

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20.0),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cover image
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20.0),
                ),
                child: SizedBox(
                  height: 20.h,
                  width: double.infinity,
                  child: CustomImageWidget(
                    imageUrl: imageUrl,
                    fit: BoxFit.cover,
                    semanticLabel: '$name group cover image',
                  ),
                ),
              ),
              // Trending badge
              if (isTrending)
                Positioned(
                  top: 1.5.h,
                  left: 3.w,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 2.w,
                      vertical: 0.4.h,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF4757),
                      borderRadius: BorderRadius.circular(20.0),
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
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              // Activity status
              Positioned(
                top: 1.5.h,
                right: 3.w,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 2.w,
                    vertical: 0.4.h,
                  ),
                  decoration: BoxDecoration(
                    color: isActive
                        ? const Color(0xFF2ED573).withAlpha(220)
                        : Colors.grey.withAlpha(180),
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 1.5.w,
                        height: 1.5.w,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: 1.w),
                      Text(
                        isActive ? 'Active' : 'Quiet',
                        style: GoogleFonts.inter(
                          fontSize: 8.sp,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          // Content
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(3.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: GoogleFonts.inter(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF1A1A2E),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 0.3.h),
                  Text(
                    description,
                    style: GoogleFonts.inter(
                      fontSize: 11.sp,
                      color: Colors.grey[600],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 1.h),
                  // Stats row
                  Row(
                    children: [
                      _buildStat(
                        Icons.people_rounded,
                        '${_formatCount(memberCount)} members',
                      ),
                      SizedBox(width: 3.w),
                      if (mutualMembers > 0)
                        _buildStat(
                          Icons.group_rounded,
                          '$mutualMembers mutual',
                          color: app_theme.AppThemeColors.electricGold,
                        ),
                      if (activeElections > 0) ...[
                        SizedBox(width: 3.w),
                        _buildStat(
                          Icons.how_to_vote_rounded,
                          '$activeElections elections',
                          color: const Color(0xFF7B2FF7),
                        ),
                      ],
                    ],
                  ),
                  if (topics.isNotEmpty) ...[
                    SizedBox(height: 0.8.h),
                    Wrap(
                      spacing: 1.w,
                      runSpacing: 0.5.h,
                      children: topics
                          .take(3)
                          .map(
                            (t) => Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 2.w,
                                vertical: 0.3.h,
                              ),
                              decoration: BoxDecoration(
                                color: app_theme.AppThemeColors.electricGold
                                    .withAlpha(30),
                                borderRadius: BorderRadius.circular(10.0),
                                border: Border.all(
                                  color: app_theme.AppThemeColors.electricGold
                                      .withAlpha(80),
                                ),
                              ),
                              child: Text(
                                t,
                                style: GoogleFonts.inter(
                                  fontSize: 9.sp,
                                  fontWeight: FontWeight.w600,
                                  color: app_theme.AppThemeColors.electricGold,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                  const Spacer(),
                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: onSwipeLeft,
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 1.2.h),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                            child: Center(
                              child: Text(
                                'Skip',
                                style: GoogleFonts.inter(
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 2.w),
                      Expanded(
                        flex: 2,
                        child: GestureDetector(
                          onTap: onSwipeRight,
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 1.2.h),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  app_theme.AppThemeColors.electricGold,
                                  const Color(0xFFFF8C00),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12.0),
                              boxShadow: [
                                BoxShadow(
                                  color: app_theme.AppThemeColors.electricGold
                                      .withAlpha(80),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                '👥 Join Group',
                                style: GoogleFonts.inter(
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStat(IconData icon, String label, {Color? color}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color ?? Colors.grey[500], size: 3.5.w),
        SizedBox(width: 0.8.w),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 9.sp,
            fontWeight: FontWeight.w600,
            color: color ?? Colors.grey[600],
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
