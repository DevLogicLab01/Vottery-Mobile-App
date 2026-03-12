import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:google_fonts/google_fonts.dart' as google_fonts;
import 'dart:async';

import '../../../core/app_export.dart';
import '../../../services/mcq_service.dart';
import '../../../theme/app_theme.dart';

/// MCQ Answering Widget for vote casting
class MCQAnsweringWidget extends StatefulWidget {
  final String electionId;
  final Function(bool passed, int score) onCompleted;

  const MCQAnsweringWidget({
    super.key,
    required this.electionId,
    required this.onCompleted,
  });

  @override
  State<MCQAnsweringWidget> createState() => _MCQAnsweringWidgetState();
}

class _MCQAnsweringWidgetState extends State<MCQAnsweringWidget> {
  final MCQService _mcqService = MCQService.instance;

  List<Map<String, dynamic>> _questions = [];
  final Map<String, int> _selectedAnswers = {};
  final Map<String, String> _freeTextAnswers = {};
  bool _isLoading = true;
  bool _isSubmitting = false;
  bool _showResults = false;
  Map<String, dynamic>? _scoreResult;
  int _currentAttempt = 1;
  final int _maxAttempts = 3;
  final int _passingScore = 70;

  // Live question injection
  StreamSubscription<List<Map<String, dynamic>>>? _liveQuestionsSubscription;
  bool _hasNewLiveQuestion = false;

  @override
  void initState() {
    super.initState();
    _loadMCQData();
    _subscribToLiveQuestions();
  }

