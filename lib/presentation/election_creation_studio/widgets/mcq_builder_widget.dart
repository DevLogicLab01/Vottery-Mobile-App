import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart' as google_fonts;
import 'package:image_picker/image_picker.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';
import './mcq_optimization_panel_widget.dart';

/// MCQ Builder Widget for election creation studio
class MCQBuilderWidget extends StatefulWidget {
  final bool requireMCQ;
  final Function(bool) onRequireMCQChanged;
  final int passingScore;
  final Function(int) onPassingScoreChanged;
  final int maxAttempts;
  final Function(int) onMaxAttemptsChanged;
  final List<Map<String, dynamic>> questions;
  final Function(List<Map<String, dynamic>>) onQuestionsChanged;

  const MCQBuilderWidget({
    super.key,
    required this.requireMCQ,
    required this.onRequireMCQChanged,
    required this.passingScore,
    required this.onPassingScoreChanged,
    required this.maxAttempts,
    required this.onMaxAttemptsChanged,
    required this.questions,
    required this.onQuestionsChanged,
  });

  @override
  State<MCQBuilderWidget> createState() => _MCQBuilderWidgetState();
}

class _MCQBuilderWidgetState extends State<MCQBuilderWidget> {
  final ImagePicker _imagePicker = ImagePicker();
  // Track which questions have dismissed optimization panels
  final Set<int> _dismissedOptimizations = {};
  // Mock accuracy rates for demo (in production, fetched from Supabase)
  final Map<int, double> _questionAccuracyRates = {};

  void _addQuestion() {
    final newQuestions = List<Map<String, dynamic>>.from(widget.questions);
    newQuestions.add({
      'question_text': '',
      'question_type': 'multiple_choice',
      'options': ['', ''],
      'correct_answer_index': 0,
      'question_image_url': null,
      'difficulty_level': 'medium',
      'is_required': true,
      'character_limit': 500,
    });
    widget.onQuestionsChanged(newQuestions);
  }

  void _removeQuestion(int index) {
    final newQuestions = List<Map<String, dynamic>>.from(widget.questions);
    newQuestions.removeAt(index);
    _dismissedOptimizations.remove(index);
    widget.onQuestionsChanged(newQuestions);
  }

  void _updateQuestion(int index, Map<String, dynamic> updates) {
    final newQuestions = List<Map<String, dynamic>>.from(widget.questions);
    newQuestions[index] = {...newQuestions[index], ...updates};
    widget.onQuestionsChanged(newQuestions);
  }

  void _addOption(int questionIndex) {
    final question = widget.questions[questionIndex];
    final options = List<String>.from(question['options']);
    if (options.length < 10) {
      options.add('');
      _updateQuestion(questionIndex, {'options': options});
    }
  }

  void _removeOption(int questionIndex, int optionIndex) {
    final question = widget.questions[questionIndex];
    final options = List<String>.from(question['options']);
    if (options.length > 2) {
      options.removeAt(optionIndex);
      _updateQuestion(questionIndex, {'options': options});
    }
  }

  bool _isLowPerforming(int index) {
    final accuracy = _questionAccuracyRates[index];
    return accuracy != null && accuracy < 0.6;
  }

