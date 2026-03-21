import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../services/auth_service.dart';
import '../../../services/messaging_service.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/custom_app_bar.dart';
import './message_bubble_widget.dart';
import './typing_indicator_widget.dart';

class ChatInterfaceWidget extends StatefulWidget {
  final String conversationId;
  final VoidCallback onBack;

  const ChatInterfaceWidget({
    super.key,
    required this.conversationId,
    required this.onBack,
  });

  @override
  State<ChatInterfaceWidget> createState() => _ChatInterfaceWidgetState();
}

class _ChatInterfaceWidgetState extends State<ChatInterfaceWidget> {
  final MessagingService _messagingService = MessagingService.instance;
  final AuthService _authService = AuthService.instance;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _imagePicker = ImagePicker();

  bool _isLoading = true;
  bool _isSending = false;
  bool _isRecording = false;
  final AudioRecorder _audioRecorder = AudioRecorder();
  List<Map<String, dynamic>> _messages = [];
  List<String> _typingUsers = [];
  StreamSubscription? _messageSubscription;
  StreamSubscription? _typingSubscription;
  Timer? _typingTimer;

  // Voice recording: slide-to-cancel and duration
  DateTime? _recordingStartTime;
  int _recordingDurationSeconds = 0;
  Timer? _recordingTickTimer;
  Timer? _recordLongPressTimer;
  Offset? _recordPointerDownPosition;
  bool _shouldCancelRecording = false;
  String? _currentRecordingPath;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _subscribeToMessages();
    _subscribeToTyping();
    _messagingService.markAsRead(widget.conversationId);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _messageSubscription?.cancel();
    _typingSubscription?.cancel();
    _typingTimer?.cancel();
    _recordingTickTimer?.cancel();
    _recordLongPressTimer?.cancel();
    _messagingService.setTypingIndicator(
      conversationId: widget.conversationId,
      isTyping: false,
    );
    _messagingService.unsubscribeFromConversation(widget.conversationId);
    super.dispose();
  }

  Future<void> _loadMessages() async {
    setState(() => _isLoading = true);

    try {
      final messages = await _messagingService.getMessages(
        widget.conversationId,
      );
      setState(() {
        _messages = messages;
      });
      _scrollToBottom();
    } catch (e) {
      debugPrint('Load messages error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _subscribeToMessages() {
    _messageSubscription = _messagingService
        .subscribeToConversation(widget.conversationId)
        ?.listen((newMessage) {
          setState(() {
            _messages.add(newMessage);
          });
          _scrollToBottom();
          _messagingService.markAsRead(widget.conversationId);
        });
  }

  void _subscribeToTyping() {
    _typingSubscription = _messagingService
        .subscribeToTypingIndicators(widget.conversationId)
        ?.listen((typingUsers) {
          setState(() {
            _typingUsers = typingUsers.where((user) {
              return user != _authService.currentUser?.email?.split('@')[0];
            }).toList();
          });
        });
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  void _onMessageChanged(String text) {
    _typingTimer?.cancel();

    if (text.isNotEmpty) {
      _messagingService.setTypingIndicator(
        conversationId: widget.conversationId,
        isTyping: true,
      );

      _typingTimer = Timer(const Duration(seconds: 3), () {
        _messagingService.setTypingIndicator(
          conversationId: widget.conversationId,
          isTyping: false,
        );
      });
    } else {
      _messagingService.setTypingIndicator(
        conversationId: widget.conversationId,
        isTyping: false,
      );
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty || _isSending) return;

    setState(() => _isSending = true);

    final message = _messageController.text.trim();
    _messageController.clear();

    _messagingService.setTypingIndicator(
      conversationId: widget.conversationId,
      isTyping: false,
    );

    final success = await _messagingService.sendMessage(
      conversationId: widget.conversationId,
      content: message,
    );

    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Message queued for sending when online'),
          backgroundColor: AppTheme.warningLight,
        ),
      );
    }

    setState(() => _isSending = false);
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        await _sendPickedMedia(filePath: image.path, messageType: 'image');
      }
    } catch (e) {
      debugPrint('Pick image error: $e');
    }
  }

  Future<void> _pickVideo() async {
    try {
      final XFile? video = await _imagePicker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 1),
      );

      if (video != null) {
        await _sendPickedMedia(filePath: video.path, messageType: 'video');
      }
    } catch (e) {
      debugPrint('Pick video error: $e');
    }
  }

  void _showMediaOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: EdgeInsets.all(4.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.photo_library),
              title: Text('Photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImage();
              },
            ),
            ListTile(
              leading: Icon(Icons.videocam),
              title: Text('Video'),
              onTap: () {
                Navigator.pop(context);
                _pickVideo();
              },
            ),
            ListTile(
              leading: Icon(Icons.camera_alt),
              title: Text('Camera'),
              onTap: () {
                Navigator.pop(context);
                _takePhoto();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _takePhoto() async {
    try {
      final XFile? photo = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (photo != null) {
        await _sendPickedMedia(filePath: photo.path, messageType: 'image');
      }
    } catch (e) {
      debugPrint('Take photo error: $e');
    }
  }

  Future<void> _sendPickedMedia({
    required String filePath,
    required String messageType,
  }) async {
    if (!mounted) return;
    setState(() => _isSending = true);
    try {
      final mediaUrl = await _messagingService.uploadConversationMedia(
        conversationId: widget.conversationId,
        filePath: filePath,
        mediaType: messageType,
      );
      if (mediaUrl == null || mediaUrl.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Upload failed. Please try again.')),
          );
        }
        return;
      }

      final success = await _messagingService.sendMessage(
        conversationId: widget.conversationId,
        content: messageType == 'video' ? 'Video attachment' : 'Image attachment',
        messageType: messageType,
        mediaUrl: mediaUrl,
      );

      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Message queued for sending when online'),
            backgroundColor: AppTheme.warningLight,
          ),
        );
      }
      await _loadMessages();
    } catch (e) {
      debugPrint('Send picked media error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not send media: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: CustomAppBar(
          title: 'Conversation',
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
              icon: Icon(Icons.photo_library_outlined, color: theme.appBarTheme.foregroundColor),
              onPressed: _showMediaGallery,
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                ? _buildEmptyState(theme)
                : _buildMessageList(theme),
          ),
          if (_typingUsers.isNotEmpty)
            TypingIndicatorWidget(users: _typingUsers),
          _buildMessageInput(theme),
        ],
      ),
    );
  }

  Widget _buildMessageList(ThemeData theme) {
    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        final isMe = message['sender_id'] == _authService.currentUser?.id;

        return MessageBubbleWidget(
          message: message,
          isMe: isMe,
          onReaction: (emoji) => _addReaction(message['id'], emoji),
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
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            'Start the conversation',
            style: TextStyle(
              fontSize: 13.sp,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  static const int _recordLongPressMs = 300;
  static const double _slideToCancelThresholdPx = 60;

  Widget _buildMessageInput(ThemeData theme) {
    if (_isRecording) {
      return _buildRecordingBar(theme);
    }
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(color: theme.colorScheme.outlineVariant, width: 1),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.attach_file, color: theme.colorScheme.primary),
            onPressed: _showMediaOptions,
          ),
          Listener(
            onPointerDown: _onRecordPointerDown,
            onPointerMove: _onRecordPointerMove,
            onPointerUp: _onRecordPointerUp,
            child: IconButton(
              icon: Icon(Icons.mic, color: theme.colorScheme.primary),
              onPressed: null,
            ),
          ),
          Expanded(
            child: TextField(
              controller: _messageController,
              onChanged: _onMessageChanged,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24.0),
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
          _isSending
              ? SizedBox(
                  width: 10.w,
                  height: 10.w,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : IconButton(
                  icon: Icon(Icons.send, color: theme.colorScheme.primary),
                  onPressed: _sendMessage,
                ),
        ],
      ),
    );
  }

  void _onRecordPointerDown(PointerDownEvent event) {
    _recordPointerDownPosition = event.position;
    _shouldCancelRecording = false;
    _recordLongPressTimer?.cancel();
    _recordLongPressTimer = Timer(Duration(milliseconds: _recordLongPressMs), () {
      if (!_isRecording) _startVoiceRecord();
    });
  }

  void _onRecordPointerMove(PointerMoveEvent event) {
    if (!_isRecording || _recordPointerDownPosition == null) return;
    final dx = _recordPointerDownPosition!.dx - event.position.dx;
    setState(() => _shouldCancelRecording = dx > _slideToCancelThresholdPx);
  }

  void _onRecordPointerUp(PointerUpEvent event) {
    _recordLongPressTimer?.cancel();
    if (!_isRecording) return;
    if (_shouldCancelRecording) {
      _cancelRecording();
    } else {
      _stopVoiceRecordAndSend();
    }
  }

  Widget _buildRecordingBar(ThemeData theme) {
    final durationStr = _formatDuration(_recordingDurationSeconds);
    return Listener(
      onPointerMove: _onRecordPointerMove,
      onPointerUp: _onRecordPointerUp,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          border: Border(
            top: BorderSide(color: theme.colorScheme.outlineVariant, width: 1),
          ),
        ),
        child: Row(
          children: [
            Icon(
              _shouldCancelRecording ? Icons.delete_outline : Icons.keyboard_voice,
              size: 28.sp,
              color: _shouldCancelRecording
                  ? theme.colorScheme.error
                  : theme.colorScheme.primary,
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: Text(
                _shouldCancelRecording ? 'Release to cancel' : 'Slide to cancel',
                style: TextStyle(
                  fontSize: 13.sp,
                  color: _shouldCancelRecording
                      ? theme.colorScheme.error
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                durationStr,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  fontFeatures: [FontFeature.tabularFigures()],
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(1, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Future<void> _cancelRecording() async {
    if (!_isRecording) return;
    _recordingTickTimer?.cancel();
    _recordingTickTimer = null;
    final path = await _audioRecorder.stop();
    setState(() {
      _isRecording = false;
      _recordingStartTime = null;
      _recordingDurationSeconds = 0;
      _shouldCancelRecording = false;
      _currentRecordingPath = null;
    });
    if (path != null && path.isNotEmpty) {
      try {
        await File(path).delete();
      } catch (_) {}
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Recording cancelled')),
      );
    }
  }

  Future<void> _addReaction(String messageId, String emoji) async {
    await _messagingService.addReaction(messageId: messageId, emoji: emoji);
  }

  Future<void> _startVoiceRecord() async {
    if (_isRecording) return;
    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
    final hasPermission = await _audioRecorder.hasPermission();
    if (!hasPermission) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Microphone permission required')),
        );
      }
      return;
    }
    await _audioRecorder.start(const RecordConfig(encoder: AudioEncoder.aacLc), path: path);
    if (!mounted) return;
    setState(() {
      _isRecording = true;
      _currentRecordingPath = path;
      _recordingStartTime = DateTime.now();
      _recordingDurationSeconds = 0;
      _shouldCancelRecording = false;
    });
    _recordingTickTimer?.cancel();
    _recordingTickTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || !_isRecording || _recordingStartTime == null) return;
      setState(() {
        _recordingDurationSeconds =
            DateTime.now().difference(_recordingStartTime!).inSeconds;
      });
    });
  }

  Future<void> _stopVoiceRecordAndSend() async {
    if (!_isRecording) return;
    _recordingTickTimer?.cancel();
    _recordingTickTimer = null;
    final durationSeconds = _recordingStartTime != null
        ? DateTime.now().difference(_recordingStartTime!).inSeconds
        : _recordingDurationSeconds;
    final path = await _audioRecorder.stop();
    setState(() {
      _isRecording = false;
      _recordingStartTime = null;
      _recordingDurationSeconds = 0;
      _shouldCancelRecording = false;
      _currentRecordingPath = null;
    });
    if (path == null || path.isEmpty) return;
    setState(() => _isSending = true);
    final durationLabel = _formatDuration(durationSeconds);
    try {
      final url = await _messagingService.uploadVoiceMessage(
        conversationId: widget.conversationId,
        filePath: path,
      );
      if (url != null && mounted) {
        await _messagingService.sendMessage(
          conversationId: widget.conversationId,
          content: 'Voice message • $durationLabel',
          messageType: 'voice',
          mediaUrl: url,
        );
        _loadMessages();
      }
    } catch (e) {
      debugPrint('Voice send error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send voice: $e')),
        );
      }
    }
    if (mounted) setState(() => _isSending = false);
    try {
      await File(path).delete();
    } catch (_) {}
  }

  void _showMediaGallery() {
    final mediaMessages = _messages.where((m) {
      final url = m['media_url'];
      final type = m['message_type'];
      return (url != null && url.toString().isNotEmpty) || type == 'voice';
    }).toList();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.3,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Padding(
              padding: EdgeInsets.all(4.w),
              child: Text(
                'Media & voice (${mediaMessages.length})',
                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: mediaMessages.length,
                itemBuilder: (context, index) {
                  final m = mediaMessages[index];
                  final url = m['media_url']?.toString() ?? '';
                  final isVoice = m['message_type'] == 'voice';
                  return ListTile(
                    leading: isVoice
                        ? const Icon(Icons.mic, color: AppTheme.primaryLight)
                        : (url.isNotEmpty
                            ? Image.network(url, width: 48, height: 48, fit: BoxFit.cover)
                            : const Icon(Icons.attachment)),
                    title: Text(isVoice ? 'Voice message' : 'Media'),
                    subtitle: Text(m['created_at']?.toString() ?? ''),
                    onTap: () {
                      Navigator.pop(context);
                      if (isVoice && url.isNotEmpty) {
                        _openVoicePlayer(url);
                      } else if (url.isNotEmpty) {
                        _openFullScreenMedia(url, isImage: true);
                      }
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openVoicePlayer(String mediaUrl) {
    showModalBottomSheet(
      context: context,
      builder: (context) => _VoicePlayerSheet(mediaUrl: mediaUrl),
    );
  }

  void _openFullScreenMedia(String url, {bool isImage = true}) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Stack(
          children: [
            InteractiveViewer(
              child: isImage
                  ? Image.network(url, fit: BoxFit.contain)
                  : Center(child: Text('Video/media: $url')),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// In-sheet voice player for media gallery.
class _VoicePlayerSheet extends StatefulWidget {
  final String mediaUrl;

  const _VoicePlayerSheet({required this.mediaUrl});

  @override
  State<_VoicePlayerSheet> createState() => _VoicePlayerSheetState();
}

class _VoicePlayerSheetState extends State<_VoicePlayerSheet> {
  final AudioPlayer _player = AudioPlayer();
  bool _playing = false;

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _player.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _playing = false);
    });
  }

  Future<void> _togglePlay() async {
    if (_playing) {
      await _player.pause();
    } else {
      await _player.play(UrlSource(widget.mediaUrl));
    }
    setState(() => _playing = !_playing);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(4.w),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              IconButton(
                icon: Icon(_playing ? Icons.pause : Icons.play_arrow, size: 40),
                onPressed: _togglePlay,
              ),
              Text('Voice message', style: TextStyle(fontSize: 16.sp)),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}
