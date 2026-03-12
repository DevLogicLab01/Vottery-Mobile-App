import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class SuggestedConnectionCardWidget extends StatelessWidget {
  final Map<String, dynamic> user;
  final VoidCallback onFollow;
  final VoidCallback onAddFriend;

  const SuggestedConnectionCardWidget({
    super.key,
    required this.user,
    required this.onFollow,
    required this.onAddFriend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40.w,
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Avatar
          CircleAvatar(
            radius: 10.w,
            backgroundImage: NetworkImage(
              user['avatar_url'] ??
                  'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde',
            ),
          ),
          SizedBox(height: 1.h),

          // Name
          Text(
            user['full_name'] ?? 'Unknown User',
            style: GoogleFonts.inter(
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryLight,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 0.3.h),

          // Mutual Connections
          if (user['mutual_connections'] != null)
            Text(
              '${user['mutual_connections']} mutual',
              style: GoogleFonts.inter(
                fontSize: 11.sp,
                color: AppTheme.textSecondaryLight,
              ),
            ),
          SizedBox(height: 1.h),

          // Follow Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onFollow,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryLight,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 1.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Follow',
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          SizedBox(height: 1.h),

          // Add Friend Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: onAddFriend,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.primaryLight,
                side: BorderSide(color: AppTheme.primaryLight),
                padding: EdgeInsets.symmetric(vertical: 1.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Add Friend',
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
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
