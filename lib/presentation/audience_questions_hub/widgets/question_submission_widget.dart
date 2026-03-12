import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../services/audience_questions_service.dart';
import '../../../theme/app_theme.dart';

/// Question submission widget with character limit and guidelines
class QuestionSubmissionWidget extends StatefulWidget {
  final String electionId;
  final VoidCallback onQuestionSubmitted;

  const QuestionSubmissionWidget({
    super.key,
    required this.electionId,
    required this.onQuestionSubmitted,
  });

  @override
  State<QuestionSubmissionWidget> createState() =>
      _QuestionSubmissionWidgetState();
}

class _QuestionSubmissionWidgetState extends State<QuestionSubmissionWidget> {
  final AudienceQuestionsService _questionsService =
      AudienceQuestionsService.instance;
  final TextEditingController _questionController = TextEditingController();
  final int _maxCharacters = 500;
  bool _isAnonymous = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _questionController.dispose();
    super.dispose();
  }

  Future<void> _submitQuestion() async {
    if (_questionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a question'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final success = await _questionsService.submitQuestion(
      electionId: widget.electionId,
      questionText: _questionController.text.trim(),
      isAnonymous: _isAnonymous,
    );

    setState(() => _isSubmitting = false);

    if (success && mounted) {
      _questionController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Question submitted for moderation'),
          backgroundColor: AppTheme.accentLight,
        ),
      );
      widget.onQuestionSubmitted();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to submit question'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final remainingChars = _maxCharacters - _questionController.text.length;

    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Guidelines
          Container(
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 18.sp,
                      color: theme.colorScheme.primary,
                    ),
                    SizedBox(width: 2.w),
                    Text(
                      'Submission Guidelines',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 1.h),
                _buildGuideline('Keep questions clear and concise'),
                _buildGuideline('Stay on topic with the election'),
                _buildGuideline('Be respectful and constructive'),
                _buildGuideline('Questions are moderated before appearing'),
              ],
            ),
          ),
          SizedBox(height: 3.h),

          // Question input
          Text(
            'Your Question',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 1.h),
          TextField(
            controller: _questionController,
            maxLines: 6,
            maxLength: _maxCharacters,
            decoration: InputDecoration(
              hintText: 'What would you like to ask?',
              hintStyle: TextStyle(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
              ),
              filled: true,
              fillColor: theme.colorScheme.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.0),
                borderSide: BorderSide(
                  color: theme.colorScheme.outline.withValues(alpha: 0.3),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.0),
                borderSide: BorderSide(
                  color: theme.colorScheme.outline.withValues(alpha: 0.3),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.0),
                borderSide: BorderSide(
                  color: theme.colorScheme.primary,
                  width: 2.0,
                ),
              ),
              counterText: '',
            ),
            onChanged: (value) => setState(() {}),
          ),
          SizedBox(height: 1.h),
          Text(
            '$remainingChars characters remaining',
            style: TextStyle(
              fontSize: 11.sp,
              color: remainingChars < 50
                  ? Colors.red
                  : theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          SizedBox(height: 2.h),

          // Anonymous toggle
          InkWell(
            onTap: () => setState(() => _isAnonymous = !_isAnonymous),
            child: Row(
              children: [
                Checkbox(
                  value: _isAnonymous,
                  onChanged: (value) =>
                      setState(() => _isAnonymous = value ?? false),
                  activeColor: theme.colorScheme.primary,
                ),
                Text(
                  'Submit anonymously',
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 3.h),

          // Submit button
          SizedBox(
            width: double.infinity,
            height: 6.h,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submitQuestion,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentLight,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
              ),
              child: _isSubmitting
                  ? SizedBox(
                      height: 20.sp,
                      width: 20.sp,
                      child: const CircularProgressIndicator(
                        strokeWidth: 2.0,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      'Submit Question',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuideline(String text) {
    return Padding(
      padding: EdgeInsets.only(top: 0.5.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.check_circle,
            size: 14.sp,
            color: Theme.of(context).colorScheme.primary,
          ),
          SizedBox(width: 2.w),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12.sp,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
