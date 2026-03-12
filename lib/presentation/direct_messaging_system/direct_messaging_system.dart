import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:audioplayers/audioplayers.dart';

import '../../services/auth_service.dart';
import '../../services/messaging_service.dart';
import '../../services/supabase_service.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/error_boundary_wrapper.dart';
import '../../widgets/shimmer_skeleton_loader.dart';

class DirectMessagingSystemScreen extends StatefulWidget {
  const DirectMessagingSystemScreen({super.key});

  @override
  State<DirectMessagingSystemScreen> createState() =>
      _DirectMessagingSystemScreenState();
}

class _DirectMessagingSystemScreenState
    extends State<DirectMessagingSystemScreen> {
  final _messagingService = MessagingService.instance;
  final _auth = AuthService.instance;
  final _client = SupabaseService.instance.client;
  final _searchController = TextEditingController();

  bool _isLoading = true;
  List<Map<String, dynamic>> _conversations = [];
  List<Map<String, dynamic>> _filteredConversations = [];
  String? _selectedConversationId;
  int _offlineQueueCount = 0;
  Timer? _syncTimer;

  @override
  void initState() {
    super.initState();
    _loadConversations();
    _loadOfflineQueueCount();
    _setupAutoSync();
    _messagingService.updateUserPresence('online');
  }

  @override
  void dispose() {
    _searchController.dispose();
    _syncTimer?.cancel();
    _messagingService.updateUserPresence('offline');
    super.dispose();
  }

  void _setupAutoSync() {
    _syncTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _syncOfflineMessages(),
    );
  }

  Future<void> _loadConversations() async {
    setState(() => _isLoading = true);

    try {
      final conversations = await _messagingService.getUserConversations();
      setState(() {
        _conversations = conversations;
        _filteredConversations = conversations;
      });
    } catch (e) {
      debugPrint('Load conversations error: $e');
      setState(() {
        _conversations = _getMockConversations();
        _filteredConversations = _conversations;
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> _getMockConversations() {
    return [
      {
        'id': '1',
        'conversation_name': 'John Doe',
        'avatar_url': 'https://i.pravatar.cc/150?img=1',
        'last_message': 'Hey, how are you?',
        'last_message_at': DateTime.now().subtract(const Duration(minutes: 5)),
        'unread_count': 2,
        'is_online': true,
      },
      {
        'id': '2',
        'conversation_name': 'Jane Smith',
        'avatar_url': 'https://i.pravatar.cc/150?img=2',
        'last_message': 'Thanks for the update!',
        'last_message_at': DateTime.now().subtract(const Duration(hours: 2)),
        'unread_count': 0,
        'is_online': false,
      },
    ];
  }

  Future<void> _loadOfflineQueueCount() async {
    final count = await _messagingService.getOfflineQueueCount();
    setState(() => _offlineQueueCount = count);
  }

  Future<void> _syncOfflineMessages() async {
    final result = await _messagingService.syncOfflineMessages();
    if (result['success'] == true && result['synced'] > 0) {
      await _loadOfflineQueueCount();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${result['synced']} messages synced')),
        );
      }
    }
  }

  void _filterConversations(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredConversations = _conversations;
      } else {
        _filteredConversations = _conversations.where((conv) {
          final name = conv['conversation_name'] ?? '';
          return name.toLowerCase().contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  void _openConversation(String conversationId) {
    setState(() => _selectedConversationId = conversationId);
  }

  void _closeConversation() {
    setState(() => _selectedConversationId = null);
    _loadConversations();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_selectedConversationId != null) {
      return _ConversationScreen(
        conversationId: _selectedConversationId!,
        onBack: _closeConversation,
      );
    }

    return ErrorBoundaryWrapper(
      screenName: 'DirectMessagingSystemScreen',
      onRetry: _loadConversations,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: CustomAppBar(
          title: 'Messages',
          actions: [
            if (_offlineQueueCount > 0)
              Padding(
                padding: EdgeInsets.only(right: 2.w),
                child: Center(
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 2.w,
                      vertical: 0.5.h,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.cloud_upload,
                          size: 4.w,
                          color: Colors.white,
                        ),
                        SizedBox(width: 1.w),
                        Text(
                          '$_offlineQueueCount',
                          style: TextStyle(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            IconButton(
              icon: const Icon(Icons.sync),
              onPressed: _syncOfflineMessages,
            ),
          ],
        ),
        body: Column(
          children: [
            _buildSearchBar(theme),
            Expanded(
              child: _isLoading
                  ? const SkeletonList(itemCount: 8)
                  : _filteredConversations.isEmpty
                  ? _buildEmptyState(theme)
                  : RefreshIndicator(
                      onRefresh: _loadConversations,
                      child: ListView.builder(
                        padding: EdgeInsets.symmetric(vertical: 2.h),
                        itemCount: _filteredConversations.length,
                        itemBuilder: (context, index) {
                          final conversation = _filteredConversations[index];
                          return _buildConversationTile(conversation, theme);
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(ThemeData theme) {
    return Container(
      padding: EdgeInsets.all(4.w),
      color: theme.colorScheme.surface,
      child: TextField(
        controller: _searchController,
        onChanged: _filterConversations,
        decoration: InputDecoration(
          hintText: 'Search conversations...',
          prefixIcon: Icon(
            Icons.search,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          filled: true,
          fillColor: theme.colorScheme.surfaceContainerHighest,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide.none,
          ),
          contentPadding: EdgeInsets.symmetric(
            horizontal: 4.w,
            vertical: 1.5.h,
          ),
        ),
      ),
    );
  }

  Widget _buildConversationTile(
    Map<String, dynamic> conversation,
    ThemeData theme,
  ) {
    final unreadCount = conversation['unread_count'] ?? 0;
    final isOnline = conversation['is_online'] ?? false;
    final lastMessageTime = conversation['last_message_at'] != null
        ? timeago.format(conversation['last_message_at'])
        : '';

    return InkWell(
      onTap: () => _openConversation(conversation['id']),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
        child: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 8.w,
                  backgroundImage: CachedNetworkImageProvider(
                    conversation['avatar_url'] ?? '',
                  ),
                ),
                if (isOnline)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 3.w,
                      height: 3.w,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: theme.scaffoldBackgroundColor,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        conversation['conversation_name'] ?? 'Unknown',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        lastMessageTime,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 0.5.h),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          conversation['last_message'] ?? '',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (unreadCount > 0) ...[
                        SizedBox(width: 2.w),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 2.w,
                            vertical: 0.5.h,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          child: Text(
                            '$unreadCount',
                            style: TextStyle(
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
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
            color: theme.colorScheme.onSurfaceVariant,
          ),
          SizedBox(height: 2.h),
          Text(
            'No conversations yet',
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            'Start a conversation to connect with others',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

// Conversation Screen
class _ConversationScreen extends StatefulWidget {
  final String conversationId;
  final VoidCallback onBack;

  const _ConversationScreen({
    required this.conversationId,
    required this.onBack,
  });

  @override
  State<_ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<_ConversationScreen> {
  final _messagingService = MessagingService.instance;
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _imagePicker = ImagePicker();
  final _audioRecorder = AudioRecorder();
  final _audioPlayer = AudioPlayer();

  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = true;
  bool _showEmojiPicker = false;
  StreamSubscription? _messageSubscription;
  Map<String, List<Map<String, dynamic>>> _reactionsByMessageId = {};
  bool _isRecording = false;
  int _recordingDurationSec = 0;
  Timer? _recordingTimer;
  bool _showMediaGallery = false;
  String? _playingVoiceMessageId;

  @override
  void initState() {
    super.initState();
    _messageController.addListener(() => setState(() {}));
    _loadMessages();
    _subscribeToMessages();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _messageSubscription?.cancel();
    _recordingTimer?.cancel();
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    setState(() => _isLoading = true);

    try {
      final messages = await _messagingService.getMessages(
        widget.conversationId,
      );
      final ids = messages
          .map((m) => m['id']?.toString())
          .whereType<String>()
          .toList();
      final reactionsMap = await _messagingService.getReactionsForMessageIds(ids);
      setState(() {
        _messages = messages;
        _reactionsByMessageId = reactionsMap;
      });
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
    _messageSubscription = stream?.listen((newMessage) async {
      setState(() => _messages.add(newMessage));
      final id = newMessage['id']?.toString();
      if (id != null) {
        final list = await _messagingService.getMessageReactions(id);
        if (mounted) setState(() => _reactionsByMessageId[id] = list);
      }
      _scrollToBottom();
    });
  }

  Future<void> _refreshReactionsForMessage(String messageId) async {
    final list = await _messagingService.getMessageReactions(messageId);
    if (mounted) setState(() => _reactionsByMessageId[messageId] = list);
  }

  Future<void> _startVoiceRecord() async {
    if (_isRecording) return;
    final hasPermission = await _audioRecorder.hasPermission();
    if (!hasPermission) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Microphone permission required')),
        );
      }
      return;
    }
    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
    await _audioRecorder.start(const RecordConfig(encoder: AudioEncoder.aacLc), path: path);
    setState(() {
      _isRecording = true;
      _recordingDurationSec = 0;
    });
    _recordingTimer?.cancel();
    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && _isRecording) setState(() => _recordingDurationSec++);
    });
  }

  Future<void> _stopVoiceRecordAndSend() async {
    if (!_isRecording) return;
    _recordingTimer?.cancel();
    _recordingTimer = null;
    final path = await _audioRecorder.stop();
    final durationSec = _recordingDurationSec;
    setState(() {
      _isRecording = false;
      _recordingDurationSec = 0;
    });
    if (path == null || path.isEmpty || durationSec < 1) return;
    final url = await _messagingService.uploadVoiceMessage(
      conversationId: widget.conversationId,
      filePath: path,
    );
    if (url == null || !mounted) return;
    await _messagingService.sendMessage(
      conversationId: widget.conversationId,
      content: '[Voice message ${durationSec}s]',
      messageType: 'voice',
      mediaUrl: url,
      metadata: {'duration': durationSec},
    );
    if (mounted) _loadMessages();
  }

  void _cancelRecording() async {
    if (!_isRecording) return;
    _recordingTimer?.cancel();
    _recordingTimer = null;
    await _audioRecorder.stop();
    setState(() {
      _isRecording = false;
      _recordingDurationSec = 0;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Recording cancelled')),
      );
    }
  }

  static String _formatDuration(int sec) {
    final m = sec ~/ 60;
    final s = sec % 60;
    return '${m}:${s.toString().padLeft(2, '0')}';
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

  Future<void> _pickImage() async {
    final image = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      // Upload to Supabase Storage and send message
      await _sendMediaMessage(image.path, 'image');
    }
  }

  Future<void> _pickDocument() async {
    final result = await FilePicker.platform.pickFiles();
    if (result != null && result.files.isNotEmpty) {
      await _sendMediaMessage(result.files.first.path!, 'document');
    }
  }

  Future<void> _sendMediaMessage(String filePath, String type) async {
    // Upload file to Supabase Storage
    // For now, send placeholder
    await _messagingService.sendMessage(
      conversationId: widget.conversationId,
      content: type == 'image' ? 'Image' : 'Document',
      messageType: type,
      mediaUrl: filePath,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: CustomAppBar(
        title: 'Chat',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.onBack,
        ),
        actions: [
          IconButton(icon: const Icon(Icons.videocam), onPressed: () {}),
          IconButton(icon: const Icon(Icons.call), onPressed: () {}),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _messages.isEmpty
                    ? _buildEmptyState(theme)
                    : _buildMessageList(theme),
              ),
              if (_showEmojiPicker)
                SizedBox(
                  height: 250,
                  child: EmojiPicker(
                    onEmojiSelected: (category, emoji) {
                      _messageController.text += emoji.emoji;
                    },
                  ),
                ),
              _buildMessageInput(theme),
            ],
          ),
          if (_showMediaGallery)
            _buildMediaGalleryOverlay(theme),
        ],
      ),
    );
  }

  Widget _buildMediaGalleryOverlay(ThemeData theme) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _messagingService.getThreadMedia(widget.conversationId),
      builder: (context, snapshot) {
        final media = snapshot.data ?? [];
        final filtered = media;
        return Material(
          color: Colors.black87,
          child: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.all(4.w),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Media Gallery',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => setState(() => _showMediaGallery = false),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: snapshot.connectionState == ConnectionState.waiting
                      ? const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        )
                      : filtered.isEmpty
                      ? Center(
                          child: Text(
                            'No media in this chat',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: Colors.white70,
                            ),
                          ),
                        )
                      : GridView.builder(
                          padding: EdgeInsets.all(4.w),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                            childAspectRatio: 1,
                          ),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final item = filtered[index];
                            final type = item['media_type'] as String? ?? 'image';
                            final url = item['media_url'] as String? ?? '';
                            if (type == 'image' && url.isNotEmpty) {
                              return GestureDetector(
                                onTap: () {
                                  showDialog(
                                    context: context,
                                    builder: (ctx) => Dialog(
                                      child: CachedNetworkImage(
                                        imageUrl: url,
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                  );
                                },
                                child: CachedNetworkImage(
                                  imageUrl: url,
                                  fit: BoxFit.cover,
                                ),
                              );
                            }
                            if (type == 'voice') {
                              return Container(
                                color: theme.colorScheme.surfaceContainerHighest,
                                child: const Icon(Icons.mic, size: 32),
                              );
                            }
                            return Container(
                              color: theme.colorScheme.surfaceContainerHighest,
                              child: const Icon(Icons.insert_drive_file, size: 32),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMessageList(ThemeData theme) {
    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        final isMe =
            message['sender_id'] == AuthService.instance.currentUser?.id;

        return _buildMessageBubble(message, isMe, theme);
      },
    );
  }

  Widget _buildMessageBubble(
    Map<String, dynamic> message,
    bool isMe,
    ThemeData theme,
  ) {
    final messageId = message['id']?.toString() ?? '';
    final messageType = message['message_type'] as String? ?? 'text';
    final mediaUrl = message['media_url'] as String?;
    final metadata = message['metadata'] as Map<String, dynamic>?;
    final durationSec = metadata != null && metadata['duration'] != null
        ? (metadata['duration'] is int
            ? metadata['duration'] as int
            : (metadata['duration'] as num).toInt())
        : 0;
    final reactions = _reactionsByMessageId[messageId] ?? [];
    final currentUserId = AuthService.instance.currentUser?.id ?? '';

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(bottom: 1.h),
        constraints: BoxConstraints(maxWidth: 70.w),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
              decoration: BoxDecoration(
                color: isMe
                    ? theme.colorScheme.primary
                    : theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (messageType == 'voice') ...[
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(
                            _playingVoiceMessageId == messageId
                                ? Icons.stop
                                : Icons.play_arrow,
                            color: isMe ? Colors.white : theme.colorScheme.primary,
                          ),
                          onPressed: () => _toggleVoicePlay(messageId, mediaUrl),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                        SizedBox(width: 2.w),
                        Container(
                          height: 4,
                          width: 40.w,
                          decoration: BoxDecoration(
                            color: (isMe ? Colors.white : theme.colorScheme.outline)
                                .withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(2),
                          ),
                          alignment: Alignment.centerLeft,
                          child: FractionallySizedBox(
                            widthFactor: 0.3,
                            child: Container(
                              decoration: BoxDecoration(
                                color: isMe ? Colors.white70 : theme.colorScheme.primary,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 2.w),
                        Text(
                          _formatDuration(durationSec),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isMe ? Colors.white70 : theme.colorScheme.onSurfaceVariant,
                            fontSize: 10.sp,
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    if (mediaUrl != null && mediaUrl.isNotEmpty)
                      Padding(
                        padding: EdgeInsets.only(bottom: 1.h),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: CachedNetworkImage(
                            imageUrl: mediaUrl,
                            width: 60.w,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    Text(
                      message['content'] ?? '',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: isMe ? Colors.white : theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            _buildMessageReactions(
              messageId: messageId,
              reactions: reactions,
              currentUserId: currentUserId,
              isMe: isMe,
              theme: theme,
            ),
            SizedBox(height: 0.3.h),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  timeago.format(message['created_at'] ?? DateTime.now()),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isMe
                        ? Colors.white70
                        : theme.colorScheme.onSurfaceVariant,
                    fontSize: 9.sp,
                  ),
                ),
                if (isMe) ...[
                  SizedBox(width: 1.w),
                  Icon(
                    message['read_at'] != null ? Icons.done_all : Icons.done,
                    size: 3.w,
                    color: message['read_at'] != null
                        ? Colors.blue
                        : Colors.white70,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _toggleVoicePlay(String messageId, String? url) async {
    if (url == null || url.isEmpty) return;
    if (_playingVoiceMessageId == messageId) {
      await _audioPlayer.stop();
      setState(() => _playingVoiceMessageId = null);
      return;
    }
    await _audioPlayer.play(UrlSource(url));
    setState(() => _playingVoiceMessageId = messageId);
    _audioPlayer.onPlayerComplete.first.then((_) {
      if (mounted) setState(() => _playingVoiceMessageId = null);
    });
  }

  static const List<String> _reactionEmojis = [
    '❤️', '👍', '😂', '😢', '😮', '🔥', '🎉', '👏',
  ];

  Widget _buildMessageReactions({
    required String messageId,
    required List<Map<String, dynamic>> reactions,
    required String currentUserId,
    required bool isMe,
    required ThemeData theme,
  }) {
    final counts = <String, int>{};
    final userEmojis = <String>{};
    for (final r in reactions) {
      final emoji = r['reaction_emoji'] as String? ?? '';
      if (emoji.isEmpty) continue;
      counts[emoji] = (counts[emoji] ?? 0) + 1;
      if (r['user_id'] == currentUserId) userEmojis.add(emoji);
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...counts.entries.map((e) {
          final emoji = e.key;
          final count = e.value;
          final isUser = userEmojis.contains(emoji);
          return Padding(
            padding: EdgeInsets.only(right: 1.w),
            child: GestureDetector(
              onTap: () async {
                if (isUser) {
                  await _messagingService.removeReaction(
                    messageId: messageId,
                    emoji: emoji,
                  );
                } else {
                  await _messagingService.addReaction(
                    messageId: messageId,
                    emoji: emoji,
                  );
                }
                _refreshReactionsForMessage(messageId);
              },
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.3.h),
                decoration: BoxDecoration(
                  color: isUser
                      ? theme.colorScheme.primary.withValues(alpha: 0.2)
                      : theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isUser
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outline.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(emoji, style: TextStyle(fontSize: 12.sp)),
                    if (count > 1) ...[
                      SizedBox(width: 1.w),
                      Text(
                        '$count',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 10.sp,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        }),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () async {
              final emoji = await showDialog<String>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Add reaction'),
                  content: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _reactionEmojis
                        .map((e) => InkWell(
                              onTap: () => Navigator.pop(ctx, e),
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(e, style: const TextStyle(fontSize: 28)),
                              ),
                            ))
                        .toList(),
                  ),
                ),
              );
              if (emoji != null) {
                await _messagingService.addReaction(
                  messageId: messageId,
                  emoji: emoji,
                );
                _refreshReactionsForMessage(messageId);
              }
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: EdgeInsets.all(1.w),
              child: Icon(
                Icons.emoji_emotions_outlined,
                size: 18.sp,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ],
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
    if (_isRecording) {
      return Container(
        padding: EdgeInsets.all(3.w),
        color: theme.colorScheme.surface,
        child: SafeArea(
          child: Row(
            children: [
              const Icon(Icons.mic, color: Colors.red, size: 28),
              SizedBox(width: 2.w),
              Text(
                'Recording... ${_formatDuration(_recordingDurationSec)}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.red.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: _cancelRecording,
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: _stopVoiceRecordAndSend,
                style: FilledButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                ),
                child: const Icon(Icons.send),
              ),
            ],
          ),
        ),
      );
    }
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
              icon: Icon(
                Icons.emoji_emotions_outlined,
                color: theme.colorScheme.primary,
              ),
              onPressed: () {
                setState(() => _showEmojiPicker = !_showEmojiPicker);
              },
            ),
            IconButton(
              icon: Icon(Icons.photo_library, color: theme.colorScheme.primary),
              onPressed: () => setState(() => _showMediaGallery = true),
            ),
            IconButton(
              icon: Icon(Icons.photo, color: theme.colorScheme.primary),
              onPressed: _pickImage,
            ),
            IconButton(
              icon: Icon(Icons.attach_file, color: theme.colorScheme.primary),
              onPressed: _pickDocument,
            ),
            Expanded(
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24.0),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainerHighest,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 4.w,
                    vertical: 1.h,
                  ),
                ),
                maxLines: 5,
                minLines: 1,
              ),
            ),
            SizedBox(width: 2.w),
            if (_messageController.text.trim().isNotEmpty)
              CircleAvatar(
                backgroundColor: theme.colorScheme.primary,
                child: IconButton(
                  icon: const Icon(Icons.send, color: Colors.white),
                  onPressed: _sendTextMessage,
                ),
              )
            else
              IconButton(
                icon: Icon(Icons.mic, color: theme.colorScheme.primary),
                onPressed: _startVoiceRecord,
              ),
          ],
        ),
      ),
    );
  }

}
