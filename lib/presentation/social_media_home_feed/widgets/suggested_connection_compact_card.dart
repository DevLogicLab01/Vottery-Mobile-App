import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

/// Compact horizontal card for Suggested Connections carousel on home feed
class SuggestedConnectionCompactCard extends StatelessWidget {
  final Map<String, dynamic> user;
  final VoidCallback onFollow;
  final VoidCallback onAddFriend;

  const SuggestedConnectionCompactCard({
    super.key,
    required this.user,
    required this.onFollow,
    required this.onAddFriend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28.w,
      margin: EdgeInsets.only(right: 3.w),
      padding: EdgeInsets.all(2.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(25),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 8.w,
            backgroundImage: NetworkImage(
              user['avatar_url'] as String? ??
                  'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde',
            ),
          ),
          SizedBox(height: 0.8.h),
          Text(
            user['full_name'] as String? ?? user['username'] as String? ?? 'User',
            style: GoogleFonts.inter(
              fontSize: 11.sp,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryLight,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          if (user['mutual_connections'] != null) ...[
            SizedBox(height: 0.2.h),
            Text(
              '${user['mutual_connections']} mutual',
              style: GoogleFonts.inter(
                fontSize: 9.sp,
                color: AppTheme.textSecondaryLight,
              ),
            ),
          ],
          SizedBox(height: 0.8.h),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onFollow,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryLight,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 0.6.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Follow',
                style: GoogleFonts.inter(
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
