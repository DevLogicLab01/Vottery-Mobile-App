import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/collaborative_voting_service.dart';
import '../../widgets/custom_app_bar.dart';
import './widgets/chat_message_widget.dart';
import './widgets/moderation_controls_widget.dart';
import './widgets/voting_option_card_widget.dart';
import '../../widgets/error_boundary_wrapper.dart';
import '../../widgets/shimmer_skeleton_loader.dart';

class CollaborativeVotingRoom extends StatefulWidget {
  const CollaborativeVotingRoom({super.key});

  @override
  State<CollaborativeVotingRoom> createState() =>
      _CollaborativeVotingRoomState();
}

class _CollaborativeVotingRoomState extends State<CollaborativeVotingRoom> {
  final CollaborativeVotingService _votingService =
      CollaborativeVotingService.instance;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _chatScrollController = ScrollController();

  bool _isLoading = true;
  bool _isSendingMessage = false;
  final String _roomId = 'room_001';
  final String _roomTitle = 'Community Budget Allocation 2026';
  int _activeParticipants = 0;
  final bool _isCreator = true;
  bool _showParticipants = false;
  String? _typingUser;
  Timer? _typingTimer;

  List<Map<String, dynamic>> _messages = [];
  List<Map<String, dynamic>> _participants = [];
  List<Map<String, dynamic>> _votingOptions = [];
  StreamSubscription? _messageSubscription;

  @override
  void initState() {
    super.initState();
    _initializeRoom();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _chatScrollController.dispose();
    _messageSubscription?.cancel();
    _typingTimer?.cancel();
    _votingService.leaveRoom(_roomId);
    super.dispose();
  }

  Future<void> _initializeRoom() async {
    setState(() => _isLoading = true);

    try {
      // Join room
      await _votingService.joinRoom(_roomId);

      // Load initial data
      final messages = await _votingService.getRoomMessages(_roomId);
      final participants = await _votingService.getRoomParticipants(_roomId);

      // Subscribe to real-time messages
      _messageSubscription = _votingService.getMessageStream(_roomId)?.listen((
        newMessage,
      ) {
        setState(() {
          _messages.add(newMessage);
        });
        _scrollToBottom();
      });

      setState(() {
        _messages = messages;
        _participants = participants;
        _activeParticipants = participants.length;
        _votingOptions = _getMockVotingOptions();
      });
    } catch (e) {
      debugPrint('Initialize room error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadData() async {
    await _initializeRoom();
  }

  List<Map<String, dynamic>> _getMockVotingOptions() {
    return [
      {
        'id': 'opt_1',
        'title': 'Education & Schools',
        'description': 'Allocate 40% to education infrastructure',
        'current_votes': 12,
        'percentage': 48.0,
        'suggestions': 3,
      },
      {
        'id': 'opt_2',
        'title': 'Public Transportation',
        'description': 'Allocate 30% to transit improvements',
        'current_votes': 8,
        'percentage': 32.0,
        'suggestions': 1,
      },
      {
        'id': 'opt_3',
        'title': 'Parks & Recreation',
        'description': 'Allocate 20% to green spaces',
        'current_votes': 5,
        'percentage': 20.0,
        'suggestions': 2,
      },
    ];
  }

  void _scrollToBottom() {
    if (_chatScrollController.hasClients) {
      _chatScrollController.animateTo(
        _chatScrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty || _isSendingMessage) return;

    setState(() => _isSendingMessage = true);

    final message = _messageController.text.trim();
    _messageController.clear();

    final success = await _votingService.sendMessage(
      roomId: _roomId,
      message: message,
    );

    if (!success && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to send message')));
    }

    setState(() => _isSendingMessage = false);
  }

  Future<void> _handleReaction(String messageId, String emoji) async {
    await _votingService.addReaction(messageId: messageId, emoji: emoji);
  }

  Future<void> _handleMuteParticipant(String userId) async {
    await _votingService.muteParticipant(roomId: _roomId, userId: userId);
  }

  @override
  Widget build(BuildContext context) {
    return ErrorBoundaryWrapper(
      screenName: 'CollaborativeVotingRoom',
      onRetry: _loadData,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: CustomAppBar(
          title: _roomTitle,
          variant: CustomAppBarVariant.withBack,
          onBackPressed: () => Navigator.of(context, rootNavigator: true).pop(),
          actions: [
            IconButton(
              icon: Badge(
                label: Text('$_activeParticipants'),
                child: Icon(Icons.people, size: 24.w),
              ),
              onPressed: () => setState(() => _showParticipants = true),
              tooltip: 'View Participants',
            ),
            if (_isCreator)
              IconButton(
                icon: Icon(Icons.settings, size: 24.w),
                onPressed: () => _showModerationControls(),
                tooltip: 'Moderation Controls',
              ),
          ],
        ),
        body: _isLoading
            ? const SkeletonDashboard()
            : Column(
                children: [
                  _buildRoomHeader(),
                  Expanded(flex: 60, child: _buildDiscussionPanel()),
                  const Divider(height: 1, thickness: 2),
                  Expanded(flex: 40, child: _buildVotingPanel()),
                ],
              ),
      ),
    );
  }

  Widget _buildRoomHeader() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.circle, color: Colors.green, size: 12.w),
          SizedBox(width: 2.w),
          Text(
            'Live Discussion',
            style: GoogleFonts.inter(
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          Spacer(),
          if (_typingUser != null)
            Text(
              '$_typingUser is typing...',
              style: GoogleFonts.inter(
                fontSize: 12.sp,
                fontStyle: FontStyle.italic,
                color: Colors.white,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDiscussionPanel() {
    return Column(
      children: [
        Expanded(
          child: _messages.isEmpty
              ? Center(
                  child: Text(
                    'No messages yet. Start the discussion!',
                    style: GoogleFonts.inter(
                      fontSize: 14.sp,
                      color: Colors.white,
                    ),
                  ),
                )
              : ListView.builder(
                  controller: _chatScrollController,
                  padding: EdgeInsets.all(3.w),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    return ChatMessageWidget(
                      message: _messages[index],
                      onReaction: (emoji) =>
                          _handleReaction(_messages[index]['id'], emoji),
                    );
                  },
                ),
        ),
        _buildMessageInput(),
      ],
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey.withValues(alpha: 0.2), width: 1),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Type your message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 4.w,
                  vertical: 1.5.h,
                ),
              ),
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          SizedBox(width: 2.w),
          IconButton(
            icon: _isSendingMessage
                ? SizedBox(
                    width: 20.w,
                    height: 20.w,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(Icons.send, color: Colors.white),
            onPressed: _isSendingMessage ? null : _sendMessage,
          ),
        ],
      ),
    );
  }

  Widget _buildVotingPanel() {
    return Container(
      color: Colors.grey.shade100.withValues(alpha: 0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(3.w),
            child: Row(
              children: [
                Text(
                  'Voting Options',
                  style: GoogleFonts.inter(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                Spacer(),
                Text(
                  '${_votingOptions.fold<int>(0, (sum, opt) => sum + (opt['current_votes'] as int))} total votes',
                  style: GoogleFonts.inter(
                    fontSize: 13.sp,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.symmetric(horizontal: 3.w),
              itemCount: _votingOptions.length,
              itemBuilder: (context, index) {
                return VotingOptionCardWidget(
                  option: _votingOptions[index],
                  roomId: _roomId,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showModerationControls() {
    showModalBottomSheet(
      context: context,
      builder: (context) => ModerationControlsWidget(
        roomId: _roomId,
        participants: _participants,
        onMuteParticipant: _handleMuteParticipant,
      ),
    );
  }
}
