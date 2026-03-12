import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:google_fonts/google_fonts.dart' as google_fonts;

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class VisualVotingPreviewWidget extends StatefulWidget {
  final List<Map<String, dynamic>> questions;

  const VisualVotingPreviewWidget({super.key, required this.questions});

  @override
  State<VisualVotingPreviewWidget> createState() =>
      _VisualVotingPreviewWidgetState();
}

class _VisualVotingPreviewWidgetState extends State<VisualVotingPreviewWidget> {
  int _currentQuestionIndex = 0;
  int? _selectedOptionIndex;
  String _viewMode = 'grid'; // 'grid' or 'carousel'

  @override
  Widget build(BuildContext context) {
    if (widget.questions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.preview, size: 20.w, color: Colors.grey),
            SizedBox(height: 2.h),
            Text(
              'No questions to preview',
              style: TextStyle(fontSize: 14.sp, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    final question = widget.questions[_currentQuestionIndex];

    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPreviewHeader(),
          SizedBox(height: 2.h),
          _buildQuestionCard(question),
          SizedBox(height: 2.h),
          _buildViewModeToggle(),
          SizedBox(height: 2.h),
          _viewMode == 'grid'
              ? _buildGridView(question)
              : _buildCarouselView(question),
          SizedBox(height: 2.h),
          _buildNavigationButtons(),
        ],
      ),
    );
  }

  Widget _buildPreviewHeader() {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: AppTheme.accentLight.withAlpha(26),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Row(
        children: [
          Icon(Icons.preview, color: AppTheme.accentLight, size: 6.w),
          SizedBox(width: 2.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Visual Voting Preview',
                  style: google_fonts.GoogleFonts.inter(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryLight,
                  ),
                ),
                Text(
                  'Question ${_currentQuestionIndex + 1} of ${widget.questions.length}',
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(Map<String, dynamic> question) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              question['question_text'] ?? 'Question text',
              style: google_fonts.GoogleFonts.inter(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimaryLight,
              ),
            ),
            SizedBox(height: 1.h),
            Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 2.w,
                    vertical: 0.5.h,
                  ),
                  decoration: BoxDecoration(
                    color: _getDifficultyColor(question['difficulty_level']),
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: Text(
                    question['difficulty_level']?.toString().toUpperCase() ??
                        'MEDIUM',
                    style: TextStyle(
                      fontSize: 9.sp,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(width: 2.w),
                if (question['is_required'] == true)
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 2.w,
                      vertical: 0.5.h,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: Text(
                      'REQUIRED',
                      style: TextStyle(
                        fontSize: 9.sp,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildViewModeToggle() {
    return Row(
      children: [
        Text(
          'View Mode:',
          style: google_fonts.GoogleFonts.inter(
            fontSize: 12.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(width: 2.w),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(
              value: 'grid',
              label: Text('Grid'),
              icon: Icon(Icons.grid_view),
            ),
            ButtonSegment(
              value: 'carousel',
              label: Text('Carousel'),
              icon: Icon(Icons.view_carousel),
            ),
          ],
          selected: {_viewMode},
          onSelectionChanged: (Set<String> newSelection) {
            setState(() {
              _viewMode = newSelection.first;
            });
          },
        ),
      ],
    );
  }

  Widget _buildGridView(Map<String, dynamic> question) {
    final options = List<Map<String, dynamic>>.from(question['options']);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 2.w,
        mainAxisSpacing: 2.h,
        childAspectRatio: 0.8,
      ),
      itemCount: options.length,
      itemBuilder: (context, index) {
        return _buildOptionCard(options[index], index);
      },
    );
  }

  Widget _buildCarouselView(Map<String, dynamic> question) {
    final options = List<Map<String, dynamic>>.from(question['options']);

    return SizedBox(
      height: 40.h,
      child: PageView.builder(
        itemCount: options.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: 2.w),
            child: _buildOptionCard(options[index], index),
          );
        },
      ),
    );
  }

  Widget _buildOptionCard(Map<String, dynamic> option, int index) {
    final isSelected = _selectedOptionIndex == index;
    final imageUrl = option['image_url'];
    final hasImage = imageUrl != null && imageUrl.toString().isNotEmpty;

    return GestureDetector(
      onTap: () => setState(() => _selectedOptionIndex = index),
      child: Card(
        elevation: isSelected ? 4 : 2,
        color: isSelected ? AppTheme.accentLight.withAlpha(26) : Colors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (hasImage)
              Expanded(
                flex: 3,
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12.0),
                  ),
                  child: kIsWeb
                      ? Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey.shade200,
                              child: Icon(Icons.broken_image, size: 10.w),
                            );
                          },
                        )
                      : Image.file(
                          File(imageUrl),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey.shade200,
                              child: Icon(Icons.broken_image, size: 10.w),
                            );
                          },
                        ),
                ),
              )
            else
              Expanded(
                flex: 3,
                child: Container(
                  color: Colors.grey.shade200,
                  child: Icon(Icons.image, size: 15.w, color: Colors.grey),
                ),
              ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: EdgeInsets.all(2.w),
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
                            option['text'] ?? 'Option ${index + 1}',
                            style: google_fonts.GoogleFonts.inter(
                              fontSize: 11.sp,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                              color: isSelected
                                  ? AppTheme.accentLight
                                  : AppTheme.textPrimaryLight,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _currentQuestionIndex > 0
                ? () => setState(() {
                    _currentQuestionIndex--;
                    _selectedOptionIndex = null;
                  })
                : null,
            icon: Icon(Icons.arrow_back, size: 5.w),
            label: Text('Previous'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryLight,
              foregroundColor: Colors.white,
              minimumSize: Size(0, 6.h),
            ),
          ),
        ),
        SizedBox(width: 2.w),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _currentQuestionIndex < widget.questions.length - 1
                ? () => setState(() {
                    _currentQuestionIndex++;
                    _selectedOptionIndex = null;
                  })
                : null,
            icon: Icon(Icons.arrow_forward, size: 5.w),
            label: Text('Next'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryLight,
              foregroundColor: Colors.white,
              minimumSize: Size(0, 6.h),
            ),
          ),
        ),
      ],
    );
  }

  Color _getDifficultyColor(String? difficulty) {
    switch (difficulty) {
      case 'easy':
        return Colors.green;
      case 'hard':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }
}
