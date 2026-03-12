import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

/// Member Moderation Dashboard Widget - Admin tools for group management
class MemberModerationDashboardWidget extends StatefulWidget {
  final String groupId;
  final bool isAdmin;

  const MemberModerationDashboardWidget({
    super.key,
    required this.groupId,
    required this.isAdmin,
  });

  @override
  State<MemberModerationDashboardWidget> createState() =>
      _MemberModerationDashboardWidgetState();
}

class _MemberModerationDashboardWidgetState
    extends State<MemberModerationDashboardWidget> {
  List<Map<String, dynamic>> _members = [];
  String _selectedRole = 'All';

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  void _loadMembers() {
    setState(() {
      _members = [
        {
          'id': 'member_1',
          'name': 'John Smith',
          'role': 'Admin',
          'activity_score': 95,
          'posts': 142,
          'warnings': 0,
          'joined': '2025-01-15',
          'avatar_url':
              'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e',
        },
        {
          'id': 'member_2',
          'name': 'Emma Wilson',
          'role': 'Moderator',
          'activity_score': 88,
          'posts': 98,
          'warnings': 1,
          'joined': '2025-02-01',
          'avatar_url':
              'https://images.unsplash.com/photo-1438761681033-6461ffad8d80',
        },
        {
          'id': 'member_3',
          'name': 'Michael Brown',
          'role': 'Member',
          'activity_score': 72,
          'posts': 45,
          'warnings': 0,
          'joined': '2026-01-10',
          'avatar_url':
              'https://images.unsplash.com/photo-1500648767791-00dcc994a43e',
        },
      ];
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isAdmin && widget.groupId.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.admin_panel_settings_outlined,
              size: 20.w,
              color: AppTheme.textSecondaryLight,
            ),
            SizedBox(height: 2.h),
            Text(
              'Admin Access Required',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimaryLight,
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              'Select a group where you have admin privileges',
              style: TextStyle(
                fontSize: 13.sp,
                color: AppTheme.textSecondaryLight,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Filter Bar
        Container(
          color: Colors.white,
          padding: EdgeInsets.all(4.w),
          child: Row(
            children: [
              Text(
                'Filter by Role:',
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimaryLight,
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildRoleChip('All'),
                      _buildRoleChip('Admin'),
                      _buildRoleChip('Moderator'),
                      _buildRoleChip('Member'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // Members List
        Expanded(
          child: ListView.separated(
            padding: EdgeInsets.all(4.w),
            itemCount: _members.length,
            separatorBuilder: (context, index) => SizedBox(height: 2.h),
            itemBuilder: (context, index) {
              final member = _members[index];
              return _buildMemberCard(member);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRoleChip(String role) {
    final isSelected = _selectedRole == role;
    return Padding(
      padding: EdgeInsets.only(right: 2.w),
      child: FilterChip(
        label: Text(role),
        selected: isSelected,
        onSelected: (selected) {
          setState(() => _selectedRole = role);
        },
        backgroundColor: Colors.white,
        selectedColor: AppTheme.primaryLight,
        labelStyle: TextStyle(
          fontSize: 11.sp,
          fontWeight: FontWeight.w600,
          color: isSelected ? Colors.white : AppTheme.primaryLight,
        ),
      ),
    );
  }

  Widget _buildMemberCard(Map<String, dynamic> member) {
    return Container(
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
      padding: EdgeInsets.all(4.w),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 8.w,
                backgroundImage: NetworkImage(member['avatar_url']),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          member['name'],
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimaryLight,
                          ),
                        ),
                        SizedBox(width: 2.w),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 2.w,
                            vertical: 0.3.h,
                          ),
                          decoration: BoxDecoration(
                            color: _getRoleColor(member['role']).withAlpha(51),
                            borderRadius: BorderRadius.circular(4.0),
                          ),
                          child: Text(
                            member['role'],
                            style: TextStyle(
                              fontSize: 9.sp,
                              fontWeight: FontWeight.w700,
                              color: _getRoleColor(member['role']),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 0.5.h),
                    Text(
                      'Joined ${member['joined']}',
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: AppTheme.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, color: AppTheme.textSecondaryLight),
                onSelected: (value) => _handleMemberAction(value, member),
                itemBuilder: (context) => [
                  PopupMenuItem(value: 'role', child: Text('Change Role')),
                  PopupMenuItem(value: 'warn', child: Text('Issue Warning')),
                  PopupMenuItem(value: 'remove', child: Text('Remove Member')),
                ],
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              Expanded(
                child: _buildStatColumn(
                  'Activity',
                  '${member['activity_score']}%',
                  AppTheme.accentLight,
                ),
              ),
              Expanded(
                child: _buildStatColumn(
                  'Posts',
                  '${member['posts']}',
                  AppTheme.primaryLight,
                ),
              ),
              Expanded(
                child: _buildStatColumn(
                  'Warnings',
                  '${member['warnings']}',
                  member['warnings'] > 0
                      ? AppTheme.errorLight
                      : AppTheme.textSecondaryLight,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        SizedBox(height: 0.3.h),
        Text(
          label,
          style: TextStyle(fontSize: 10.sp, color: AppTheme.textSecondaryLight),
        ),
      ],
    );
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'Admin':
        return AppTheme.errorLight;
      case 'Moderator':
        return AppTheme.warningLight;
      default:
        return AppTheme.primaryLight;
    }
  }

  void _handleMemberAction(String action, Map<String, dynamic> member) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$action action for ${member['name']}')),
    );
  }
}
