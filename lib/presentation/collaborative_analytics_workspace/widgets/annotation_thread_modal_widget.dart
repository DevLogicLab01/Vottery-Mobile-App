import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../services/supabase_service.dart';
import '../../../services/auth_service.dart';

class AnnotationThreadModalWidget extends StatefulWidget {
  final Map<String, dynamic> annotation;

  const AnnotationThreadModalWidget({super.key, required this.annotation});

  @override
  State<AnnotationThreadModalWidget> createState() =>
      _AnnotationThreadModalWidgetState();
}

class _AnnotationThreadModalWidgetState
    extends State<AnnotationThreadModalWidget> {
  final _client = SupabaseService.instance.client;
  final _auth = AuthService.instance;
  final _replyController = TextEditingController();

  List<Map<String, dynamic>> _replies = [];
  Map<String, int> _reactions = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadThreadData();
  }

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  Future<void> _loadThreadData() async {
    setState(() => _isLoading = true);

    try {
      final replies = await _client
          .from('annotation_threads')
          .select('*, user:user_profiles!user_id(*)')
          .eq('annotation_id', widget.annotation['id'])
          .order('created_at', ascending: true);

      final reactions = await _client
          .from('annotation_reactions')
          .select('emoji')
          .eq('annotation_id', widget.annotation['id']);

      final reactionCounts = <String, int>{};
      for (var reaction in reactions) {
        final emoji = reaction['emoji'] as String;
        reactionCounts[emoji] = (reactionCounts[emoji] ?? 0) + 1;
      }

      setState(() {
        _replies = List<Map<String, dynamic>>.from(replies);
        _reactions = reactionCounts;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Load thread data error: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addReply() async {
    if (_replyController.text.trim().isEmpty) return;

    try {
      await _client.from('annotation_threads').insert({
        'annotation_id': widget.annotation['id'],
        'user_id': _auth.currentUser!.id,
        'comment_text': _replyController.text.trim(),
      });

      _replyController.clear();
      await _loadThreadData();
    } catch (e) {
      debugPrint('Add reply error: $e');
    }
  }

  Future<void> _addReaction(String emoji) async {
    try {
      await _client.from('annotation_reactions').insert({
        'annotation_id': widget.annotation['id'],
        'user_id': _auth.currentUser!.id,
        'emoji': emoji,
      });

      await _loadThreadData();
    } catch (e) {
      debugPrint('Add reaction error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(20.0),
            ),
          ),
          child: Column(
            children: [
              Container(
                margin: EdgeInsets.symmetric(vertical: 1.h),
                width: 10.w,
                height: 0.5.h,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurfaceVariant.withAlpha(77),
                  borderRadius: BorderRadius.circular(2.0),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Annotation Thread',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: theme.dividerColor),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ListView(
                        controller: scrollController,
                        padding: EdgeInsets.all(4.w),
                        children: [
                          _buildAnnotationHeader(theme),
                          SizedBox(height: 2.h),
                          _buildReactions(theme),
                          SizedBox(height: 3.h),
                          if (_replies.isNotEmpty) ..._buildReplies(theme),
                        ],
                      ),
              ),
              _buildReplyInput(theme),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAnnotationHeader(ThemeData theme) {
    final annotationType = widget.annotation['annotation_type'] ?? 'insight';
    final priority = widget.annotation['priority'] ?? 'medium';

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildTypeBadge(annotationType, theme),
              SizedBox(width: 2.w),
              _buildPriorityBadge(priority, theme),
            ],
          ),
          SizedBox(height: 2.h),
          Text(
            widget.annotation['annotation_text'] ?? '',
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildTypeBadge(String type, ThemeData theme) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Text(
        type.toUpperCase(),
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onPrimaryContainer,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildPriorityBadge(String priority, ThemeData theme) {
    Color color;
    switch (priority) {
      case 'critical':
        color = Colors.purple;
        break;
      case 'high':
        color = Colors.red;
        break;
      case 'medium':
        color = Colors.orange;
        break;
      default:
        color = Colors.green;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
      decoration: BoxDecoration(
        color: color.withAlpha(51),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Text(
        priority.toUpperCase(),
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildReactions(ThemeData theme) {
    final reactionEmojis = ['👍', '❤️', '💡', '❓', '✅'];

    return Wrap(
      spacing: 2.w,
      runSpacing: 1.h,
      children: [
        ...reactionEmojis.map((emoji) {
          final count = _reactions[emoji] ?? 0;
          return GestureDetector(
            onTap: () => _addReaction(emoji),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
              decoration: BoxDecoration(
                color: count > 0
                    ? theme.colorScheme.primaryContainer
                    : theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(20.0),
                border: Border.all(
                  color: count > 0
                      ? theme.colorScheme.primary
                      : theme.dividerColor,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(emoji, style: TextStyle(fontSize: 14.sp)),
                  if (count > 0) ...[
                    SizedBox(width: 1.w),
                    Text(
                      count.toString(),
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  List<Widget> _buildReplies(ThemeData theme) {
    return [
      Text(
        'Replies (${_replies.length})',
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      SizedBox(height: 2.h),
      ..._replies.map((reply) {
        final user = reply['user'];
        final userName = user != null
            ? (user['full_name'] ?? user['email'] ?? 'Unknown')
            : 'Unknown';
        final createdAt = DateTime.parse(reply['created_at']);

        return Container(
          margin: EdgeInsets.only(bottom: 2.h),
          padding: EdgeInsets.all(3.w),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12.0),
            border: Border.all(color: theme.dividerColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 4.w,
                    child: Text(userName[0].toUpperCase()),
                  ),
                  SizedBox(width: 2.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userName,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          timeago.format(createdAt),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 1.h),
              Text(
                reply['comment_text'] ?? '',
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        );
      }),
    ];
  }

  Widget _buildReplyInput(ThemeData theme) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(top: BorderSide(color: theme.dividerColor)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _replyController,
              decoration: InputDecoration(
                hintText: 'Add a reply...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24.0),
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
          IconButton(icon: const Icon(Icons.send), onPressed: _addReply),
        ],
      ),
    );
  }
}
