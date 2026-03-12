import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../services/audience_questions_service.dart';
import '../../../widgets/shimmer_skeleton_loader.dart';
import './question_card_widget.dart';

/// Moderation panel widget for creators to approve/reject/flag questions
class ModerationPanelWidget extends StatefulWidget {
  final String electionId;
  final VoidCallback onModerated;

  const ModerationPanelWidget({
    super.key,
    required this.electionId,
    required this.onModerated,
  });

  @override
  State<ModerationPanelWidget> createState() => _ModerationPanelWidgetState();
}

class _ModerationPanelWidgetState extends State<ModerationPanelWidget> {
  final AudienceQuestionsService _questionsService =
      AudienceQuestionsService.instance;

  bool _isLoading = true;
  List<Map<String, dynamic>> _pendingQuestions = [];

  @override
  void initState() {
    super.initState();
    _loadPendingQuestions();
  }

  Future<void> _loadPendingQuestions() async {
    setState(() => _isLoading = true);

    final questions = await _questionsService.getQuestions(
      electionId: widget.electionId,
      statusFilter: 'pending',
    );

    setState(() {
      _pendingQuestions = questions;
      _isLoading = false;
    });
  }

  Future<void> _moderateQuestion(String questionId, String action) async {
    final success = await _questionsService.moderateQuestion(
      questionId: questionId,
      action: action,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Question ${action}d'),
          backgroundColor: Colors.green,
        ),
      );
      await _loadPendingQuestions();
      widget.onModerated();
    }
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
          child: SkeletonCard(height: 15.h),
        ),
      );
    }

    if (_pendingQuestions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 48.sp,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            SizedBox(height: 2.h),
            Text(
              'No pending questions',
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
      onRefresh: _loadPendingQuestions,
      child: ListView.builder(
        padding: EdgeInsets.all(4.w),
        itemCount: _pendingQuestions.length,
        itemBuilder: (context, index) {
          final question = _pendingQuestions[index];
          return _buildModerationCard(theme, question);
        },
      ),
    );
  }

  Widget _buildModerationCard(ThemeData theme, Map<String, dynamic> question) {
    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      child: Column(
        children: [
          QuestionCardWidget(question: question, onVote: null),
          SizedBox(height: 1.h),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () =>
                      _moderateQuestion(question['id'], 'approved'),
                  icon: const Icon(Icons.check),
                  label: const Text('Approve'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () =>
                      _moderateQuestion(question['id'], 'rejected'),
                  icon: const Icon(Icons.close),
                  label: const Text('Reject'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 2.w),
              IconButton(
                onPressed: () => _moderateQuestion(question['id'], 'flagged'),
                icon: const Icon(Icons.flag),
                color: Colors.orange,
                style: IconButton.styleFrom(
                  backgroundColor: theme.colorScheme.surface.withValues(
                    alpha: 0.5,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
