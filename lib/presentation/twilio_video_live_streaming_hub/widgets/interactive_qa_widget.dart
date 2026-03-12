import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class InteractiveQAWidget extends StatefulWidget {
  final List<Map<String, dynamic>> messages;
  final Function(String) onAddMessage;

  const InteractiveQAWidget({
    super.key,
    required this.messages,
    required this.onAddMessage,
  });

  @override
  State<InteractiveQAWidget> createState() => _InteractiveQAWidgetState();
}

class _InteractiveQAWidgetState extends State<InteractiveQAWidget> {
  final TextEditingController _questionController = TextEditingController();

  @override
  void dispose() {
    _questionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: widget.messages.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: EdgeInsets.all(4.w),
                  itemCount: widget.messages.length,
                  itemBuilder: (context, index) {
                    return _buildQuestionCard(widget.messages[index]);
                  },
                ),
        ),
        _buildInputBar(),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.question_answer_outlined,
            size: 20.w,
            color: AppTheme.textSecondaryLight.withAlpha(128),
          ),
          SizedBox(height: 2.h),
          Text(
            'No questions yet',
            style: TextStyle(
              fontSize: 14.sp,
              color: AppTheme.textSecondaryLight,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            'Viewers can ask questions during the stream',
            style: TextStyle(
              fontSize: 11.sp,
              color: AppTheme.textSecondaryLight.withAlpha(179),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(Map<String, dynamic> message) {
    final answered = message['answered'] as bool;

    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: answered
              ? AppTheme.accentLight.withAlpha(128)
              : AppTheme.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.help_outline, size: 5.w, color: AppTheme.primaryLight),
              SizedBox(width: 2.w),
              Expanded(
                child: Text(
                  message['question'] as String,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimaryLight,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Row(
            children: [
              Text(
                _formatTime(message['timestamp'] as DateTime),
                style: TextStyle(
                  fontSize: 10.sp,
                  color: AppTheme.textSecondaryLight,
                ),
              ),
              const Spacer(),
              if (answered)
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 2.w,
                    vertical: 0.5.h,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.accentLight.withAlpha(26),
                    borderRadius: BorderRadius.circular(6.0),
                  ),
                  child: Text(
                    'Answered',
                    style: TextStyle(
                      fontSize: 9.sp,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.accentLight,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppTheme.borderLight)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _questionController,
              decoration: InputDecoration(
                hintText: 'Type a question...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: BorderSide(color: AppTheme.borderLight),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 4.w,
                  vertical: 1.5.h,
                ),
              ),
            ),
          ),
          SizedBox(width: 3.w),
          IconButton(
            onPressed: () {
              if (_questionController.text.isNotEmpty) {
                widget.onAddMessage(_questionController.text);
                _questionController.clear();
              }
            },
            icon: Icon(Icons.send, size: 6.w, color: AppTheme.primaryLight),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else {
      return '${difference.inHours}h ago';
    }
  }
}