  double _getAccuracyRate(int index) {
    return _questionAccuracyRates[index] ?? 0.45;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.backgroundLight,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.quiz, color: AppTheme.primaryLight, size: 6.w),
              SizedBox(width: 2.w),
              Expanded(
                child: Text(
                  'MCQ Requirement (Optional)',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryLight,
                  ),
                ),
              ),
              Switch(
                value: widget.requireMCQ,
                onChanged: widget.onRequireMCQChanged,
                activeThumbColor: AppTheme.accentLight,
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Text(
            widget.requireMCQ
                ? 'Voters must answer MCQ questions before voting'
                : 'MCQ is optional for this election',
            style: TextStyle(fontSize: 11.sp, color: Colors.grey.shade600),
          ),
          if (widget.requireMCQ) ...[
            SizedBox(height: 2.h),
            const Divider(),
            SizedBox(height: 2.h),
            _buildMCQSettings(),
            SizedBox(height: 2.h),
            _buildQuestionsList(),
            SizedBox(height: 2.h),
            ElevatedButton.icon(
              onPressed: _addQuestion,
              icon: Icon(Icons.add, size: 5.w),
              label: const Text('Add Question'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentLight,
                foregroundColor: Colors.white,
                minimumSize: Size(double.infinity, 6.h),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMCQSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'MCQ Settings',
          style: google_fonts.GoogleFonts.inter(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimaryLight,
          ),
        ),
        SizedBox(height: 1.h),
        Text(
          'Passing Score: ${widget.passingScore}%',
          style: google_fonts.GoogleFonts.inter(
            fontSize: 12.sp,
            color: AppTheme.textSecondaryLight,
          ),
        ),
        Slider(
          value: widget.passingScore.toDouble(),
          min: 0,
          max: 100,
          divisions: 20,
          label: '${widget.passingScore}%',
          onChanged: (value) => widget.onPassingScoreChanged(value.toInt()),
        ),
        SizedBox(height: 1.h),
        Text(
          'Maximum Attempts: ${widget.maxAttempts}',
          style: google_fonts.GoogleFonts.inter(
            fontSize: 12.sp,
            color: AppTheme.textSecondaryLight,
          ),
        ),
        Slider(
          value: widget.maxAttempts.toDouble(),
          min: 1,
          max: 5,
          divisions: 4,
          label: '${widget.maxAttempts}',
          onChanged: (value) => widget.onMaxAttemptsChanged(value.toInt()),
        ),
        if (widget.passingScore == 0)
          Container(
            padding: EdgeInsets.all(2.w),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue, size: 5.w),
                SizedBox(width: 2.w),
                Expanded(
                  child: Text(
                    'Passing score set to 0% - voters can skip MCQ',
                    style: TextStyle(
                      fontSize: 10.sp,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildQuestionsList() {
    if (widget.questions.isEmpty) {
      return Container(
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8.0),
          border: Border.all(
            color: Colors.grey.shade300,
            style: BorderStyle.solid,
          ),
        ),
        child: Center(
          child: Text(
            'No questions added yet. Click "Add Question" to start.',
            style: TextStyle(fontSize: 11.sp, color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Column(
      children: widget.questions.asMap().entries.map((entry) {
        final index = entry.key;
        final question = entry.value;
        return _buildQuestionWithOptimization(index, question);
      }).toList(),
    );
  }

  Widget _buildQuestionWithOptimization(
    int index,
    Map<String, dynamic> question,
  ) {
    final showOptimization =
        _isLowPerforming(index) &&
        !_dismissedOptimizations.contains(index) &&
        question['question_type'] != 'free_text';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showOptimization)
          MCQOptimizationPanel(
            currentQuestion: question,
            questionIndex: index,
            accuracyRate: _getAccuracyRate(index),
            onApplySuggestion: () {
              setState(() {
                _dismissedOptimizations.add(index);
              });
            },
            onQuestionUpdated: (updatedQuestion) {
              _updateQuestion(index, updatedQuestion);
            },
            onDismiss: () {
              setState(() {
                _dismissedOptimizations.add(index);
              });
            },
          ),
        _buildQuestionCard(index, question),
      ],
    );
  }

  Widget _buildQuestionCard(int index, Map<String, dynamic> question) {
    final hasLowAccuracy = _isLowPerforming(index);
    final isDismissed = _dismissedOptimizations.contains(index);

    return Card(
      margin: EdgeInsets.only(bottom: 2.h),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
        side: hasLowAccuracy && !isDismissed
            ? BorderSide(color: Colors.orange.shade300)
            : BorderSide.none,
      ),
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Question ${index + 1}',
                  style: google_fonts.GoogleFonts.inter(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryLight,
                  ),
                ),
                if (hasLowAccuracy && !isDismissed) ...[
                  SizedBox(width: 2.w),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _dismissedOptimizations.remove(index);
                      });
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 1.5.w,
                        vertical: 0.3.h,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(4.0),
                      ),
                      child: Text(
                        '⚠️ Needs optimization',
                        style: TextStyle(
                          fontSize: 9.sp,
                          color: Colors.orange.shade800,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
                const Spacer(),
                // Refresh optimization button
                if (question['question_text']?.isNotEmpty == true &&
                    question['question_type'] != 'free_text')
                  IconButton(
                    icon: Icon(
                      Icons.auto_fix_high,
                      color: AppTheme.accentLight,
                      size: 5.w,
                    ),
                    tooltip: 'Get AI optimization suggestions',
                    onPressed: () {
                      setState(() {
                        // Simulate low accuracy to trigger optimization panel
                        _questionAccuracyRates[index] = 0.45;
                        _dismissedOptimizations.remove(index);
                      });
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                SizedBox(width: 2.w),
                IconButton(
                  icon: Icon(Icons.delete, color: Colors.red, size: 5.w),
                  onPressed: () => _removeQuestion(index),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            SizedBox(height: 1.h),
            TextField(
              decoration: InputDecoration(
                labelText: 'Question Text',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              maxLines: 2,
              controller: TextEditingController(
                text: question['question_text'] ?? '',
              ),
              onChanged: (value) {
                _updateQuestion(index, {'question_text': value});
              },
            ),
            SizedBox(height: 1.h),
            DropdownButtonFormField<String>(
              initialValue: question['question_type'] ?? 'multiple_choice',
              decoration: InputDecoration(
                labelText: 'Question Type',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'multiple_choice',
                  child: Text('Multiple Choice'),
                ),
                DropdownMenuItem(
                  value: 'free_text',
                  child: Text('Free Text (Open-Ended)'),
                ),
              ],
              onChanged: (value) {
                _updateQuestion(index, {'question_type': value});
              },
            ),
            SizedBox(height: 1.h),
            if (question['question_type'] == 'free_text') ...[
              DropdownButtonFormField<int>(
                initialValue: question['character_limit'] ?? 500,
                decoration: InputDecoration(
                  labelText: 'Character Limit',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                items: const [
                  DropdownMenuItem(value: 50, child: Text('50 characters')),
                  DropdownMenuItem(value: 500, child: Text('500 characters')),
                  DropdownMenuItem(value: 2000, child: Text('2000 characters')),
                ],
                onChanged: (value) {
                  _updateQuestion(index, {'character_limit': value});
                },
              ),
            ] else ...[
              SizedBox(height: 1.h),
              Text(
                'Options (with image support)',
                style: google_fonts.GoogleFonts.inter(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 1.h),
              ...List.generate(
                (question['options'] as List).length,
                (optionIndex) => _buildOptionField(
                  index,
                  optionIndex,
                  question['options'][optionIndex],
                ),
              ),
              SizedBox(height: 1.h),
              if ((question['options'] as List).length < 10)
                OutlinedButton.icon(
                  onPressed: () => _addOption(index),
                  icon: Icon(Icons.add, size: 4.w),
                  label: const Text('Add Option'),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOptionField(int questionIndex, int optionIndex, dynamic option) {
    final optionText = option is String ? option : (option['text'] ?? '');
    final optionImageUrl = option is Map ? option['image_url'] : null;

    return Padding(
      padding: EdgeInsets.only(bottom: 1.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Radio<int>(
                value: optionIndex,
                groupValue:
                    widget.questions[questionIndex]['correct_answer_index'],
                onChanged: (value) {
                  _updateQuestion(questionIndex, {
                    'correct_answer_index': value,
                  });
                },
              ),
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    labelText: 'Option ${optionIndex + 1}',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  controller: TextEditingController(text: optionText),
                  onChanged: (value) {
                    final options = List<dynamic>.from(
                      widget.questions[questionIndex]['options'],
                    );
                    if (options[optionIndex] is String) {
                      options[optionIndex] = {
                        'text': value,
                        'image_url': null,
                        'alt_text': '',
                      };
                    } else {
                      options[optionIndex]['text'] = value;
                    }
                    _updateQuestion(questionIndex, {'options': options});
                  },
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.image,
                  color: optionImageUrl != null
                      ? AppTheme.accentLight
                      : Colors.grey,
                  size: 5.w,
                ),
                onPressed: () => _pickOptionImage(questionIndex, optionIndex),
              ),
              if ((widget.questions[questionIndex]['options'] as List).length >
                  2)
                IconButton(
                  icon: Icon(Icons.delete, color: Colors.red, size: 5.w),
                  onPressed: () => _removeOption(questionIndex, optionIndex),
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
    );
  }

  Future<void> _pickOptionImage(int questionIndex, int optionIndex) async {
    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      maxHeight: 1080,
      imageQuality: 85,
    );

    if (image != null) {
      final options = List<dynamic>.from(
        widget.questions[questionIndex]['options'],
      );
      if (options[optionIndex] is String) {
        options[optionIndex] = {
          'text': options[optionIndex],
          'image_url': image.path,
          'alt_text': 'Option ${optionIndex + 1} image',
        };
      } else {
        options[optionIndex]['image_url'] = image.path;
      }
      _updateQuestion(questionIndex, {'options': options});
    }
  }
}
