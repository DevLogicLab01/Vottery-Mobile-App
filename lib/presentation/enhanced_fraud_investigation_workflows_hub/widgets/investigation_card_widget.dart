import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class InvestigationCardWidget extends StatelessWidget {
  final Map<String, dynamic> investigation;
  final VoidCallback onTap;
  final VoidCallback onAssign;

  const InvestigationCardWidget({
    super.key,
    required this.investigation,
    required this.onTap,
    required this.onAssign,
  });

  @override
  Widget build(BuildContext context) {
    final priority = investigation['priority'] as String? ?? 'medium';
    final status = investigation['status'] as String? ?? 'pending_review';
    final patternName =
        investigation['pattern_name'] as String? ?? 'Unknown Pattern';
    final title = investigation['title'] as String? ?? 'Untitled Investigation';
    final affectedUsers = investigation['affected_users'] as List? ?? [];
    final createdAt = investigation['created_at'] != null
        ? DateTime.parse(investigation['created_at'])
        : DateTime.now();
    final assignedTo = investigation['assigned_to'] as String?;

    return Card(
      margin: EdgeInsets.only(bottom: 2.h),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.0),
        child: Padding(
          padding: EdgeInsets.all(4.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  // Priority badge
                  _buildPriorityBadge(priority),
                  SizedBox(width: 2.w),

                  // Pattern name
                  Expanded(
                    child: Text(
                      patternName,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimaryLight,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                  // Status badge
                  _buildStatusBadge(status),
                ],
              ),

              SizedBox(height: 1.h),

              // Title
              Text(
                title,
                style: TextStyle(
                  fontSize: 13.sp,
                  color: AppTheme.textSecondaryLight,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              SizedBox(height: 1.5.h),

              // Metrics row
              Row(
                children: [
                  Icon(
                    Icons.people_outline,
                    size: 4.w,
                    color: AppTheme.textSecondaryLight,
                  ),
                  SizedBox(width: 1.w),
                  Text(
                    '${affectedUsers.length} users',
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: AppTheme.textSecondaryLight,
                    ),
                  ),
                  SizedBox(width: 4.w),
                  Icon(
                    Icons.access_time,
                    size: 4.w,
                    color: AppTheme.textSecondaryLight,
                  ),
                  SizedBox(width: 1.w),
                  Text(
                    timeago.format(createdAt),
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: AppTheme.textSecondaryLight,
                    ),
                  ),
                ],
              ),

              SizedBox(height: 1.5.h),

              // Action buttons
              Row(
                children: [
                  // Assigned to
                  if (assignedTo != null)
                    Expanded(
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 3.w,
                            backgroundColor: AppTheme.primaryLight,
                            child: Icon(
                              Icons.person,
                              size: 3.w,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: 2.w),
                          Text(
                            'Assigned',
                            style: TextStyle(
                              fontSize: 11.sp,
                              color: AppTheme.textSecondaryLight,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onAssign,
                        icon: Icon(Icons.person_add, size: 4.w),
                        label: Text(
                          'Assign',
                          style: TextStyle(fontSize: 11.sp),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                            horizontal: 3.w,
                            vertical: 1.h,
                          ),
                        ),
                      ),
                    ),

                  SizedBox(width: 2.w),

                  // View details button
                  ElevatedButton.icon(
                    onPressed: onTap,
                    icon: Icon(Icons.arrow_forward, size: 4.w),
                    label: Text('View', style: TextStyle(fontSize: 11.sp)),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        horizontal: 3.w,
                        vertical: 1.h,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPriorityBadge(String priority) {
    Color color;
    String label;

    switch (priority.toLowerCase()) {
      case 'critical':
        color = AppTheme.errorLight;
        label = 'P0';
        break;
      case 'high':
        color = Colors.orange;
        label = 'P1';
        break;
      case 'medium':
        color = AppTheme.warningLight;
        label = 'P2';
        break;
      case 'low':
        color = AppTheme.accentLight;
        label = 'P3';
        break;
      default:
        color = AppTheme.textSecondaryLight;
        label = 'P2';
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(4.0),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10.sp,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String label;

    switch (status.toLowerCase()) {
      case 'pending_review':
        color = AppTheme.warningLight;
        label = 'New';
        break;
      case 'investigating':
        color = AppTheme.secondaryLight;
        label = 'Investigating';
        break;
      case 'action_taken':
        color = Colors.purple;
        label = 'Action Taken';
        break;
      case 'resolved':
        color = AppTheme.accentLight;
        label = 'Resolved';
        break;
      case 'false_positive':
        color = AppTheme.textSecondaryLight;
        label = 'False Positive';
        break;
      case 'escalated':
        color = AppTheme.errorLight;
        label = 'Escalated';
        break;
      default:
        color = AppTheme.textSecondaryLight;
        label = status;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(4.0),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10.sp,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
