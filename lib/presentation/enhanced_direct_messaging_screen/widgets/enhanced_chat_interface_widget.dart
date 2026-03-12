import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../services/auth_service.dart';
import '../../../services/messaging_service.dart';
import '../../../widgets/custom_app_bar.dart';
import './voice_message_recorder_widget.dart';
import './emoji_reaction_picker_widget.dart';
import './media_gallery_picker_widget.dart';
import './enhanced_message_bubble_widget.dart';

class EnhancedChatInterfaceWidget extends StatefulWidget {
  final String conversationId;
  final VoidCallback onBack;

  const EnhancedChatInterfaceWidget({
    super.key,
    required this.conversationId,
    required this.onBack,
  });

  @override
  State<EnhancedChatInterfaceWidget> createState() =>
      _EnhancedChatInterfaceWidgetState();
}

class _EnhancedChatInterfaceWidgetState
    extends State<EnhancedChatInterfaceWidget> {
  final MessagingService _messagingService = MessagingService.instance;
  final AuthService _authService = AuthService.instance;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = true;
  bool _isRecordingVoice = false;
  bool _otherUserTyping = false;
  StreamSubscription? _messageSubscription;
  StreamSubscription<Map<String, dynamic>>? _typingSubscription;
  Timer? _typingDebounceTimer;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _subscribeToMessages();
    _subscribeToTypingBroadcast();
    _messageController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _messageController.removeListener(_onTextChanged);
    _typingDebounceTimer?.cancel();
    _messagingService.sendTypingIndicatorBroadcast(
      conversationId: widget.conversationId,
      isTyping: false,
    );
    _typingSubscription?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    _messageSubscription?.cancel();
    _messagingService.unsubscribeFromConversation(widget.conversationId);
    super.dispose();
  }

  void _onTextChanged() {
    _messagingService.sendTypingIndicatorBroadcast(
      conversationId: widget.conversationId,
      isTyping: true,
    );
    _typingDebounceTimer?.cancel();
    _typingDebounceTimer = Timer(const Duration(seconds: 3), () {
      _messagingService.sendTypingIndicatorBroadcast(
        conversationId: widget.conversationId,
        isTyping: false,
      );
    });
  }

  void _subscribeToTypingBroadcast() {
    final currentUserId = _authService.currentUser?.id;
    if (currentUserId == null) return;

    final stream = _messagingService.subscribeToTypingBroadcast(
      widget.conversationId,
    );
    _typingSubscription = stream?.listen((payload) {
      if (!mounted) return;
      final userId = payload['userId'] as String?;
      final isTyping = payload['isTyping'] as bool? ?? false;
      if (userId == null || userId == currentUserId) return;
      setState(() => _otherUserTyping = isTyping);
      if (isTyping) {
        Future.delayed(const Duration(seconds: 4), () {
          if (mounted) setState(() => _otherUserTyping = false);
        });
      }
    });
  }

  Future<void> _loadMessages() async {
    setState(() => _isLoading = true);

    try {
      final messages = await _messagingService.getMessages(
        widget.conversationId,
      );
      setState(() => _messages = messages);
      _scrollToBottom();
    } catch (e) {
      debugPrint('Load messages error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _subscribeToMessages() {
    final stream = _messagingService.subscribeToConversation(
      widget.conversationId,
    );
    _messageSubscription = stream?.listen((newMessage) {
      setState(() => _messages.add(newMessage));
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

  Future<void> _sendTextMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    _messageController.clear();

    await _messagingService.sendMessage(
      conversationId: widget.conversationId,
      content: content,
      messageType: 'text',
    );
  }

  Future<void> _sendVoiceMessage(String localPath, int durationSeconds) async {
    final publicUrl = await _messagingService.uploadVoiceMessage(
      conversationId: widget.conversationId,
      filePath: localPath,
    );
    if (publicUrl == null || !mounted) return;
    await _messagingService.sendMessage(
      conversationId: widget.conversationId,
      content: 'Voice message ${durationSeconds}s',
      messageType: 'voice',
      mediaUrl: publicUrl,
    );
  }

  Future<void> _sendMediaMessage(List<String> mediaUrls) async {
    await _messagingService.sendMessage(
      conversationId: widget.conversationId,
      content: 'Media',
      messageType: 'media',
      mediaUrl: mediaUrls.first,
    );
  }

  void _showEmojiReactionPicker(String messageId) {
    showModalBottomSheet(
      context: context,
      builder: (context) => EmojiReactionPickerWidget(
        messageId: messageId,
        onEmojiSelected: (emoji) {
          Navigator.pop(context);
          _addReaction(messageId, emoji);
        },
      ),
    );
  }

  Future<void> _addReaction(String messageId, String emoji) async {
    // Add reaction logic here
    debugPrint('Add reaction: $emoji to message: $messageId');
  }

  void _showMediaGalleryPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => MediaGalleryPickerWidget(
        onMediaSelected: (mediaUrls) {
          Navigator.pop(context);
          _sendMediaMessage(mediaUrls);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: CustomAppBar(
          title: 'Chat',
          variant: CustomAppBarVariant.standard,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back,
              color: theme.appBarTheme.foregroundColor,
            ),
            onPressed: widget.onBack,
          ),
          actions: [
            IconButton(
              icon: Icon(
                Icons.photo_library,
                color: theme.appBarTheme.foregroundColor,
              ),
              onPressed: _showMediaGalleryPicker,
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                ? _buildEmptyState(theme)
                : _buildMessageList(),
          ),
          _buildMessageInput(theme),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    final theme = Theme.of(context);
    final itemCount =
        _messages.length + (_otherUserTyping ? 1 : 0);
    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        if (index == _messages.length) {
          return Padding(
            padding: EdgeInsets.only(left: 4.w, bottom: 1.h),
            child: Row(
              children: [
                SizedBox(
                  width: 6.w,
                  height: 6.w,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: theme.colorScheme.primary.withValues(alpha: 0.7),
                  ),
                ),
                SizedBox(width: 2.w),
                Text(
                  'typing…',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          );
        }
        final message = _messages[index];
        return EnhancedMessageBubbleWidget(
          message: message,
          onLongPress: () => _showEmojiReactionPicker(message['id']),
        );
      },
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
            color: theme.colorScheme.onSurfaceVariant,
          ),
          SizedBox(height: 2.h),
          Text(
            'No messages yet',
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput(ThemeData theme) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              icon: Icon(Icons.photo, color: theme.colorScheme.primary),
              onPressed: _showMediaGalleryPicker,
            ),
            Expanded(
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainerHighest,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25.0),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 4.w,
                    vertical: 1.h,
                  ),
                ),
                maxLines: null,
              ),
            ),
            SizedBox(width: 2.w),
            IconButton(
              icon: Icon(
                _isRecordingVoice ? Icons.stop : Icons.mic,
                color: theme.colorScheme.primary,
              ),
              onPressed: () {
                setState(() => _isRecordingVoice = !_isRecordingVoice);
                if (_isRecordingVoice) {
                  _showVoiceRecorder();
                }
              },
            ),
            IconButton(
              icon: Icon(Icons.send, color: theme.colorScheme.primary),
              onPressed: _sendTextMessage,
            ),
          ],
        ),
      ),
    );
  }

  void _showVoiceRecorder() {
    showModalBottomSheet(
      context: context,
      builder: (context) => VoiceMessageRecorderWidget(
        onRecordingComplete: (voiceUrl, duration) {
          Navigator.pop(context);
          setState(() => _isRecordingVoice = false);
          _sendVoiceMessage(voiceUrl, duration);
        },
        onCancel: () {
          Navigator.pop(context);
          setState(() => _isRecordingVoice = false);
        },
      ),
    );
  }
}
