import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class ConnectionUserCardWidget extends StatelessWidget {
  final Map<String, dynamic> user;
  final String actionType; // 'follow', 'unfollow', 'unfriend'
  final VoidCallback onAction;
  final bool showMutualConnections;

  const ConnectionUserCardWidget({
    super.key,
    required this.user,
    required this.actionType,
    required this.onAction,
    this.showMutualConnections = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 8.w,
            backgroundImage: NetworkImage(
              user['avatar_url'] ??
                  'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde',
            ),
          ),
          SizedBox(width: 3.w),

          // User Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user['full_name'] ?? 'Unknown User',
                  style: GoogleFonts.inter(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimaryLight,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 0.3.h),
                Text(
                  '@${user['username'] ?? 'user'}',
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    color: AppTheme.textSecondaryLight,
                  ),
                ),
                if (showMutualConnections && user['mutual_connections'] != null)
                  Padding(
                    padding: EdgeInsets.only(top: 0.5.h),
                    child: Text(
                      '${user['mutual_connections']} mutual connections',
                      style: GoogleFonts.inter(
                        fontSize: 11.sp,
                        color: AppTheme.textSecondaryLight,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Action Button
          _buildActionButton(),
        ],
      ),
    );
  }

  Widget _buildActionButton() {
    Color buttonColor;
    Color textColor;
    String buttonText;
    IconData? icon;

    switch (actionType) {
      case 'follow':
        buttonColor = AppTheme.primaryLight;
        textColor = Colors.white;
        buttonText = 'Follow';
        icon = Icons.person_add;
        break;
      case 'unfollow':
        buttonColor = AppTheme.surfaceLight;
        textColor = AppTheme.textPrimaryLight;
        buttonText = 'Unfollow';
        icon = Icons.person_remove;
        break;
      case 'unfriend':
        buttonColor = AppTheme.errorLight.withAlpha(26);
        textColor = AppTheme.errorLight;
        buttonText = 'Unfriend';
        icon = Icons.person_off;
        break;
      default:
        buttonColor = AppTheme.primaryLight;
        textColor = Colors.white;
        buttonText = 'Action';
    }

    return ElevatedButton.icon(
      onPressed: onAction,
      icon: icon != null ? Icon(icon, size: 4.w) : const SizedBox.shrink(),
      label: Text(buttonText),
      style: ElevatedButton.styleFrom(
        backgroundColor: buttonColor,
        foregroundColor: textColor,
        padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: GoogleFonts.inter(
          fontSize: 12.sp,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
