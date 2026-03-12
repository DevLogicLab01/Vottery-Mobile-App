import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

/// Post Approval Queue Widget - Content moderation workflow
class PostApprovalQueueWidget extends StatefulWidget {
  final String groupId;

  const PostApprovalQueueWidget({super.key, required this.groupId});

  @override
  State<PostApprovalQueueWidget> createState() =>
      _PostApprovalQueueWidgetState();
}

class _PostApprovalQueueWidgetState extends State<PostApprovalQueueWidget> {
  List<Map<String, dynamic>> _pendingPosts = [];

  @override
  void initState() {
    super.initState();
    _loadPendingPosts();
  }

  void _loadPendingPosts() {
    setState(() {
      _pendingPosts = [
        {
          'id': 'post_1',
          'author': 'Jane Doe',
          'content': 'What are your thoughts on the upcoming local election?',
          'ai_flag': null,
          'timestamp': '2 hours ago',
        },
        {
          'id': 'post_2',
          'author': 'Bob Johnson',
          'content': 'Check out this amazing voting guide I created!',
          'ai_flag': 'Potential spam',
          'timestamp': '5 hours ago',
        },
      ];
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_pendingPosts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 20.w,
              color: AppTheme.accentLight,
            ),
            SizedBox(height: 2.h),
            Text(
              'All posts approved',
              style: GoogleFonts.inter(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimaryLight,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: EdgeInsets.all(4.w),
      itemCount: _pendingPosts.length,
      separatorBuilder: (context, index) => SizedBox(height: 2.h),
      itemBuilder: (context, index) {
        final post = _pendingPosts[index];
        return _buildPostCard(post);
      },
    );
  }

  Widget _buildPostCard(Map<String, dynamic> post) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: post['ai_flag'] != null
            ? Border.all(color: AppTheme.warningLight, width: 2)
            : null,
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
              Text(
                post['author'],
                style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimaryLight,
                ),
              ),
              Spacer(),
              Text(
                post['timestamp'],
                style: GoogleFonts.inter(
                  fontSize: 11.sp,
                  color: AppTheme.textSecondaryLight,
                ),
              ),
            ],
          ),
          if (post['ai_flag'] != null) ...[
            SizedBox(height: 1.h),
            Container(
              padding: EdgeInsets.all(2.w),
              decoration: BoxDecoration(
                color: AppTheme.warningLight.withAlpha(26),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber,
                    color: AppTheme.warningLight,
                    size: 5.w,
                  ),
                  SizedBox(width: 2.w),
                  Text(
                    'AI Flag: ${post['ai_flag']}',
                    style: GoogleFonts.inter(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.warningLight,
                    ),
                  ),
                ],
              ),
            ),
          ],
          SizedBox(height: 1.5.h),
          Text(
            post['content'],
            style: GoogleFonts.inter(
              fontSize: 13.sp,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _approvePost(post['id']),
                  icon: Icon(Icons.check, size: 5.w),
                  label: Text('Approve'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentLight,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 1.5.h),
                  ),
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _rejectPost(post['id']),
                  icon: Icon(Icons.close, size: 5.w),
                  label: Text('Reject'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.errorLight,
                    side: BorderSide(color: AppTheme.errorLight),
                    padding: EdgeInsets.symmetric(vertical: 1.5.h),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _approvePost(String postId) {
    setState(() {
      _pendingPosts.removeWhere((post) => post['id'] == postId);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Post approved'),
        backgroundColor: AppTheme.accentLight,
      ),
    );
  }

  void _rejectPost(String postId) {
    setState(() {
      _pendingPosts.removeWhere((post) => post['id'] == postId);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Post rejected'),
        backgroundColor: AppTheme.errorLight,
      ),
    );
  }
}
