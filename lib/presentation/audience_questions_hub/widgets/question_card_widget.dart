import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../theme/app_theme.dart';

/// Question card widget displaying question with voting and status
class QuestionCardWidget extends StatelessWidget {
  final Map<String, dynamic> question;
  final Function(String)? onVote;
  final bool showStatus;

  const QuestionCardWidget({
    super.key,
    required this.question,
    this.onVote,
    this.showStatus = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final upvotes = question['upvotes'] as int? ?? 0;
    final downvotes = question['downvotes'] as int? ?? 0;
    final status = question['moderation_status'] as String? ?? 'pending';
    final answers = question['answers'] as List? ?? [];
    final submitter = question['submitter'] as Map<String, dynamic>?;
    final isAnonymous = question['is_anonymous'] as bool? ?? false;
    final createdAt = DateTime.parse(question['created_at'] as String);

    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              CircleAvatar(
                radius: 16.sp,
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Icon(
                  isAnonymous ? Icons.person_outline : Icons.person,
                  size: 16.sp,
                  color: theme.colorScheme.primary,
                ),
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isAnonymous
                          ? 'Anonymous'
                          : submitter?['full_name'] ?? 'Unknown',
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      timeago.format(createdAt),
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.6,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (showStatus) _buildStatusBadge(theme, status),
            ],
          ),
          SizedBox(height: 2.h),

          // Question text
          Text(
            question['question_text'] as String? ?? '',
            style: TextStyle(
              fontSize: 14.sp,
              color: theme.colorScheme.onSurface,
              height: 1.4,
            ),
          ),
          SizedBox(height: 2.h),

          // Voting and answers
          Row(
            children: [
              if (onVote != null) ...[
                _buildVoteButton(theme, Icons.arrow_upward, upvotes, 'upvote'),
                SizedBox(width: 2.w),
                _buildVoteButton(
                  theme,
                  Icons.arrow_downward,
                  downvotes,
                  'downvote',
                ),
                SizedBox(width: 4.w),
              ],
              if (answers.isNotEmpty)
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 2.w,
                    vertical: 0.5.h,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.accentLight.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        size: 14.sp,
                        color: AppTheme.accentLight,
                      ),
                      SizedBox(width: 1.w),
                      Text(
                        'Answered',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: AppTheme.accentLight,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),

          // Show answer if exists
          if (answers.isNotEmpty) ...[
            SizedBox(height: 2.h),
            Container(
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withValues(
                  alpha: 0.3,
                ),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.person,
                        size: 14.sp,
                        color: theme.colorScheme.primary,
                      ),
                      SizedBox(width: 1.w),
                      Text(
                        answers[0]['answerer']?['full_name'] ?? 'Creator',
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 1.h),
                  Text(
                    answers[0]['answer_text'] as String? ?? '',
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildVoteButton(
    ThemeData theme,
    IconData icon,
    int count,
    String voteType,
  ) {
    return InkWell(
      onTap: () => onVote?.call(voteType),
      borderRadius: BorderRadius.circular(8.0),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16.sp, color: theme.colorScheme.primary),
            SizedBox(width: 1.w),
            Text(
              count.toString(),
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(ThemeData theme, String status) {
    Color color;
    String label;

    switch (status) {
      case 'approved':
        color = Colors.green;
        label = 'Approved';
        break;
      case 'rejected':
        color = Colors.red;
        label = 'Rejected';
        break;
      case 'flagged':
        color = Colors.orange;
        label = 'Flagged';
        break;
      default:
        color = Colors.grey;
        label = 'Pending';
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11.sp,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
