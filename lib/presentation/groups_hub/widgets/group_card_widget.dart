import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

/// Group Card Widget - Display group information with swipe actions
class GroupCardWidget extends StatelessWidget {
  final Map<String, dynamic> group;
  final bool isMember;
  final VoidCallback onTap;
  final VoidCallback? onLeave;
  final VoidCallback? onJoin;

  const GroupCardWidget({
    super.key,
    required this.group,
    required this.isMember,
    required this.onTap,
    this.onLeave,
    this.onJoin,
  });

  @override
  Widget build(BuildContext context) {
    final name = group['name'] as String? ?? 'Group';
    final description = group['description'] as String? ?? '';
    final memberCount = group['member_count'] as int? ?? 0;
    final isPublic = group['is_public'] as bool? ?? true;
    final topic = group['topic'] as String? ?? 'General';
    final coverImageUrl =
        group['cover_image_url'] as String? ??
        'https://images.pexels.com/photos/3184291/pexels-photo-3184291.jpeg';

    final card = GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.0),
          boxShadow: [
            BoxShadow(
              color: AppTheme.shadowLight,
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover Image
            ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(12.0)),
              child: CustomImageWidget(
                imageUrl: coverImageUrl,
                height: 20.h,
                width: double.infinity,
                fit: BoxFit.cover,
                semanticLabel: 'Group cover image',
              ),
            ),

            Padding(
              padding: EdgeInsets.all(4.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Group Name and Privacy Badge
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: GoogleFonts.inter(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimaryLight,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 2.w,
                          vertical: 0.5.h,
                        ),
                        decoration: BoxDecoration(
                          color: isPublic
                              ? AppTheme.accentLight.withAlpha(51)
                              : AppTheme.warningLight.withAlpha(51),
                          borderRadius: BorderRadius.circular(4.0),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isPublic ? Icons.public : Icons.lock_outline,
                              size: 3.w,
                              color: isPublic
                                  ? AppTheme.accentLight
                                  : AppTheme.warningLight,
                            ),
                            SizedBox(width: 1.w),
                            Text(
                              isPublic ? 'Public' : 'Private',
                              style: GoogleFonts.inter(
                                fontSize: 10.sp,
                                fontWeight: FontWeight.w600,
                                color: isPublic
                                    ? AppTheme.accentLight
                                    : AppTheme.warningLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 1.h),

                  // Topic Badge
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 2.w,
                      vertical: 0.5.h,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryLight.withAlpha(26),
                      borderRadius: BorderRadius.circular(4.0),
                    ),
                    child: Text(
                      topic,
                      style: GoogleFonts.inter(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryLight,
                      ),
                    ),
                  ),
                  SizedBox(height: 1.h),

                  // Description
                  if (description.isNotEmpty)
                    Text(
                      description,
                      style: GoogleFonts.inter(
                        fontSize: 13.sp,
                        color: AppTheme.textSecondaryLight,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  SizedBox(height: 1.5.h),

                  // Member Count and Activity
                  Row(
                    children: [
                      Icon(
                        Icons.people_outline,
                        size: 4.w,
                        color: AppTheme.textSecondaryLight,
                      ),
                      SizedBox(width: 1.w),
                      Text(
                        '$memberCount members',
                        style: GoogleFonts.inter(
                          fontSize: 12.sp,
                          color: AppTheme.textSecondaryLight,
                        ),
                      ),
                      Spacer(),
                      if (isMember)
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 2.w,
                            vertical: 0.5.h,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.accentLight.withAlpha(26),
                            borderRadius: BorderRadius.circular(4.0),
                          ),
                          child: Text(
                            'Joined',
                            style: GoogleFonts.inter(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.accentLight,
                            ),
                          ),
                        )
                      else
                        ElevatedButton(
                          onPressed: onJoin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryLight,
                            padding: EdgeInsets.symmetric(
                              horizontal: 4.w,
                              vertical: 0.8.h,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20.0),
                            ),
                          ),
                          child: Text(
                            'Join',
                            style: GoogleFonts.inter(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    if (isMember && onLeave != null) {
      return Slidable(
        key: ValueKey(group['id']),
        endActionPane: ActionPane(
          motion: ScrollMotion(),
          children: [
            SlidableAction(
              onPressed: (context) => onLeave?.call(),
              backgroundColor: AppTheme.errorLight,
              foregroundColor: Colors.white,
              icon: Icons.exit_to_app,
              label: 'Leave',
              borderRadius: BorderRadius.circular(12.0),
            ),
          ],
        ),
        child: card,
      );
    }

    return card;
  }
}
