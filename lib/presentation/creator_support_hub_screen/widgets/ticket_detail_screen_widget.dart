import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../services/support_ticket_service.dart';
import '../../../services/auth_service.dart';
import '../../../widgets/shimmer_skeleton_loader.dart';

class TicketDetailScreenWidget extends StatefulWidget {
  final String ticketId;

  const TicketDetailScreenWidget({super.key, required this.ticketId});

  @override
  State<TicketDetailScreenWidget> createState() =>
      _TicketDetailScreenWidgetState();
}

class _TicketDetailScreenWidgetState extends State<TicketDetailScreenWidget> {
  final SupportTicketService _service = SupportTicketService.instance;
  final _auth = AuthService.instance;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  Map<String, dynamic>? _ticket;
  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _loadTicketDetails();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadTicketDetails() async {
    setState(() => _isLoading = true);

    try {
      final ticket = await _service.getTicketDetails(widget.ticketId);
      final messages = await _service.getTicketMessages(widget.ticketId);

      setState(() {
        _ticket = ticket;
        _messages = messages;
        _isLoading = false;
      });

      _scrollToBottom();
    } catch (e) {
      debugPrint('Load ticket details error: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    setState(() => _isSending = true);

    try {
      final success = await _service.sendTicketMessage(
        ticketId: widget.ticketId,
        message: _messageController.text,
      );

      if (success) {
        _messageController.clear();
        await _loadTicketDetails();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to send message'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      debugPrint('Send message error: $e');
    } finally {
      setState(() => _isSending = false);
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

  Color _getStatusColor(String status) {
    switch (status) {
      case 'open':
        return Colors.orange;
      case 'in_progress':
        return Colors.blue;
      case 'resolved':
        return Colors.green;
      case 'closed':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Ticket Details')),
        body: const SkeletonList(itemCount: 6),
      );
    }

    if (_ticket == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Ticket Details')),
        body: const Center(child: Text('Ticket not found')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        title: Text(
          'Ticket #${_ticket!['ticket_number'] ?? _ticket!['id'].toString().substring(0, 8)}',
          style: GoogleFonts.inter(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          Container(
            margin: EdgeInsets.only(right: 4.w),
            padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
            decoration: BoxDecoration(
              color: _getStatusColor(_ticket!['status']).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Text(
              _ticket!['status'].toString().toUpperCase(),
              style: GoogleFonts.inter(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: _getStatusColor(_ticket!['status']),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Ticket info
          Container(
            padding: EdgeInsets.all(4.w),
            color: theme.colorScheme.surface,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _ticket!['subject'] ?? 'No subject',
                  style: GoogleFonts.inter(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
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
                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6.0),
                      ),
                      child: Text(
                        _ticket!['category'] ?? 'General',
                        style: GoogleFonts.inter(
                          fontSize: 11.sp,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                    SizedBox(width: 2.w),
                    Text(
                      'Priority: ${_ticket!['priority'] ?? 'Medium'}',
                      style: GoogleFonts.inter(
                        fontSize: 11.sp,
                        color: Colors.grey,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      timeago.format(DateTime.parse(_ticket!['created_at'])),
                      style: GoogleFonts.inter(
                        fontSize: 11.sp,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: EdgeInsets.all(4.w),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                final isUser = message['sender_type'] == 'user';
                return _buildMessageBubble(message, isUser);
              },
            ),
          ),

          // Input bar
          if (_ticket!['status'] != 'closed')
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
                        hintText: 'Type your message...',
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
                    ),
                  ),
                  SizedBox(width: 2.w),
                  IconButton(
                    onPressed: _isSending ? null : _sendMessage,
                    icon: _isSending
                        ? const CircularProgressIndicator()
                        : Icon(Icons.send, color: theme.colorScheme.primary),
                    iconSize: 24.sp,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> message, bool isUser) {
    final theme = Theme.of(context);
    final timestamp = DateTime.parse(message['created_at']);

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
            Container(
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: isUser
                    ? theme.colorScheme.primary
                    : theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Text(
                message['message'] ?? '',
                style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  color: isUser ? Colors.white : Colors.black,
                ),
              ),
            ),
            SizedBox(height: 0.5.h),
            Text(
              timeago.format(timestamp),
              style: GoogleFonts.inter(fontSize: 10.sp, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
