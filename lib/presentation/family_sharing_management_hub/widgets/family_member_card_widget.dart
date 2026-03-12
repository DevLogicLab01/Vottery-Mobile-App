import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class FamilyMemberCardWidget extends StatelessWidget {
  final Map<String, dynamic> member;
  final VoidCallback onRemove;
  final VoidCallback onResendInvitation;

  const FamilyMemberCardWidget({
    super.key,
    required this.member,
    required this.onRemove,
    required this.onResendInvitation,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = member['status'] as String? ?? 'pending';
    final permissions = member['permissions'] as Map<String, dynamic>? ?? {};
    final email = member['email'] as String? ?? '';
    final relationship = member['relationship'] as String? ?? 'Other';

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: _getStatusColor(status).withAlpha(100),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildAvatar(email),
              SizedBox(width: 3.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      email,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimaryLight,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 0.5.h),
                    Row(
                      children: [
                        _buildRelationshipBadge(relationship),
                        SizedBox(width: 2.w),
                        _buildStatusBadge(status),
                      ],
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'remove') {
                    _showRemoveConfirmation(context);
                  } else if (value == 'resend') {
                    onResendInvitation();
                  }
                },
                itemBuilder: (context) => [
                  if (status == 'pending')
                    const PopupMenuItem(
                      value: 'resend',
                      child: Row(
                        children: [
                          Icon(Icons.send, size: 20),
                          SizedBox(width: 8),
                          Text('Resend Invitation'),
                        ],
                      ),
                    ),
                  const PopupMenuItem(
                    value: 'remove',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 20, color: Colors.red),
                        SizedBox(width: 8),
                        Text(
                          'Remove Member',
                          style: TextStyle(color: Colors.red),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Text(
            'Permissions',
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondaryLight,
            ),
          ),
          SizedBox(height: 1.h),
          _buildPermissionsGrid(permissions),
          if (member['joined_at'] != null) ...[
            SizedBox(height: 1.h),
            Text(
              'Joined ${_formatDate(member['joined_at'])}',
              style: TextStyle(
                fontSize: 11.sp,
                color: AppTheme.textSecondaryLight,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAvatar(String email) {
    final initials = email.isNotEmpty ? email[0].toUpperCase() : '?';

    return Container(
      width: 12.w,
      height: 12.w,
      decoration: BoxDecoration(
        color: AppTheme.primaryLight,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildRelationshipBadge(String relationship) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getRelationshipIcon(relationship),
            size: 4.w,
            color: Colors.blue,
          ),
          SizedBox(width: 1.w),
          Text(
            relationship,
            style: TextStyle(
              fontSize: 10.sp,
              fontWeight: FontWeight.w600,
              color: Colors.blue[900],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    final color = _getStatusColor(status);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
      decoration: BoxDecoration(
        color: color.withAlpha(50),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          fontSize: 10.sp,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildPermissionsGrid(Map<String, dynamic> permissions) {
    final permissionsList = [
      {'key': 'ad_free', 'label': 'Ad-Free', 'icon': Icons.block},
      {
        'key': 'priority_support',
        'label': 'Support',
        'icon': Icons.support_agent,
      },
      {'key': 'creator_tools', 'label': 'Creator', 'icon': Icons.create},
      {
        'key': 'analytics_dashboard',
        'label': 'Analytics',
        'icon': Icons.analytics,
      },
      {'key': 'api_access', 'label': 'API', 'icon': Icons.api},
    ];

    return Wrap(
      spacing: 2.w,
      runSpacing: 1.h,
      children: permissionsList.map((perm) {
        final isEnabled = permissions[perm['key']] == true;

        return Container(
          padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.8.h),
          decoration: BoxDecoration(
            color: isEnabled ? Colors.green[50] : Colors.grey[200],
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                perm['icon'] as IconData,
                size: 4.w,
                color: isEnabled ? Colors.green : Colors.grey,
              ),
              SizedBox(width: 1.w),
              Text(
                perm['label'] as String,
                style: TextStyle(
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w500,
                  color: isEnabled ? Colors.green[900] : Colors.grey[700],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  void _showRemoveConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Family Member'),
        content: const Text(
          'Are you sure you want to remove this family member? They will lose access to premium features.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onRemove();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'active':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'expired':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getRelationshipIcon(String relationship) {
    switch (relationship) {
      case 'Spouse':
      case 'Partner':
        return Icons.favorite;
      case 'Parent':
        return Icons.elderly;
      case 'Child':
        return Icons.child_care;
      case 'Sibling':
        return Icons.people;
      default:
        return Icons.person;
    }
  }

  String _formatDate(dynamic date) {
    try {
      final dateTime = DateTime.parse(date.toString());
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inDays == 0) {
        return 'today';
      } else if (difference.inDays == 1) {
        return 'yesterday';
      } else if (difference.inDays < 30) {
        return '${difference.inDays} days ago';
      } else if (difference.inDays < 365) {
        final months = (difference.inDays / 30).floor();
        return '$months ${months == 1 ? "month" : "months"} ago';
      } else {
        final years = (difference.inDays / 365).floor();
        return '$years ${years == 1 ? "year" : "years"} ago';
      }
    } catch (e) {
      return 'recently';
    }
  }
}
