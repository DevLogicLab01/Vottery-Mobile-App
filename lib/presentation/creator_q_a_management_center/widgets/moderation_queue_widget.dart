import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../services/audience_questions_service.dart';
import '../../../theme/app_theme.dart';

class ModerationQueueWidget extends StatefulWidget {
  final String electionId;
  final VoidCallback onModerationComplete;

  const ModerationQueueWidget({
    super.key,
    required this.electionId,
    required this.onModerationComplete,
  });

  @override
  State<ModerationQueueWidget> createState() => _ModerationQueueWidgetState();
}

class _ModerationQueueWidgetState extends State<ModerationQueueWidget> {
  final AudienceQuestionsService _questionsService =
      AudienceQuestionsService.instance;

  bool _isLoading = true;
  List<Map<String, dynamic>> _pendingQuestions = [];
  final Set<String> _selectedQuestions = {};
  bool _bulkModeEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadPendingQuestions();
  }

  Future<void> _loadPendingQuestions() async {
    setState(() => _isLoading = true);

    final questions = await _questionsService.getQuestions(
      electionId: widget.electionId,
      sortBy: 'created_at',
      statusFilter: 'pending',
    );

    setState(() {
      _pendingQuestions = questions;
      _isLoading = false;
    });
  }

  Future<void> _moderateQuestion(
    String questionId,
    String action,
    String? notes,
  ) async {
    try {
      await _questionsService.moderateQuestion(
        questionId: questionId,
        action: action,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Question ${action}d successfully'),
            duration: const Duration(seconds: 2),
          ),
        );

        await _loadPendingQuestions();
        widget.onModerationComplete();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to moderate question: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _bulkModerate(String action) async {
    if (_selectedQuestions.isEmpty) return;

    try {
      for (final questionId in _selectedQuestions) {
        await _questionsService.moderateQuestion(
          questionId: questionId,
          action: action,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_selectedQuestions.length} questions ${action}d'),
            duration: const Duration(seconds: 2),
          ),
        );

        setState(() {
          _selectedQuestions.clear();
          _bulkModeEnabled = false;
        });

        await _loadPendingQuestions();
        widget.onModerationComplete();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Bulk moderation failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showModerationDialog(Map<String, dynamic> question, String action) {
    final TextEditingController notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${action.toUpperCase()} Question'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              question['question_text'] ?? '',
              style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 2.h),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(
                labelText: 'Moderator Notes (Optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _moderateQuestion(
                question['id'],
                action,
                notesController.text.isEmpty ? null : notesController.text,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: action == 'approve'
                  ? Colors.green
                  : action == 'reject'
                  ? Colors.red
                  : Colors.orange,
            ),
            child: Text(action.toUpperCase()),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(2.w),
          color: Colors.grey[100],
          child: Row(
            children: [
              Checkbox(
                value: _bulkModeEnabled,
                onChanged: (value) {
                  setState(() {
                    _bulkModeEnabled = value ?? false;
                    if (!_bulkModeEnabled) {
                      _selectedQuestions.clear();
                    }
                  });
                },
              ),
              Text('Bulk Mode', style: TextStyle(fontSize: 14.sp)),
              const Spacer(),
              if (_bulkModeEnabled && _selectedQuestions.isNotEmpty) ...[
                ElevatedButton.icon(
                  onPressed: () => _bulkModerate('approve'),
                  icon: const Icon(Icons.check, size: 16),
                  label: const Text('Approve'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: EdgeInsets.symmetric(
                      horizontal: 2.w,
                      vertical: 1.h,
                    ),
                  ),
                ),
                SizedBox(width: 2.w),
                ElevatedButton.icon(
                  onPressed: () => _bulkModerate('reject'),
                  icon: const Icon(Icons.close, size: 16),
                  label: const Text('Reject'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: EdgeInsets.symmetric(
                      horizontal: 2.w,
                      vertical: 1.h,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        Expanded(
          child: _isLoading
              ? ListView.builder(
                  itemCount: 5,
                  itemBuilder: (context, index) => Padding(
                    padding: EdgeInsets.all(2.w),
                    child: Container(
                      height: 15.h,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                )
              : _pendingQuestions.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        'No pending questions',
                        style: TextStyle(
                          fontSize: 16.sp,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadPendingQuestions,
                  child: ListView.builder(
                    itemCount: _pendingQuestions.length,
                    itemBuilder: (context, index) {
                      final question = _pendingQuestions[index];
                      final isSelected = _selectedQuestions.contains(
                        question['id'],
                      );

                      return Card(
                        margin: EdgeInsets.symmetric(
                          horizontal: 3.w,
                          vertical: 1.h,
                        ),
                        child: ListTile(
                          leading: _bulkModeEnabled
                              ? Checkbox(
                                  value: isSelected,
                                  onChanged: (value) {
                                    setState(() {
                                      if (value == true) {
                                        _selectedQuestions.add(question['id']);
                                      } else {
                                        _selectedQuestions.remove(
                                          question['id'],
                                        );
                                      }
                                    });
                                  },
                                )
                              : CircleAvatar(
                                  backgroundColor: AppTheme.primaryLight
                                      .withAlpha(26),
                                  child: Icon(
                                    Icons.question_answer,
                                    color: AppTheme.primaryLight,
                                  ),
                                ),
                          title: Text(
                            question['question_text'] ?? '',
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(height: 0.5.h),
                              Row(
                                children: [
                                  Icon(
                                    Icons.thumb_up,
                                    size: 14,
                                    color: Colors.grey[600],
                                  ),
                                  SizedBox(width: 1.w),
                                  Text(
                                    '${question['upvotes'] ?? 0}',
                                    style: TextStyle(
                                      fontSize: 12.sp,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  SizedBox(width: 3.w),
                                  Icon(
                                    Icons.access_time,
                                    size: 14,
                                    color: Colors.grey[600],
                                  ),
                                  SizedBox(width: 1.w),
                                  Text(
                                    _formatTimestamp(question['created_at']),
                                    style: TextStyle(
                                      fontSize: 12.sp,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          trailing: !_bulkModeEnabled
                              ? Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                        Icons.check_circle,
                                        color: Colors.green,
                                      ),
                                      onPressed: () => _showModerationDialog(
                                        question,
                                        'approve',
                                      ),
                                      tooltip: 'Approve',
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.cancel,
                                        color: Colors.red,
                                      ),
                                      onPressed: () => _showModerationDialog(
                                        question,
                                        'reject',
                                      ),
                                      tooltip: 'Reject',
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.flag,
                                        color: Colors.orange,
                                      ),
                                      onPressed: () => _showModerationDialog(
                                        question,
                                        'flag',
                                      ),
                                      tooltip: 'Flag',
                                    ),
                                  ],
                                )
                              : null,
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'Unknown';

    try {
      final DateTime dateTime = DateTime.parse(timestamp.toString());
      final Duration difference = DateTime.now().difference(dateTime);

      if (difference.inMinutes < 1) {
        return 'Just now';
      } else if (difference.inHours < 1) {
        return '${difference.inMinutes}m ago';
      } else if (difference.inDays < 1) {
        return '${difference.inHours}h ago';
      } else {
        return '${difference.inDays}d ago';
      }
    } catch (e) {
      return 'Unknown';
    }
  }
}
