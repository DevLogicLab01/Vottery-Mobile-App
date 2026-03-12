import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart' as google_fonts;
import 'package:image_picker/image_picker.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/mcq_service.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/error_boundary_wrapper.dart';
import './widgets/image_gallery_export_widget.dart';
import './widgets/image_option_builder_widget.dart';
import './widgets/visual_voting_preview_widget.dart';

/// Enhanced MCQ Image Options Interface
/// Enables image upload per MCQ option for visual comparison voting
class EnhancedMcqImageOptionsInterface extends StatefulWidget {
  const EnhancedMcqImageOptionsInterface({super.key});

  @override
  State<EnhancedMcqImageOptionsInterface> createState() =>
      _EnhancedMcqImageOptionsInterfaceState();
}

class _EnhancedMcqImageOptionsInterfaceState
    extends State<EnhancedMcqImageOptionsInterface>
    with SingleTickerProviderStateMixin {
  final MCQService _mcqService = MCQService.instance;
  final ImagePicker _imagePicker = ImagePicker();

  late TabController _tabController;
  final bool _isLoading = false;
  bool _isSaving = false;

  // MCQ Question Data
  final List<Map<String, dynamic>> _questions = [];
  int _currentQuestionIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _addNewQuestion();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _addNewQuestion() {
    setState(() {
      _questions.add({
        'question_text': '',
        'options': [
          {'text': '', 'image_url': null, 'alt_text': ''},
          {'text': '', 'image_url': null, 'alt_text': ''},
        ],
        'correct_answer_index': 0,
        'difficulty_level': 'medium',
        'is_required': true,
      });
      _currentQuestionIndex = _questions.length - 1;
    });
  }

  void _removeQuestion(int index) {
    if (_questions.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('At least one question is required'),
          backgroundColor: AppTheme.errorLight,
        ),
      );
      return;
    }

    setState(() {
      _questions.removeAt(index);
      if (_currentQuestionIndex >= _questions.length) {
        _currentQuestionIndex = _questions.length - 1;
      }
    });
  }

  void _addOption(int questionIndex) {
    if (_questions[questionIndex]['options'].length >= 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Maximum 10 options allowed'),
          backgroundColor: AppTheme.errorLight,
        ),
      );
      return;
    }

    setState(() {
      _questions[questionIndex]['options'].add({
        'text': '',
        'image_url': null,
        'alt_text': '',
      });
    });
  }

  void _removeOption(int questionIndex, int optionIndex) {
    if (_questions[questionIndex]['options'].length <= 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('At least 2 options required'),
          backgroundColor: AppTheme.errorLight,
        ),
      );
      return;
    }

    setState(() {
      _questions[questionIndex]['options'].removeAt(optionIndex);
    });
  }

  Future<void> _pickImageForOption(int questionIndex, int optionIndex) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _questions[questionIndex]['options'][optionIndex]['image_url'] =
              image.path;
          if (_questions[questionIndex]['options'][optionIndex]['alt_text']
              .isEmpty) {
            _questions[questionIndex]['options'][optionIndex]['alt_text'] =
                'Option ${optionIndex + 1} image';
          }
        });
      }
    } catch (e) {
      debugPrint('Pick image error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image: $e'),
            backgroundColor: AppTheme.errorLight,
          ),
        );
      }
    }
  }

  Future<void> _saveQuestions() async {
    // Validate questions
    for (var question in _questions) {
      if (question['question_text'].toString().trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('All questions must have text'),
            backgroundColor: AppTheme.errorLight,
          ),
        );
        return;
      }

      for (var option in question['options']) {
        if (option['text'].toString().trim().isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('All options must have text'),
              backgroundColor: AppTheme.errorLight,
            ),
          );
          return;
        }
      }
    }

    setState(() => _isSaving = true);

    // In a real implementation, this would save to an election
    await Future.delayed(const Duration(seconds: 2));

    setState(() => _isSaving = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Questions saved successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ErrorBoundaryWrapper(
      screenName: 'EnhancedMcqImageOptionsInterface',
      onRetry: () => setState(() {}),
      child: Scaffold(
        backgroundColor: AppTheme.backgroundLight,
        appBar: CustomAppBar(
          leading: Padding(
            padding: EdgeInsets.only(left: 4.w),
            child: IconButton(
              icon: CustomIconWidget(
                iconName: 'arrow_back',
                size: 6.w,
                color: AppTheme.textPrimaryLight,
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          title: 'Image MCQ Builder',
          actions: [
            IconButton(
              icon: Icon(Icons.save, size: 6.w),
              onPressed: _isSaving ? null : _saveQuestions,
            ),
            SizedBox(width: 2.w),
          ],
        ),
        body: Column(
          children: [
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildQuestionBuilderTab(),
                  _buildVisualPreviewTab(),
                  _buildExportTab(),
                ],
              ),
            ),
          ],
        ),
        floatingActionButton: _tabController.index == 0
            ? FloatingActionButton(
                onPressed: _addNewQuestion,
                backgroundColor: AppTheme.accentLight,
                child: Icon(Icons.add, color: Colors.white),
              )
            : null,
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        labelColor: AppTheme.primaryLight,
        unselectedLabelColor: AppTheme.textSecondaryLight,
        indicatorColor: AppTheme.primaryLight,
        labelStyle: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w600),
        tabs: const [
          Tab(text: 'Question Builder'),
          Tab(text: 'Visual Preview'),
          Tab(text: 'Export Gallery'),
        ],
      ),
    );
  }

  Widget _buildQuestionBuilderTab() {
    if (_questions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.quiz, size: 20.w, color: Colors.grey),
            SizedBox(height: 2.h),
            Text(
              'No questions yet',
              style: TextStyle(fontSize: 14.sp, color: Colors.grey),
            ),
            SizedBox(height: 1.h),
            ElevatedButton.icon(
              onPressed: _addNewQuestion,
              icon: Icon(Icons.add),
              label: Text('Add Question'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentLight,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildQuestionSelector(),
          SizedBox(height: 2.h),
          _buildCurrentQuestionEditor(),
        ],
      ),
    );
  }

  Widget _buildQuestionSelector() {
    return SizedBox(
      height: 8.h,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _questions.length,
        itemBuilder: (context, index) {
          final isSelected = index == _currentQuestionIndex;
          return GestureDetector(
            onTap: () => setState(() => _currentQuestionIndex = index),
            child: Container(
              margin: EdgeInsets.only(right: 2.w),
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.accentLight : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(
                  color: isSelected
                      ? AppTheme.accentLight
                      : Colors.grey.shade300,
                  width: 2,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Q${index + 1}',
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : Colors.black,
                    ),
                  ),
                  SizedBox(height: 0.5.h),
                  Icon(
                    Icons.image,
                    size: 4.w,
                    color: isSelected ? Colors.white : Colors.grey,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCurrentQuestionEditor() {
    final question = _questions[_currentQuestionIndex];

    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Question ${_currentQuestionIndex + 1}',
                    style: google_fonts.GoogleFonts.inter(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryLight,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.delete, color: Colors.red, size: 6.w),
                  onPressed: () => _removeQuestion(_currentQuestionIndex),
                ),
              ],
            ),
            SizedBox(height: 2.h),
            TextField(
              decoration: InputDecoration(
                labelText: 'Question Text',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              maxLines: 2,
              controller: TextEditingController(
                text: question['question_text'],
              ),
              onChanged: (value) {
                setState(() {
                  _questions[_currentQuestionIndex]['question_text'] = value;
                });
              },
            ),
            SizedBox(height: 2.h),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: question['difficulty_level'],
                    decoration: InputDecoration(
                      labelText: 'Difficulty',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    items: [
                      DropdownMenuItem(value: 'easy', child: Text('Easy')),
                      DropdownMenuItem(value: 'medium', child: Text('Medium')),
                      DropdownMenuItem(value: 'hard', child: Text('Hard')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _questions[_currentQuestionIndex]['difficulty_level'] =
                            value;
                      });
                    },
                  ),
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: SwitchListTile(
                    title: Text('Required', style: TextStyle(fontSize: 11.sp)),
                    value: question['is_required'],
                    onChanged: (value) {
                      setState(() {
                        _questions[_currentQuestionIndex]['is_required'] =
                            value;
                      });
                    },
                  ),
                ),
              ],
            ),
            SizedBox(height: 2.h),
            Divider(),
            SizedBox(height: 1.h),
            Row(
              children: [
                Text(
                  'Options with Images',
                  style: google_fonts.GoogleFonts.inter(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Spacer(),
                TextButton.icon(
                  onPressed: () => _addOption(_currentQuestionIndex),
                  icon: Icon(Icons.add, size: 4.w),
                  label: Text('Add Option'),
                ),
              ],
            ),
            SizedBox(height: 1.h),
            ...List.generate(
              question['options'].length,
              (optionIndex) => ImageOptionBuilderWidget(
                optionIndex: optionIndex,
                option: question['options'][optionIndex],
                isCorrectAnswer:
                    question['correct_answer_index'] == optionIndex,
                onTextChanged: (value) {
                  setState(() {
                    _questions[_currentQuestionIndex]['options'][optionIndex]['text'] =
                        value;
                  });
                },
                onAltTextChanged: (value) {
                  setState(() {
                    _questions[_currentQuestionIndex]['options'][optionIndex]['alt_text'] =
                        value;
                  });
                },
                onImagePick: () =>
                    _pickImageForOption(_currentQuestionIndex, optionIndex),
                onRemove: () =>
                    _removeOption(_currentQuestionIndex, optionIndex),
                onSetCorrect: () {
                  setState(() {
                    _questions[_currentQuestionIndex]['correct_answer_index'] =
                        optionIndex;
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVisualPreviewTab() {
    return VisualVotingPreviewWidget(questions: _questions);
  }

  Widget _buildExportTab() {
    return ImageGalleryExportWidget(questions: _questions);
  }
}
