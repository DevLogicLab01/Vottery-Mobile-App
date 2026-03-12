import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../../theme/app_theme.dart';

class CoachingChatWidget extends StatefulWidget {
  final Map<String, dynamic> coachingData;
  final Function(String) onSendMessage;

  const CoachingChatWidget({
    super.key,
    required this.coachingData,
    required this.onSendMessage,
  });

  @override
  State<CoachingChatWidget> createState() => _CoachingChatWidgetState();
}

class _CoachingChatWidgetState extends State<CoachingChatWidget> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSending = false;

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final conversationHistory =
        widget.coachingData['conversation_history'] as List? ?? [];

    return Column(
      children: [
        // Suggested questions
        if (conversationHistory.isEmpty) _buildSuggestedQuestions(theme),

        // Chat messages
        Expanded(
          child: conversationHistory.isEmpty
              ? _buildEmptyState(theme)
              : ListView.builder(
                  controller: _scrollController,
                  padding: EdgeInsets.all(4.w),
                  itemCount: conversationHistory.length,
                  itemBuilder: (context, index) {
                    final message = conversationHistory[index];
                    return _buildMessageBubble(theme, message);
                  },
                ),
        ),

        // Input field
        _buildInputField(theme),
      ],
    );
  }

  Widget _buildSuggestedQuestions(ThemeData theme) {
    final suggestions = [
      'How can I get to Platinum tier faster?',
      'What\'s the best pricing strategy for my services?',
      'How do I increase my election engagement?',
      'What categories should I focus on?',
    ];

    return Container(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Suggested Questions',
            style: GoogleFonts.inter(
              fontSize: 12.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 1.h),
          Wrap(
            spacing: 2.w,
            runSpacing: 1.h,
            children: suggestions.map((question) {
              return InkWell(
                onTap: () => _sendMessage(question),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withAlpha(26),
                    borderRadius: BorderRadius.circular(20.0),
                    border: Border.all(
                      color: AppTheme.primaryColor.withAlpha(77),
                    ),
                  ),
                  child: Text(
                    question,
                    style: GoogleFonts.inter(
                      fontSize: 11.sp,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 20.w,
            color: theme.textTheme.bodySmall?.color,
          ),
          SizedBox(height: 2.h),
          Text(
            'Ask your revenue coach',
            style: GoogleFonts.inter(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 1.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 10.w),
            child: Text(
              'Get personalized advice on growing your earnings and reaching your goals',
              style: GoogleFonts.inter(
                fontSize: 12.sp,
                color: theme.textTheme.bodySmall?.color,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ThemeData theme, Map<String, dynamic> message) {
    final isUser = message['role'] == 'user';
    final content = message['content'] ?? '';
    final timestamp = message['timestamp'] as String?;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(bottom: 2.h),
        constraints: BoxConstraints(maxWidth: 75.w),
        child: Column(
          crossAxisAlignment: isUser
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: isUser ? AppTheme.primaryColor : theme.cardColor,
                borderRadius: BorderRadius.circular(12.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(13),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                content,
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  color: isUser
                      ? Colors.white
                      : theme.textTheme.bodyMedium?.color,
                ),
              ),
            ),
            if (timestamp != null) ...[
              SizedBox(height: 0.5.h),
              Text(
                _formatTimestamp(timestamp),
                style: GoogleFonts.inter(
                  fontSize: 10.sp,
                  color: theme.textTheme.bodySmall?.color,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInputField(ThemeData theme) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Ask your coach...',
                hintStyle: GoogleFonts.inter(
                  fontSize: 12.sp,
                  color: theme.textTheme.bodySmall?.color,
                ),
                filled: true,
                fillColor: theme.scaffoldBackgroundColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25.0),
                  borderSide: BorderSide.none,
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 4.w,
                  vertical: 1.5.h,
                ),
              ),
              style: GoogleFonts.inter(fontSize: 12.sp),
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(_messageController.text),
            ),
          ),
          SizedBox(width: 2.w),
          Container(
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: _isSending
                  ? SizedBox(
                      width: 5.w,
                      height: 5.w,
                      child: const CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.send, color: Colors.white),
              onPressed: _isSending
                  ? null
                  : () => _sendMessage(_messageController.text),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sendMessage(String message) async {
    if (message.trim().isEmpty || _isSending) return;

    setState(() => _isSending = true);
    _messageController.clear();

    try {
      await widget.onSendMessage(message);

      // Scroll to bottom
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  String _formatTimestamp(String timestamp) {
    try {
      final dt = DateTime.parse(timestamp);
      final now = DateTime.now();
      final diff = now.difference(dt);

      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inHours < 1) return '${diff.inMinutes}m ago';
      if (diff.inDays < 1) return '${diff.inHours}h ago';
      return '${diff.inDays}d ago';
    } catch (e) {
      return '';
    }
  }
}
