import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../../../services/claude_faq_service.dart';
import '../../../services/auth_service.dart';

class FAQBotTabWidget extends StatefulWidget {
  const FAQBotTabWidget({super.key});

  @override
  State<FAQBotTabWidget> createState() => _FAQBotTabWidgetState();
}

class _FAQBotTabWidgetState extends State<FAQBotTabWidget> {
  final ClaudeFAQService _claudeService = ClaudeFAQService.instance;
  final _auth = AuthService.instance;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<Map<String, dynamic>> _messages = [];
  bool _isTyping = false;

  final List<String> _suggestedQuestions = [
    'How do I withdraw earnings?',
    'What are VP?',
    'How to create an election?',
    'Why is my content flagged?',
    'How do I verify my account?',
    'How to increase my creator tier?',
  ];

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage(String message) async {
    if (message.trim().isEmpty) return;

    setState(() {
      _messages.add({
        'isUser': true,
        'message': message,
        'timestamp': DateTime.now(),
      });
      _isTyping = true;
    });

    _messageController.clear();
    _scrollToBottom();

    try {
      final response = await _claudeService.askQuestion(
        question: message,
        userId: _auth.currentUser?.id,
      );

      setState(() {
        _messages.add({
          'isUser': false,
          'message': response['answer'],
          'hasUncertainty': response['hasUncertainty'],
          'relatedGuides': response['relatedGuides'],
          'quickActions': response['quickActions'],
          'timestamp': DateTime.now(),
        });
        _isTyping = false;
      });

      _scrollToBottom();
    } catch (e) {
      setState(() {
        _messages.add({
          'isUser': false,
          'message':
              'I apologize, but I encountered an error. Please try again or create a support ticket.',
          'timestamp': DateTime.now(),
        });
        _isTyping = false;
      });
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _clearConversation() {
    setState(() => _messages.clear());
    _claudeService.clearConversationHistory(
      _auth.currentUser?.id ?? 'anonymous',
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        // Suggested questions (show when no messages)
        if (_messages.isEmpty)
          Container(
            padding: EdgeInsets.all(4.w),
            color: theme.colorScheme.surface,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Suggested Questions',
                  style: GoogleFonts.inter(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 2.h),
                Wrap(
                  spacing: 2.w,
                  runSpacing: 1.h,
                  children: _suggestedQuestions.map((question) {
                    return ActionChip(
                      label: Text(
                        question,
                        style: GoogleFonts.inter(fontSize: 12.sp),
                      ),
                      onPressed: () => _sendMessage(question),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

        // Clear button (show when has messages)
        if (_messages.isNotEmpty)
          Container(
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: _clearConversation,
                  icon: const Icon(Icons.refresh),
                  label: Text(
                    'Clear Chat',
                    style: GoogleFonts.inter(fontSize: 12.sp),
                  ),
                ),
              ],
            ),
          ),

        // Messages
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: EdgeInsets.all(4.w),
            itemCount: _messages.length + (_isTyping ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == _messages.length && _isTyping) {
                return _buildTypingIndicator();
              }
              return _buildMessageBubble(_messages[index]);
            },
          ),
        ),

        // Input bar
        Container(
          padding: EdgeInsets.all(4.w),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10.0,
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
                    hintText: 'Ask me anything...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24.0),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 4.w,
                      vertical: 1.5.h,
                    ),
                  ),
                  maxLines: 5,
                  minLines: 1,
                  onSubmitted: _sendMessage,
                ),
              ),
              SizedBox(width: 2.w),
              IconButton(
                onPressed: () => _sendMessage(_messageController.text),
                icon: Icon(Icons.send, color: theme.colorScheme.primary),
                iconSize: 24.sp,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> message) {
    final theme = Theme.of(context);
    final isUser = message['isUser'] as bool;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(bottom: 2.h),
        constraints: BoxConstraints(maxWidth: 80.w),
        child: Column(
          crossAxisAlignment: isUser
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            if (!isUser)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 16.sp,
                    backgroundColor: theme.colorScheme.primary,
                    child: Icon(
                      Icons.smart_toy,
                      size: 16.sp,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: 2.w),
                  Text(
                    'AI Assistant',
                    style: GoogleFonts.inter(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            if (!isUser) SizedBox(height: 1.h),
            Container(
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: isUser
                    ? theme.colorScheme.primary
                    : theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: isUser
                  ? Text(
                      message['message'],
                      style: GoogleFonts.inter(
                        fontSize: 14.sp,
                        color: Colors.white,
                      ),
                    )
                  : MarkdownBody(
                      data: message['message'],
                      styleSheet: MarkdownStyleSheet(
                        p: GoogleFonts.inter(fontSize: 14.sp),
                        strong: GoogleFonts.inter(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
            ),
            SizedBox(height: 0.5.h),
            Text(
              _formatTime(message['timestamp']),
              style: GoogleFonts.inter(fontSize: 10.sp, color: Colors.grey),
            ),

            // Uncertainty warning
            if (!isUser && message['hasUncertainty'] == true)
              Container(
                margin: EdgeInsets.only(top: 1.h),
                padding: EdgeInsets.all(2.w),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(
                    color: Colors.orange.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.info_outline, size: 14.sp, color: Colors.orange),
                    SizedBox(width: 2.w),
                    Expanded(
                      child: Text(
                        'This answer may need verification. Create a ticket for detailed support.',
                        style: GoogleFonts.inter(
                          fontSize: 11.sp,
                          color: Colors.orange[800],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Quick actions
            if (!isUser &&
                message['quickActions'] != null &&
                (message['quickActions'] as List).isNotEmpty)
              Container(
                margin: EdgeInsets.only(top: 1.h),
                child: Wrap(
                  spacing: 2.w,
                  children: (message['quickActions'] as List).map((action) {
                    return ActionChip(
                      label: Text(
                        _getActionLabel(action),
                        style: GoogleFonts.inter(fontSize: 11.sp),
                      ),
                      onPressed: () => _handleQuickAction(action),
                    );
                  }).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    final theme = Theme.of(context);
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(bottom: 2.h),
        padding: EdgeInsets.all(3.w),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'AI is thinking',
              style: GoogleFonts.inter(fontSize: 14.sp, color: Colors.grey),
            ),
            SizedBox(width: 2.w),
            SizedBox(
              width: 16.sp,
              height: 16.sp,
              child: CircularProgressIndicator(
                strokeWidth: 2.0,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
    }
  }

  String _getActionLabel(String action) {
    switch (action) {
      case 'create_ticket':
        return 'Create Ticket';
      case 'view_guides':
        return 'View Guides';
      case 'open_wallet':
        return 'Open Wallet';
      case 'start_verification':
        return 'Start Verification';
      default:
        return action;
    }
  }

  void _handleQuickAction(String action) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Action: $action'),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
