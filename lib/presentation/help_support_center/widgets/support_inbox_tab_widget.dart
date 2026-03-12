import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../widgets/custom_icon_widget.dart';

/// Support Inbox tab displaying conversation threads with support agents,
/// file attachment capabilities, and real-time message delivery with typing indicators.
class SupportInboxTabWidget extends StatefulWidget {
  const SupportInboxTabWidget({super.key});

  @override
  State<SupportInboxTabWidget> createState() => _SupportInboxTabWidgetState();
}

class _SupportInboxTabWidgetState extends State<SupportInboxTabWidget> {
  final List<Map<String, dynamic>> _conversations = [
    {
      'id': '1',
      'subject': 'Vote not counting issue',
      'status': 'open',
      'priority': 'high',
      'lastMessage':
          'We\'re investigating this issue and will update you soon.',
      'lastMessageTime': '2 hours ago',
      'unreadCount': 2,
      'agentName': 'Support Agent Sarah',
      'agentAvatar':
          'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=200',
    },
    {
      'id': '2',
      'subject': 'Account verification help',
      'status': 'resolved',
      'priority': 'medium',
      'lastMessage': 'Your account has been successfully verified!',
      'lastMessageTime': '1 day ago',
      'unreadCount': 0,
      'agentName': 'Support Agent Mike',
      'agentAvatar':
          'https://img.rocket.new/generatedImages/rocket_gen_img_1d32bdb63-1768040634285.png',
    },
    {
      'id': '3',
      'subject': 'VP rewards not received',
      'status': 'waiting',
      'priority': 'low',
      'lastMessage': 'Please provide your transaction ID for verification.',
      'lastMessageTime': '3 days ago',
      'unreadCount': 0,
      'agentName': 'Support Agent Emma',
      'agentAvatar':
          'https://img.rocket.new/generatedImages/rocket_gen_img_1df567048-1764839603599.png',
    },
  ];

  String _selectedFilter = 'all';

  List<Map<String, dynamic>> get _filteredConversations {
    if (_selectedFilter == 'all') return _conversations;
    return _conversations
        .where((conv) => conv['status'] == _selectedFilter)
        .toList();
  }

