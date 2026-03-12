import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/app_export.dart';
import '../../../services/jolts_service.dart';
import '../../../theme/app_theme.dart';

/// Jolt Comment Bottom Sheet - Interactive comment system
class JoltCommentBottomSheetWidget extends StatefulWidget {
  final Map<String, dynamic> jolt;
  final VoidCallback onCommentAdded;

  const JoltCommentBottomSheetWidget({
    super.key,
    required this.jolt,
    required this.onCommentAdded,
  });

  @override
  State<JoltCommentBottomSheetWidget> createState() =>
      _JoltCommentBottomSheetWidgetState();
}

class _JoltCommentBottomSheetWidgetState
    extends State<JoltCommentBottomSheetWidget> {
  final JoltsService _joltsService = JoltsService.instance;
  final TextEditingController _commentController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<Map<String, dynamic>> _comments = [];
  bool _isLoading = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadComments() async {
    setState(() => _isLoading = true);

    try {
      final comments = await _joltsService.getJoltComments(
        widget.jolt['id'] as String,
      );
      setState(() {
        _comments = comments;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Load comments error: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _submitComment() async {
    if (_commentController.text.trim().isEmpty) return;

    setState(() => _isSubmitting = true);

    try {
      final success = await _joltsService.commentOnJolt(
        joltId: widget.jolt['id'] as String,
        commentText: _commentController.text.trim(),
      );

      if (success) {
        _commentController.clear();
        await _loadComments();
        widget.onCommentAdded();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('💬 Comment added! +10 VP earned'),
              backgroundColor: AppTheme.accentLight,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Submit comment error: $e');
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80.h,
      decoration: BoxDecoration(
        color: AppTheme.backgroundLight,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      child: Column(
        children: [
          // Handle Bar
          Container(
            margin: EdgeInsets.symmetric(vertical: 1.h),
            width: 10.w,
            height: 0.5.h,
            decoration: BoxDecoration(
              color: AppTheme.borderLight,
              borderRadius: BorderRadius.circular(10.0),
            ),
          ),

          // Header
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_comments.length} Comments',
                  style: GoogleFonts.inter(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimaryLight,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, size: 6.w),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          Divider(height: 1, color: AppTheme.borderLight),

          // Comments List
          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.primaryLight,
                    ),
                  )
                : _comments.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.comment_outlined,
                          size: 15.w,
                          color: AppTheme.textSecondaryLight,
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          'No comments yet',
                          style: GoogleFonts.inter(
                            fontSize: 14.sp,
                            color: AppTheme.textSecondaryLight,
                          ),
                        ),
                        SizedBox(height: 1.h),
                        Text(
                          'Be the first to comment!',
                          style: GoogleFonts.inter(
                            fontSize: 12.sp,
                            color: AppTheme.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    controller: _scrollController,
                    padding: EdgeInsets.symmetric(
                      horizontal: 4.w,
                      vertical: 2.h,
                    ),
                    itemCount: _comments.length,
                    separatorBuilder: (context, index) => SizedBox(height: 2.h),
                    itemBuilder: (context, index) {
                      final comment = _comments[index];
                      return _buildCommentItem(comment);
                    },
                  ),
          ),

          // Comment Input
          Container(
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: AppTheme.surfaceLight,
              border: Border(top: BorderSide(color: AppTheme.borderLight)),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      decoration: InputDecoration(
                        hintText: 'Add a comment...',
                        hintStyle: GoogleFonts.inter(
                          fontSize: 13.sp,
                          color: AppTheme.textSecondaryLight,
                        ),
                        filled: true,
                        fillColor: AppTheme.backgroundLight,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25.0),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 4.w,
                          vertical: 1.5.h,
                        ),
                      ),
                      maxLines: null,
                      textCapitalization: TextCapitalization.sentences,
                    ),
                  ),
                  SizedBox(width: 2.w),
                  GestureDetector(
                    onTap: _isSubmitting ? null : _submitComment,
                    child: Container(
                      padding: EdgeInsets.all(2.5.w),
                      decoration: BoxDecoration(
                        color: _commentController.text.trim().isEmpty
                            ? AppTheme.borderLight
                            : AppTheme.primaryLight,
                        shape: BoxShape.circle,
                      ),
                      child: _isSubmitting
                          ? SizedBox(
                              width: 5.w,
                              height: 5.w,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Icon(Icons.send, color: Colors.white, size: 5.w),
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

  Widget _buildCommentItem(Map<String, dynamic> comment) {
    final user = comment['user'] as Map<String, dynamic>? ?? {};
    final username = user['username'] as String? ?? 'User';
    final commentText = comment['comment_text'] as String? ?? '';
    final createdAt = comment['created_at'] as String?;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 4.w,
          backgroundColor: AppTheme.primaryLight,
          child: Text(
            username[0].toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
        SizedBox(width: 3.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    username,
                    style: GoogleFonts.inter(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimaryLight,
                    ),
                  ),
                  SizedBox(width: 2.w),
                  if (createdAt != null)
                    Text(
                      _formatTimestamp(createdAt),
                      style: GoogleFonts.inter(
                        fontSize: 11.sp,
                        color: AppTheme.textSecondaryLight,
                      ),
                    ),
                ],
              ),
              SizedBox(height: 0.5.h),
              Text(
                commentText,
                style: GoogleFonts.inter(
                  fontSize: 13.sp,
                  color: AppTheme.textPrimaryLight,
                ),
              ),
              SizedBox(height: 1.h),
              Row(
                children: [
                  Text(
                    'Reply',
                    style: GoogleFonts.inter(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatTimestamp(String timestamp) {
    try {
      final dateTime = DateTime.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inDays > 0) {
        return '${difference.inDays}d ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}m ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return '';
    }
  }
}
