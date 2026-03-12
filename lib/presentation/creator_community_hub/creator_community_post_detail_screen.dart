import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../theme/app_theme.dart';

/// Full post detail view for Creator Community Hub
class CreatorCommunityPostDetailScreen extends StatelessWidget {
  const CreatorCommunityPostDetailScreen({
    super.key,
    required this.post,
    required this.postTypeLabel,
    required this.icon,
  });

  final Map<String, dynamic> post;
  final String postTypeLabel;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final author = post['author'] as Map<String, dynamic>?;
    final username = author?['username'] as String? ?? 'Creator';
    final title = post['title'] as String? ?? 'Untitled';
    final body = post['body'] as String? ?? '';
    final tags = post['tags'];
    final likesCount = post['likes_count'] as int? ?? 0;
    final createdAt = post['created_at'];

    String timeAgo = '';
    if (createdAt != null) {
      try {
        final dt = DateTime.parse(createdAt.toString());
        final diff = DateTime.now().difference(dt);
        if (diff.inMinutes < 60) {
          timeAgo = '${diff.inMinutes}m ago';
        } else if (diff.inHours < 24) {
          timeAgo = '${diff.inHours}h ago';
        } else {
          timeAgo = '${diff.inDays}d ago';
        }
      } catch (_) {
        timeAgo = '';
      }
    }

    List<String> tagList = [];
    if (tags is List) {
      tagList = tags.map((e) => e.toString()).toList();
    } else if (tags is String && tags.isNotEmpty) {
      tagList = tags.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
          color: AppTheme.textPrimaryLight,
        ),
        title: Text(
          postTypeLabel,
          style: GoogleFonts.inter(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimaryLight,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppTheme.vibrantYellow.withAlpha(80),
                  radius: 24,
                  child: Icon(icon, color: AppTheme.primaryLight, size: 28),
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '@$username',
                        style: GoogleFonts.inter(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimaryLight,
                        ),
                      ),
                      if (timeAgo.isNotEmpty)
                        Text(
                          timeAgo,
                          style: GoogleFonts.inter(
                            fontSize: 11.sp,
                            color: AppTheme.textSecondaryLight,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 2.h),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 18.sp,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimaryLight,
              ),
            ),
            SizedBox(height: 1.5.h),
            Text(
              body,
              style: GoogleFonts.inter(
                fontSize: 14.sp,
                height: 1.5,
                color: AppTheme.textPrimaryLight,
              ),
            ),
            if (tagList.isNotEmpty) ...[
              SizedBox(height: 2.h),
              Wrap(
                spacing: 2.w,
                runSpacing: 1.h,
                children: tagList.map((tag) {
                  return Chip(
                    label: Text(
                      tag,
                      style: GoogleFonts.inter(fontSize: 11.sp),
                    ),
                    backgroundColor: AppTheme.vibrantYellow.withAlpha(60),
                    padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                  );
                }).toList(),
              ),
            ],
            SizedBox(height: 2.h),
            Row(
              children: [
                Icon(Icons.favorite_border, size: 20, color: AppTheme.textSecondaryLight),
                SizedBox(width: 1.w),
                Text(
                  '$likesCount likes',
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    color: AppTheme.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