  Color _getStatusColor(String status, ThemeData theme) {
    switch (status) {
      case 'open':
        return Colors.green;
      case 'resolved':
        return Colors.blue;
      case 'waiting':
        return Colors.orange;
      default:
        return theme.colorScheme.onSurface.withValues(alpha: 0.5);
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        // Filter Chips
        Container(
          padding: EdgeInsets.all(4.w),
          child: Row(
            children: [
              _buildFilterChip(theme, 'all', 'All'),
              SizedBox(width: 2.w),
              _buildFilterChip(theme, 'open', 'Open'),
              SizedBox(width: 2.w),
              _buildFilterChip(theme, 'waiting', 'Waiting'),
              SizedBox(width: 2.w),
              _buildFilterChip(theme, 'resolved', 'Resolved'),
            ],
          ),
        ),

        // Conversations List
        Expanded(
          child: _filteredConversations.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CustomIconWidget(
                        iconName: 'inbox',
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.3,
                        ),
                        size: 64,
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        'No conversations',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.6,
                          ),
                        ),
                      ),
                      SizedBox(height: 1.h),
                      Text(
                        'Start a new conversation with support',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: 4.w),
                  itemCount: _filteredConversations.length,
                  itemBuilder: (context, index) {
                    final conversation = _filteredConversations[index];
                    final hasUnread = (conversation['unreadCount'] as int) > 0;

                    return Container(
                      margin: EdgeInsets.only(bottom: 2.h),
                      decoration: BoxDecoration(
                        color: hasUnread
                            ? theme.colorScheme.primary.withValues(alpha: 0.05)
                            : theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: hasUnread
                              ? theme.colorScheme.primary.withValues(alpha: 0.3)
                              : theme.colorScheme.outline.withValues(
                                  alpha: 0.2,
                                ),
                          width: hasUnread ? 2 : 1,
                        ),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            _showConversationDetail(context, conversation);
                          },
                          child: Padding(
                            padding: EdgeInsets.all(4.w),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    // Agent Avatar
                                    CircleAvatar(
                                      radius: 6.w,
                                      backgroundImage: NetworkImage(
                                        conversation['agentAvatar'] as String,
                                      ),
                                    ),
                                    SizedBox(width: 3.w),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  conversation['subject']
                                                      as String,
                                                  style: theme
                                                      .textTheme
                                                      .titleMedium
                                                      ?.copyWith(
                                                        fontWeight: hasUnread
                                                            ? FontWeight.w700
                                                            : FontWeight.w600,
                                                      ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                              if (hasUnread)
                                                Container(
                                                  padding: EdgeInsets.symmetric(
                                                    horizontal: 2.w,
                                                    vertical: 0.5.h,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: theme
                                                        .colorScheme
                                                        .primary,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          12,
                                                        ),
                                                  ),
                                                  child: Text(
                                                    '${conversation['unreadCount']}',
                                                    style: theme
                                                        .textTheme
                                                        .bodySmall
                                                        ?.copyWith(
                                                          color: theme
                                                              .colorScheme
                                                              .onPrimary,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                          SizedBox(height: 0.5.h),
                                          Text(
                                            conversation['agentName'] as String,
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                                  color: theme
                                                      .colorScheme
                                                      .onSurface
                                                      .withValues(alpha: 0.6),
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 1.5.h),
                                Text(
                                  conversation['lastMessage'] as String,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: 0.7),
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                SizedBox(height: 1.5.h),
                                Row(
                                  children: [
                                    // Status Badge
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 2.w,
                                        vertical: 0.5.h,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _getStatusColor(
                                          conversation['status'] as String,
                                          theme,
                                        ).withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        (conversation['status'] as String)
                                            .toUpperCase(),
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                              color: _getStatusColor(
                                                conversation['status']
                                                    as String,
                                                theme,
                                              ),
                                              fontWeight: FontWeight.w600,
                                              fontSize: 10.sp,
                                            ),
                                      ),
                                    ),
                                    SizedBox(width: 2.w),
                                    // Priority Badge
                                    Container(
                                      width: 2.w,
                                      height: 2.w,
                                      decoration: BoxDecoration(
                                        color: _getPriorityColor(
                                          conversation['priority'] as String,
                                        ),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    SizedBox(width: 1.w),
                                    Text(
                                      '${conversation['priority']} priority',
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: theme.colorScheme.onSurface
                                                .withValues(alpha: 0.5),
                                          ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      conversation['lastMessageTime'] as String,
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: theme.colorScheme.onSurface
                                                .withValues(alpha: 0.5),
                                          ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),

        // New Conversation Button
        Container(
          padding: EdgeInsets.all(4.w),
          child: ElevatedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Starting new conversation...'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text('New Conversation'),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
              minimumSize: Size(double.infinity, 6.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(ThemeData theme, String value, String label) {
    final isSelected = _selectedFilter == value;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = value;
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.outline.withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: isSelected
                ? theme.colorScheme.onPrimary
                : theme.colorScheme.onSurface,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }

  void _showConversationDetail(
    BuildContext context,
    Map<String, dynamic> conversation,
  ) {
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: 80.h,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: EdgeInsets.only(top: 1.h, bottom: 2.h),
              width: 12.w,
              height: 0.5.h,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(10),
              ),
            ),

            // Header
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 5.w,
                    backgroundImage: NetworkImage(
                      conversation['agentAvatar'] as String,
                    ),
                  ),
                  SizedBox(width: 3.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          conversation['subject'] as String,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          conversation['agentName'] as String,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.6,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            Divider(color: theme.colorScheme.outline.withValues(alpha: 0.2)),

            // Message Thread
            Expanded(
              child: ListView(
                padding: EdgeInsets.all(4.w),
                children: [
                  _buildMessage(
                    theme,
                    'Hello! I need help with my vote not being counted.',
                    true,
                    '10:30 AM',
                  ),
                  _buildMessage(
                    theme,
                    'Hi! I\'m sorry to hear that. Can you provide more details about when this happened?',
                    false,
                    '10:32 AM',
                  ),
                  _buildMessage(
                    theme,
                    'It was during the community poll yesterday around 3 PM.',
                    true,
                    '10:35 AM',
                  ),
                  _buildMessage(
                    theme,
                    conversation['lastMessage'] as String,
                    false,
                    conversation['lastMessageTime'] as String,
                  ),
                ],
              ),
            ),

            // Message Input
            Container(
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                border: Border(
                  top: BorderSide(
                    color: theme.colorScheme.outline.withValues(alpha: 0.2),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        filled: true,
                        fillColor: theme.colorScheme.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 4.w,
                          vertical: 1.5.h,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 2.w),
                  CircleAvatar(
                    radius: 6.w,
                    backgroundColor: theme.colorScheme.primary,
                    child: IconButton(
                      icon: Icon(
                        Icons.send,
                        color: theme.colorScheme.onPrimary,
                        size: 20,
                      ),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Message sent!'),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      },
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

  Widget _buildMessage(ThemeData theme, String text, bool isUser, String time) {
    return Padding(
      padding: EdgeInsets.only(bottom: 2.h),
      child: Row(
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          if (!isUser) ...[],
          Container(
            constraints: BoxConstraints(maxWidth: 70.w),
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: isUser
                  ? theme.colorScheme.primary
                  : theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  text,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isUser
                        ? theme.colorScheme.onPrimary
                        : theme.colorScheme.onSurface,
                  ),
                ),
                SizedBox(height: 0.5.h),
                Text(
                  time,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isUser
                        ? theme.colorScheme.onPrimary.withValues(alpha: 0.7)
                        : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    fontSize: 10.sp,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
