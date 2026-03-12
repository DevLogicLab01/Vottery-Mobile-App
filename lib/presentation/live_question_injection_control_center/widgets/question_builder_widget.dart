import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sizer/sizer.dart';
import 'package:google_fonts/google_fonts.dart' as google_fonts;

import '../../../core/app_export.dart';
import '../../../services/mcq_service.dart';
import '../../../theme/app_theme.dart';

class QuestionBuilderWidget extends StatefulWidget {
  final String electionId;
  final VoidCallback onQuestionCreated;

  const QuestionBuilderWidget({
    super.key,
    required this.electionId,
    required this.onQuestionCreated,
  });

  @override
  State<QuestionBuilderWidget> createState() => _QuestionBuilderWidgetState();
}

class _QuestionBuilderWidgetState extends State<QuestionBuilderWidget> {
  final MCQService _mcqService = MCQService.instance;
  final ImagePicker _imagePicker = ImagePicker();
  final TextEditingController _questionController = TextEditingController();
  final List<TextEditingController> _optionControllers = [
    TextEditingController(),
    TextEditingController(),
  ];

  int _correctAnswerIndex = 0;
  String _difficultyLevel = 'medium';
  String _injectionPosition = 'end';
  bool _isCreating = false;
  String? _questionImageUrl;

  @override
  void dispose() {
    _questionController.dispose();
    for (var controller in _optionControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addOption() {
    if (_optionControllers.length < 6) {
      setState(() => _optionControllers.add(TextEditingController()));
    }
  }

  void _removeOption(int index) {
    if (_optionControllers.length > 2) {
      setState(() {
        _optionControllers[index].dispose();
        _optionControllers.removeAt(index);
        if (_correctAnswerIndex >= _optionControllers.length) {
          _correctAnswerIndex = _optionControllers.length - 1;
        }
      });
    }
  }

  Future<void> _pickQuestionImage() async {
    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      maxHeight: 1080,
      imageQuality: 85,
    );

    if (image != null) {
      setState(() => _questionImageUrl = image.path);
    }
  }

  Future<void> _createQuestion() async {
    if (_questionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter question text')),
      );
      return;
    }

    for (var controller in _optionControllers) {
      if (controller.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill all options')),
        );
        return;
      }
    }

    setState(() => _isCreating = true);

    final options = _optionControllers
        .map((c) => {'text': c.text.trim(), 'image_url': null})
        .toList();

    final injectionId = await _mcqService.createLiveQuestionInjection(
      electionId: widget.electionId,
      questionText: _questionController.text.trim(),
      options: options,
      correctAnswerIndex: _correctAnswerIndex,
      questionImageUrl: _questionImageUrl,
      difficultyLevel: _difficultyLevel,
      injectionPosition: _injectionPosition,
    );

    setState(() => _isCreating = false);

    if (injectionId != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Question added to injection queue'),
          backgroundColor: Colors.green,
        ),
      );
      _clearForm();
      widget.onQuestionCreated();
    }
  }

  void _clearForm() {
    _questionController.clear();
    for (var controller in _optionControllers) {
      controller.clear();
    }
    setState(() {
      _correctAnswerIndex = 0;
      _questionImageUrl = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Rapid MCQ Creation',
            style: google_fonts.GoogleFonts.inter(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryLight,
            ),
          ),
          SizedBox(height: 2.h),
          TextField(
            controller: _questionController,
            decoration: InputDecoration(
              labelText: 'Question Text',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
              prefixIcon: const Icon(Icons.question_answer),
            ),
            maxLines: 3,
          ),
          SizedBox(height: 2.h),
          if (_questionImageUrl != null)
            Container(
              height: 20.h,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8.0),
                image: DecorationImage(
                  image: NetworkImage(_questionImageUrl!),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          SizedBox(height: 1.h),
          OutlinedButton.icon(
            onPressed: _pickQuestionImage,
            icon: const Icon(Icons.image),
            label: Text(
              _questionImageUrl == null ? 'Add Image' : 'Change Image',
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            'Options',
            style: google_fonts.GoogleFonts.inter(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 1.h),
          ..._optionControllers.asMap().entries.map((entry) {
            final index = entry.key;
            final controller = entry.value;
            return Padding(
              padding: EdgeInsets.only(bottom: 2.h),
              child: Row(
                children: [
                  Radio<int>(
                    value: index,
                    groupValue: _correctAnswerIndex,
                    onChanged: (value) {
                      setState(() => _correctAnswerIndex = value!);
                    },
                  ),
                  Expanded(
                    child: TextField(
                      controller: controller,
                      decoration: InputDecoration(
                        labelText: 'Option ${index + 1}',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                    ),
                  ),
                  if (_optionControllers.length > 2)
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _removeOption(index),
                    ),
                ],
              ),
            );
          }),
          if (_optionControllers.length < 6)
            OutlinedButton.icon(
              onPressed: _addOption,
              icon: const Icon(Icons.add),
              label: const Text('Add Option'),
            ),
          SizedBox(height: 2.h),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _difficultyLevel,
                  decoration: InputDecoration(
                    labelText: 'Difficulty',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  items: ['easy', 'medium', 'hard'].map((level) {
                    return DropdownMenuItem(
                      value: level,
                      child: Text(level.toUpperCase()),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => _difficultyLevel = value!);
                  },
                ),
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _injectionPosition,
                  decoration: InputDecoration(
                    labelText: 'Position',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  items: ['beginning', 'middle', 'end'].map((pos) {
                    return DropdownMenuItem(
                      value: pos,
                      child: Text(pos.toUpperCase()),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => _injectionPosition = value!);
                  },
                ),
              ),
            ],
          ),
          SizedBox(height: 3.h),
          ElevatedButton(
            onPressed: _isCreating ? null : _createQuestion,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentLight,
              foregroundColor: Colors.white,
              minimumSize: Size(double.infinity, 6.h),
            ),
            child: _isCreating
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text('Add to Injection Queue'),
          ),
        ],
      ),
    );
  }
}
