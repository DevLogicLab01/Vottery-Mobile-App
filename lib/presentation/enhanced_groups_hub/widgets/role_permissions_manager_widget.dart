import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

/// Role Permissions Manager Widget - Custom role creation with granular controls
class RolePermissionsManagerWidget extends StatelessWidget {
  final String groupId;

  const RolePermissionsManagerWidget({super.key, required this.groupId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Role Permissions'),
        backgroundColor: AppTheme.primaryLight,
      ),
      body: ListView(
        padding: EdgeInsets.all(4.w),
        children: [
          _buildRoleCard(
            'Admin',
            'Full control over group settings and members',
            AppTheme.errorLight,
            [
              'Manage members',
              'Approve posts',
              'Create events',
              'Edit group settings',
              'Assign roles',
            ],
          ),
          SizedBox(height: 2.h),
          _buildRoleCard(
            'Moderator',
            'Can moderate content and manage members',
            AppTheme.warningLight,
            ['Approve posts', 'Remove posts', 'Warn members', 'Create events'],
          ),
          SizedBox(height: 2.h),
          _buildRoleCard(
            'Member',
            'Standard group member permissions',
            AppTheme.primaryLight,
            ['Create posts', 'Comment', 'RSVP to events'],
          ),
        ],
      ),
    );
  }

  Widget _buildRoleCard(
    String role,
    String description,
    Color color,
    List<String> permissions,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: color, width: 2),
        boxShadow: [
          BoxShadow(
            color: AppTheme.shadowLight,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(2.w),
                decoration: BoxDecoration(
                  color: color.withAlpha(26),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.shield, color: color, size: 6.w),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      role,
                      style: GoogleFonts.inter(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimaryLight,
                      ),
                    ),
                    Text(
                      description,
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
            'Permissions:',
            style: GoogleFonts.inter(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          SizedBox(height: 1.h),
          ...permissions.map(
            (permission) => Padding(
              padding: EdgeInsets.only(bottom: 0.8.h),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: color, size: 4.w),
                  SizedBox(width: 2.w),
                  Text(
                    permission,
                    style: GoogleFonts.inter(
                      fontSize: 11.sp,
                      color: AppTheme.textPrimaryLight,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
