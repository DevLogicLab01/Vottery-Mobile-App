import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../theme/app_theme.dart';

class TextQuestionConfigWidget extends StatefulWidget {
  final String? electionId;
  final VoidCallback? onConfigUpdated;

  const TextQuestionConfigWidget({
    super.key,
    this.electionId,
    this.onConfigUpdated,
  });

  @override
  State<TextQuestionConfigWidget> createState() =>
      _TextQuestionConfigWidgetState();
}

class _TextQuestionConfigWidgetState extends State<TextQuestionConfigWidget> {
  String _selectedQuestionType = 'free_text';
  int _characterLimit = 500;
  final TextEditingController _questionController = TextEditingController();

  @override
  void dispose() {
    _questionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.electionId == null) {
      return Center(
        child: Text(
          'Please select an election first',
          style: TextStyle(fontSize: 13.sp, color: Colors.grey),
        ),
      );
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildQuestionTypeSelector(),
          SizedBox(height: 2.h),
          _buildQuestionInput(),
          SizedBox(height: 2.h),
          _buildCharacterLimitSelector(),
          SizedBox(height: 2.h),
          _buildPreview(),
          SizedBox(height: 3.h),
          _buildSaveButton(),
        ],
      ),
    );
  }

  Widget _buildQuestionTypeSelector() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Question Type',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryLight,
            ),
          ),
          SizedBox(height: 1.h),
          Row(
            children: [
              Expanded(
                child: RadioListTile<String>(
                  title: Text(
                    'Multiple Choice',
                    style: TextStyle(fontSize: 12.sp),
                  ),
                  value: 'multiple_choice',
                  groupValue: _selectedQuestionType,
                  onChanged: (value) {
                    setState(() => _selectedQuestionType = value!);
                  },
                ),
              ),
              Expanded(
                child: RadioListTile<String>(
                  title: Text('Free Text', style: TextStyle(fontSize: 12.sp)),
                  value: 'free_text',
                  groupValue: _selectedQuestionType,
                  onChanged: (value) {
                    setState(() => _selectedQuestionType = value!);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionInput() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Question Text',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryLight,
            ),
          ),
          SizedBox(height: 1.h),
          TextField(
            controller: _questionController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Enter your question here...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCharacterLimitSelector() {
    if (_selectedQuestionType != 'free_text') return SizedBox.shrink();

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Character Limit',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryLight,
            ),
          ),
          SizedBox(height: 1.h),
          Wrap(
            spacing: 2.w,
            children: [
              _buildLimitChip('Short Answer', 50),
              _buildLimitChip('Medium Response', 500),
              _buildLimitChip('Essay Format', 2000),
            ],
          ),
          SizedBox(height: 1.h),
          Text(
            'Selected: $_characterLimit characters',
            style: TextStyle(fontSize: 11.sp, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildLimitChip(String label, int limit) {
    final isSelected = _characterLimit == limit;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() => _characterLimit = limit);
        }
      },
      selectedColor: AppTheme.accentLight,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black87,
        fontSize: 11.sp,
      ),
    );
  }

  Widget _buildPreview() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.visibility, size: 5.w, color: AppTheme.primaryLight),
              SizedBox(width: 2.w),
              Text(
                'Preview',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryLight,
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Text(
            _questionController.text.isEmpty
                ? 'Your question will appear here...'
                : _questionController.text,
            style: TextStyle(fontSize: 12.sp),
          ),
          if (_selectedQuestionType == 'free_text') ...[
            SizedBox(height: 1.h),
            TextField(
              enabled: false,
              maxLines: 3,
              decoration: InputDecoration(
                hintText:
                    'Voter will type their answer here (max $_characterLimit chars)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return ElevatedButton(
      onPressed: () {
        // Save question configuration
        widget.onConfigUpdated?.call();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Question configuration saved')));
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.accentLight,
        minimumSize: Size(double.infinity, 6.h),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      ),
      child: Text(
        'Save Question',
        style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
      ),
    );
  }
}