  @override
  void dispose() {
    _liveQuestionsSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadMCQData() async {
    setState(() => _isLoading = true);

    final questions = await _mcqService.getMCQQuestions(widget.electionId);
    final attempts = await _mcqService.getVoterAttempts(widget.electionId);

    setState(() {
      _questions = questions;
      _currentAttempt = attempts.length + 1;
      _isLoading = false;
    });
  }

  void _subscribToLiveQuestions() {
    _liveQuestionsSubscription = _mcqService
        .streamLiveQuestions(widget.electionId)
        .listen((questions) {
          if (questions.length > _questions.length) {
            setState(() {
              _questions = questions;
              _hasNewLiveQuestion = true;
            });

            // Show notification
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    Icon(Icons.new_releases, color: Colors.white),
                    SizedBox(width: 2.w),
                    Expanded(
                      child: Text(
                        'New question added! Scroll down to answer.',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                backgroundColor: AppTheme.accentLight,
                duration: const Duration(seconds: 5),
                action: SnackBarAction(
                  label: 'View',
                  textColor: Colors.white,
                  onPressed: () {
                    // Scroll to bottom to show new question
                  },
                ),
              ),
            );

            // Reset new question flag after 3 seconds
            Future.delayed(const Duration(seconds: 3), () {
              if (mounted) {
                setState(() => _hasNewLiveQuestion = false);
              }
            });
          }
        });
  }

  Future<void> _submitAnswers() async {
    // Check if all required questions are answered
    for (var question in _questions) {
      final questionId = question['id'];
      final questionType = question['question_type'] ?? 'multiple_choice';
      final isRequired = question['is_required'] ?? true;

      if (isRequired) {
        if (questionType == 'multiple_choice' &&
            !_selectedAnswers.containsKey(questionId)) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Please answer all required questions'),
              backgroundColor: AppTheme.errorLight,
            ),
          );
          return;
        }
        if (questionType == 'free_text' &&
            (!_freeTextAnswers.containsKey(questionId) ||
                _freeTextAnswers[questionId]!.trim().isEmpty)) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Please answer all required questions'),
              backgroundColor: AppTheme.errorLight,
            ),
          );
          return;
        }
      }
    }

    setState(() => _isSubmitting = true);

    // Submit multiple choice answers
    final mcAnswers = _questions
        .where(
          (q) => (q['question_type'] ?? 'multiple_choice') == 'multiple_choice',
        )
        .where((q) => _selectedAnswers.containsKey(q['id']))
        .map((question) {
          final questionId = question['id'];
          final selectedIndex = _selectedAnswers[questionId]!;
          final correctIndex = question['correct_answer_index'] as int;

          return {
            'mcq_id': questionId,
            'selected_answer_index': selectedIndex,
            'is_correct': selectedIndex == correctIndex,
          };
        })
        .toList();

    Map<String, dynamic> result = {};
    if (mcAnswers.isNotEmpty) {
      result = await _mcqService.submitMCQAnswers(
        electionId: widget.electionId,
        answers: mcAnswers,
        attemptNumber: _currentAttempt,
      );
    }

    // Submit free-text answers
    for (var question in _questions) {
      if ((question['question_type'] ?? 'multiple_choice') == 'free_text') {
        final questionId = question['id'];
        if (_freeTextAnswers.containsKey(questionId)) {
          await _mcqService.submitFreeTextAnswer(
            mcqId: questionId,
            electionId: widget.electionId,
            answerText: _freeTextAnswers[questionId]!,
          );
        }
      }
    }

    setState(() {
      _isSubmitting = false;
      _showResults = true;
      _scoreResult = result;
    });

    final passed = result['passed'] as bool? ?? true;
    final scorePercentage =
        (result['score_percentage'] as num?)?.toInt() ?? 100;

    if (passed) {
      widget.onCompleted(true, scorePercentage);
    } else if (_currentAttempt >= _maxAttempts) {
      widget.onCompleted(false, scorePercentage);
    }
  }

  void _retryMCQ() {
    setState(() {
      _selectedAnswers.clear();
      _freeTextAnswers.clear();
      _showResults = false;
      _scoreResult = null;
      _currentAttempt++;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (_showResults && _scoreResult != null) {
      return _buildResultsView();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(),
        if (_hasNewLiveQuestion) _buildNewQuestionBanner(),
        SizedBox(height: 2.h),
        Expanded(
          child: ListView.builder(
            itemCount: _questions.length,
            itemBuilder: (context, index) {
              return _buildQuestionCard(index, _questions[index]);
            },
          ),
        ),
        SizedBox(height: 2.h),
        _buildSubmitButton(),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: AppTheme.accentLight.withAlpha(26),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.quiz, color: AppTheme.accentLight, size: 6.w),
              SizedBox(width: 2.w),
              Expanded(
                child: Text(
                  'Answer MCQ Questions',
                  style: google_fonts.GoogleFonts.inter(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryLight,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Text(
            'Attempt $_currentAttempt of $_maxAttempts • Passing Score: $_passingScore%',
            style: google_fonts.GoogleFonts.inter(
              fontSize: 11.sp,
              color: AppTheme.textSecondaryLight,
            ),
          ),
          SizedBox(height: 0.5.h),
          LinearProgressIndicator(
            value: _selectedAnswers.length / _questions.length,
            backgroundColor: Colors.grey.shade300,
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accentLight),
          ),
          SizedBox(height: 0.5.h),
          Text(
            '${_selectedAnswers.length} of ${_questions.length} answered',
            style: google_fonts.GoogleFonts.inter(
              fontSize: 10.sp,
              color: AppTheme.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(int index, Map<String, dynamic> question) {
    final questionId = question['id'];
    final questionType = question['question_type'] ?? 'multiple_choice';

    return Card(
      margin: EdgeInsets.only(bottom: 2.h),
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(2.w),
                  decoration: BoxDecoration(
                    color: AppTheme.accentLight.withAlpha(26),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Text(
                    'Q${index + 1}',
                    style: google_fonts.GoogleFonts.inter(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.accentLight,
                    ),
                  ),
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: Text(
                    question['question_text'] ?? '',
                    style: google_fonts.GoogleFonts.inter(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimaryLight,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            if (question['question_image_url'] != null) ...[
              SizedBox(height: 1.h),
              Container(
                height: 20.h,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8.0),
                  image: DecorationImage(
                    image: NetworkImage(question['question_image_url']),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ],
            SizedBox(height: 2.h),
            if (questionType == 'free_text') ...[
              TextField(
                decoration: InputDecoration(
                  labelText: 'Your Answer',
                  hintText: 'Type your answer here...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                maxLines: 5,
                maxLength: question['character_limit'] ?? 500,
                onChanged: (value) {
                  setState(() {
                    _freeTextAnswers[questionId] = value;
                  });
                },
              ),
            ] else ...[
              ...List.generate((question['options'] as List).length, (
                optionIndex,
              ) {
                final option = (question['options'] as List)[optionIndex];
                final optionText = option is String
                    ? option
                    : (option['text'] ?? '');
                final optionImageUrl = option is Map
                    ? option['image_url']
                    : null;
                final isSelected = _selectedAnswers[questionId] == optionIndex;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedAnswers[questionId] = optionIndex;
                    });
                  },
                  child: Container(
                    margin: EdgeInsets.only(bottom: 1.h),
                    padding: EdgeInsets.all(3.w),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.accentLight.withAlpha(26)
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8.0),
                      border: Border.all(
                        color: isSelected
                            ? AppTheme.accentLight
                            : Colors.grey.shade300,
                        width: 2,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              isSelected
                                  ? Icons.radio_button_checked
                                  : Icons.radio_button_unchecked,
                              color: isSelected
                                  ? AppTheme.accentLight
                                  : Colors.grey,
                              size: 5.w,
                            ),
                            SizedBox(width: 2.w),
                            Expanded(
                              child: Text(
                                optionText,
                                style: google_fonts.GoogleFonts.inter(
                                  fontSize: 12.sp,
                                  color: isSelected
                                      ? AppTheme.accentLight
                                      : AppTheme.textPrimaryLight,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (optionImageUrl != null) ...[
                          SizedBox(height: 1.h),
                          Container(
                            height: 15.h,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8.0),
                              image: DecorationImage(
                                image: NetworkImage(optionImageUrl),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return ElevatedButton(
      onPressed: _isSubmitting ? null : _submitAnswers,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.accentLight,
        foregroundColor: Colors.white,
        minimumSize: Size(double.infinity, 6.h),
        disabledBackgroundColor: Colors.grey.shade400,
      ),
      child: _isSubmitting
          ? CircularProgressIndicator(color: Colors.white)
          : Text(
              'Submit Answers',
              style: google_fonts.GoogleFonts.inter(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
    );
  }

  Widget _buildResultsView() {
    final passed = _scoreResult!['passed'] as bool;
    final scorePercentage = (_scoreResult!['score_percentage'] as num).toInt();
    final correctAnswers = _scoreResult!['correct_answers'] as int;
    final totalQuestions = _scoreResult!['total_questions'] as int;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            passed ? Icons.check_circle : Icons.cancel,
            color: passed ? Colors.green : Colors.red,
            size: 20.w,
          ),
          SizedBox(height: 2.h),
          Text(
            passed ? 'Congratulations!' : 'Not Passed',
            style: google_fonts.GoogleFonts.inter(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: passed ? Colors.green : Colors.red,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            'Score: $scorePercentage%',
            style: google_fonts.GoogleFonts.inter(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          SizedBox(height: 0.5.h),
          Text(
            '$correctAnswers out of $totalQuestions correct',
            style: google_fonts.GoogleFonts.inter(
              fontSize: 12.sp,
              color: AppTheme.textSecondaryLight,
            ),
          ),
          SizedBox(height: 3.h),
          if (!passed && _currentAttempt < _maxAttempts)
            ElevatedButton(
              onPressed: _retryMCQ,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentLight,
                foregroundColor: Colors.white,
                minimumSize: Size(60.w, 6.h),
              ),
              child: Text('Retry MCQ'),
            ),
        ],
      ),
    );
  }

  Widget _buildNewQuestionBanner() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: AppTheme.accentLight.withAlpha(26),
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: AppTheme.accentLight, width: 2),
      ),
      child: Row(
        children: [
          Icon(Icons.new_releases, color: AppTheme.accentLight, size: 6.w),
          SizedBox(width: 2.w),
          Expanded(
            child: Text(
              'New question(s) added during voting!',
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: FontWeight.w600,
                color: AppTheme.accentLight,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
