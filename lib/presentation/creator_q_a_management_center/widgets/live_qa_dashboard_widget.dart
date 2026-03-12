import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../services/audience_questions_service.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/shimmer_skeleton_loader.dart';

class LiveQADashboardWidget extends StatefulWidget {
  final String electionId;
  final bool isLiveSessionActive;

  const LiveQADashboardWidget({
    super.key,
    required this.electionId,
    required this.isLiveSessionActive,
  });

  @override
  State<LiveQADashboardWidget> createState() => _LiveQADashboardWidgetState();
}

class _LiveQADashboardWidgetState extends State<LiveQADashboardWidget> {
  final AudienceQuestionsService _questionsService =
      AudienceQuestionsService.instance;
  final TextEditingController _answerController = TextEditingController();

  bool _isLoading = true;
  List<Map<String, dynamic>> _approvedQuestions = [];
  Map<String, dynamic>? _selectedQuestion;
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    _loadApprovedQuestions();
  }

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

  Future<void> _loadApprovedQuestions() async {
    setState(() => _isLoading = true);

    final questions = await _questionsService.getQuestions(
      electionId: widget.electionId,
      sortBy: 'votes',
      statusFilter: 'approved',
    );

    setState(() {
      _approvedQuestions = questions;
      _isLoading = false;
    });
  }

  Future<void> _submitAnswer() async {
    if (_selectedQuestion == null || _answerController.text.trim().isEmpty) {
      return;
    }

    try {
      await _questionsService.answerQuestion(
        questionId: _selectedQuestion!['id'],
        answerText: _answerController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Answer submitted successfully'),
            duration: Duration(seconds: 2),
          ),
        );

        _answerController.clear();
        setState(() {
          _selectedQuestion = null;
          _isTyping = false;
        });

        await _loadApprovedQuestions();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit answer: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isLiveSessionActive) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.play_circle_outline, size: 64, color: Colors.grey[400]),
            SizedBox(height: 2.h),
            Text(
              'Start a live session to answer questions',
              style: TextStyle(fontSize: 16.sp, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          flex: 3,
          child: _isLoading
              ? ListView.builder(
                  itemCount: 5,
                  itemBuilder: (context, index) => ShimmerSkeletonLoader(
                    child: Container(
                      height: 12.h,
                      margin: EdgeInsets.all(2.w),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                    ),
                  ),
                )
              : _approvedQuestions.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.question_answer_outlined,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        'No approved questions yet',
                        style: TextStyle(
                          fontSize: 16.sp,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadApprovedQuestions,
                  child: ListView.builder(
                    itemCount: _approvedQuestions.length,
                    itemBuilder: (context, index) {
                      final question = _approvedQuestions[index];
                      final isSelected =
                          _selectedQuestion?['id'] == question['id'];

                      return Card(
                        margin: EdgeInsets.symmetric(
                          horizontal: 3.w,
                          vertical: 1.h,
                        ),
                        color: isSelected
                            ? AppTheme.primaryLight.withAlpha(26)
                            : Colors.white,
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppTheme.primaryLight.withAlpha(
                              26,
                            ),
                            child: Text(
                              '${index + 1}',
                              style: TextStyle(
                                color: AppTheme.primaryLight,
                                fontWeight: FontWeight.bold,
                              ),
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
                          subtitle: Row(
                            children: [
                              Icon(
                                Icons.thumb_up,
                                size: 14,
                                color: Colors.grey[600],
                              ),
                              SizedBox(width: 1.w),
                              Text(
                                '${question['upvotes'] ?? 0} votes',
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                          trailing: Icon(
                            isSelected
                                ? Icons.check_circle
                                : Icons.radio_button_unchecked,
                            color: isSelected
                                ? AppTheme.primaryLight
                                : Colors.grey,
                          ),
                          onTap: () {
                            setState(() {
                              _selectedQuestion = question;
                              _answerController.clear();
                            });
                          },
                        ),
                      );
                    },
                  ),
                ),
        ),
        if (_selectedQuestion != null)
          Container(
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(26),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.edit, color: AppTheme.primaryLight, size: 20),
                    SizedBox(width: 2.w),
                    Expanded(
                      child: Text(
                        'Answering: ${_selectedQuestion!['question_text']}',
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        setState(() {
                          _selectedQuestion = null;
                          _answerController.clear();
                          _isTyping = false;
                        });
                      },
                    ),
                  ],
                ),
                SizedBox(height: 1.h),
                TextField(
                  controller: _answerController,
                  decoration: InputDecoration(
                    hintText: 'Type your answer here...',
                    border: const OutlineInputBorder(),
                    suffixText: '${_answerController.text.length}/500',
                  ),
                  maxLines: 3,
                  maxLength: 500,
                  onChanged: (value) {
                    setState(() {
                      _isTyping = value.isNotEmpty;
                    });
                  },
                ),
                SizedBox(height: 1.h),
                Row(
                  children: [
                    if (_isTyping)
                      Row(
                        children: [
                          const SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 2.w),
                          Text(
                            'Typing...',
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    const Spacer(),
                    ElevatedButton.icon(
                      onPressed: _answerController.text.trim().isEmpty
                          ? null
                          : _submitAnswer,
                      icon: const Icon(Icons.send, size: 16),
                      label: const Text('Submit Answer'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryLight,
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
}
