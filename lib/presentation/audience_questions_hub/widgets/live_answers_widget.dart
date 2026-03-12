import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../services/audience_questions_service.dart';

/// Live answers widget showing real-time creator responses
class LiveAnswersWidget extends StatefulWidget {
  final String electionId;

  const LiveAnswersWidget({super.key, required this.electionId});

  @override
  State<LiveAnswersWidget> createState() => _LiveAnswersWidgetState();
}

class _LiveAnswersWidgetState extends State<LiveAnswersWidget> {
  final AudienceQuestionsService _questionsService =
      AudienceQuestionsService.instance;

  bool _isLoading = true;
  List<Map<String, dynamic>> _answeredQuestions = [];

  @override
  void initState() {
    super.initState();
    _loadAnsweredQuestions();
  }

  Future<void> _loadAnsweredQuestions() async {
    setState(() => _isLoading = true);

    final questions = await _questionsService.getQuestions(
      electionId: widget.electionId,
      sortBy: 'recent',
    );

    final answered = questions
        .where((q) => (q['answers'] as List?)?.isNotEmpty ?? false)
        .toList();

    setState(() {
      _answeredQuestions = answered;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return ListView.builder(
        padding: EdgeInsets.all(4.w),
        itemCount: 3,
        itemBuilder: (context, index) => Padding(
          padding: EdgeInsets.only(bottom: 2.h),
          child: Container(
            height: 20.h,
            decoration: BoxDecoration(
              color: theme.colorScheme.surface.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12.0),
            ),
          ),
        ),
      );
    }

    if (_answeredQuestions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.live_tv_outlined,
              size: 48.sp,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            SizedBox(height: 2.h),
            Text(
              'No live answers yet',
              style: TextStyle(
                fontSize: 14.sp,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAnsweredQuestions,
      child: ListView.builder(
        padding: EdgeInsets.all(4.w),
        itemCount: _answeredQuestions.length,
        itemBuilder: (context, index) {
          final question = _answeredQuestions[index];
          final answers = question['answers'] as List? ?? [];
          return _buildAnswerCard(theme, question, answers);
        },
      ),
    );
  }

  Widget _buildAnswerCard(
    ThemeData theme,
    Map<String, dynamic> question,
    List answers,
  ) {
    final answer = answers.first;
    final isLive = answer['is_live'] as bool? ?? false;
    final createdAt = DateTime.parse(answer['created_at'] as String);

    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: isLive
              ? Colors.red.withValues(alpha: 0.5)
              : theme.colorScheme.outline.withValues(alpha: 0.3),
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
          // Live indicator
          if (isLive)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.circle, size: 8.sp, color: Colors.white),
                  SizedBox(width: 1.w),
                  Text(
                    'LIVE',
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          SizedBox(height: 2.h),

          // Question
          Text(
            'Q: ${question['question_text'] as String? ?? ''}',
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 2.h),

          // Answer
          Container(
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.person,
                      size: 16.sp,
                      color: theme.colorScheme.primary,
                    ),
                    SizedBox(width: 2.w),
                    Text(
                      answer['answerer']?['full_name'] ?? 'Creator',
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const Spacer(),
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
                SizedBox(height: 1.h),
                Text(
                  answer['answer_text'] as String? ?? '',
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: theme.colorScheme.onSurface,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
