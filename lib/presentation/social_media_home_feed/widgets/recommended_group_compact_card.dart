import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart' as app_theme;
import '../../../widgets/custom_image_widget.dart';

/// Compact horizontal card for Recommended Groups carousel on home feed
class RecommendedGroupCompactCard extends StatelessWidget {
  final Map<String, dynamic> group;
  final VoidCallback? onJoin;

  const RecommendedGroupCompactCard({
    super.key,
    required this.group,
    this.onJoin,
  });

  @override
  Widget build(BuildContext context) {
    final name = group['name'] as String? ?? 'Group';
    final imageUrl =
        group['image_url'] as String? ??
        'https://images.pexels.com/photos/3184291/pexels-photo-3184291.jpeg';
    final memberCount = group['member_count'] as int? ?? 0;
    final mutualMembers = group['mutual_members'] as int? ?? 0;

    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, AppRoutes.groupsHub),
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints(minWidth: 36.w),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(20),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              child: SizedBox(
                height: 10.h,
                width: double.infinity,
                child: CustomImageWidget(
                  imageUrl: imageUrl,
                  fit: BoxFit.cover,
                  semanticLabel: '$name group cover',
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(2.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: GoogleFonts.inter(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1A1A2E),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 0.3.h),
                  Row(
                    children: [
                      Icon(Icons.people_rounded,
                          size: 3.w, color: Colors.grey[600]),
                      SizedBox(width: 0.5.w),
                      Text(
                        _formatCount(memberCount),
                        style: GoogleFonts.inter(
                          fontSize: 9.sp,
                          color: Colors.grey[600],
                        ),
                      ),
                      if (mutualMembers > 0) ...[
                        SizedBox(width: 2.w),
                        Text(
                          '$mutualMembers mutual',
                          style: GoogleFonts.inter(
                            fontSize: 9.sp,
                            color: app_theme.AppThemeColors.electricGold,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                  SizedBox(height: 0.8.h),
                  GestureDetector(
                    onTap: onJoin ?? () {},
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 0.6.h),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            app_theme.AppThemeColors.electricGold,
                            const Color(0xFFFF8C00),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          'Join',
                          style: GoogleFonts.inter(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return count.toString();
  }
}
