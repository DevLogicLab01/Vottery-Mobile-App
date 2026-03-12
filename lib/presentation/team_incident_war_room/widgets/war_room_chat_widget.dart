import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../../services/team_incident_war_room_service.dart';
import '../../../services/auth_service.dart';
import '../../../theme/app_theme.dart';

class WarRoomChatWidget extends StatefulWidget {
  final String roomId;

  const WarRoomChatWidget({super.key, required this.roomId});

  @override
  State<WarRoomChatWidget> createState() => _WarRoomChatWidgetState();
}

class _WarRoomChatWidgetState extends State<WarRoomChatWidget> {
  final _warRoomService = TeamIncidentWarRoomService.instance;
  final _authService = AuthService.instance;
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  List<Map<String, dynamic>> _messages = [];
  final bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    _subscribeToMessages();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _subscribeToMessages() {
    _warRoomService.getMessagesStream(widget.roomId).listen((messages) {
      setState(() {
        _messages = messages;
      });
      _scrollToBottom();
    });
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final messageText = _messageController.text;
    _messageController.clear();

    // Extract mentions (@username)
    final mentions = <String>[];
    final mentionRegex = RegExp(r'@(\w+)');
    final matches = mentionRegex.allMatches(messageText);
    for (final match in matches) {
      // In production, resolve username to user_id
      mentions.add(match.group(1)!);
    }

    await _warRoomService.sendMessage(
      roomId: widget.roomId,
      messageText: messageText,
      mentions: mentions.isNotEmpty ? mentions : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Messages list
        Expanded(
          child: _messages.isEmpty
              ? Center(
                  child: Text(
                    'No messages yet. Start the conversation!',
                    style: TextStyle(fontSize: 12.sp, color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  controller: _scrollController,
                  padding: EdgeInsets.all(2.w),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final message = _messages[index];
                    final isOwnMessage =
                        message['sender_id'] == _authService.currentUser?.id;

                    return _buildMessageBubble(message, isOwnMessage);
                  },
                ),
        ),
        // Typing indicator
        if (_isTyping)
          Container(
            padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
            child: Row(
              children: [
                Text(
                  'Someone is typing...',
                  style: TextStyle(fontSize: 11.sp, color: Colors.grey),
                ),
              ],
            ),
          ),
        // Message input
        Container(
          padding: EdgeInsets.all(2.w),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(13),
                blurRadius: 10.0,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Attachment button
              IconButton(
                icon: const Icon(Icons.attach_file),
                onPressed: () {
                  // TODO: Implement file attachment
                },
              ),
              // Message input field
              Expanded(
                child: TextField(
                  controller: _messageController,
                  decoration: InputDecoration(
                    hintText: 'Type a message... (use @mention)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25.0),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 4.w,
                      vertical: 1.h,
                    ),
                  ),
                  maxLines: null,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
              SizedBox(width: 2.w),
              // Send button
              CircleAvatar(
                backgroundColor: AppTheme.primaryLight,
                child: IconButton(
                  icon: const Icon(Icons.send, color: Colors.white),
                  onPressed: _sendMessage,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> message, bool isOwnMessage) {
    final createdAt = DateTime.parse(message['created_at']);
    final isPinned = message['is_pinned'] == true;

    return Align(
      alignment: isOwnMessage ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(bottom: 1.h),
        constraints: BoxConstraints(maxWidth: 70.w),
        child: Column(
          crossAxisAlignment: isOwnMessage
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            // Sender name (for others' messages)
            if (!isOwnMessage)
              Padding(
                padding: EdgeInsets.only(left: 2.w, bottom: 0.5.h),
                child: Text(
                  'Team Member', // In production, show actual name
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            // Message bubble
            Container(
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: isOwnMessage ? AppTheme.primaryLight : Colors.grey[200],
                borderRadius: BorderRadius.circular(12.0),
                border: isPinned
                    ? Border.all(color: Colors.amber, width: 2.0)
                    : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Pinned indicator
                  if (isPinned)
                    Row(
                      children: [
                        Icon(Icons.push_pin, size: 12.sp, color: Colors.amber),
                        SizedBox(width: 1.w),
                        Text(
                          'Pinned',
                          style: TextStyle(
                            fontSize: 10.sp,
                            color: Colors.amber,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  // Message text with markdown support
                  MarkdownBody(
                    data: message['message_text'],
                    styleSheet: MarkdownStyleSheet(
                      p: TextStyle(
                        fontSize: 12.sp,
                        color: isOwnMessage ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                  // Timestamp
                  SizedBox(height: 0.5.h),
                  Text(
                    timeago.format(createdAt),
                    style: TextStyle(
                      fontSize: 9.sp,
                      color: isOwnMessage
                          ? Colors.white.withAlpha(179)
                          : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
