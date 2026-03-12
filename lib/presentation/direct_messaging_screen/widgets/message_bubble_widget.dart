import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class MessageBubbleWidget extends StatelessWidget {
  final Map<String, dynamic> message;
  final bool isMe;
  final Function(String emoji) onReaction;

  const MessageBubbleWidget({
    super.key,
    required this.message,
    required this.isMe,
    required this.onReaction,
  });

  bool get _isVoice =>
      message['message_type'] == 'voice' ||
      (message['media_url'] != null && (message['content'] as String? ?? '').isEmpty);

  @override
  Widget build(BuildContext context) {
    if (_isVoice) {
      return Padding(
        padding: EdgeInsets.only(bottom: 1.5.h),
        child: Row(
          mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!isMe) _buildAvatar(context),
            if (!isMe) SizedBox(width: 2.w),
            Flexible(
              child: GestureDetector(
                onLongPress: () => _showReactionPicker(context),
                child: _VoiceBubble(
                  mediaUrl: message['media_url'] as String? ?? '',
                  isMe: isMe,
                  createdAt: message['created_at'],
                  content: message['content'] as String? ?? '',
                ),
              ),
            ),
          ],
        ),
      );
    }

    final theme = Theme.of(context);
    final content = message['content'] ?? '';
    final timestamp = message['created_at'] != null
        ? DateTime.parse(message['created_at'])
        : DateTime.now();
    final timeString =
        '${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
    final readBy = message['read_by'] as List? ?? [];
    final isRead = readBy.isNotEmpty;

    return Padding(
      padding: EdgeInsets.only(bottom: 1.5.h),
      child: Row(
        mainAxisAlignment: isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) _buildAvatar(context),
          if (!isMe) SizedBox(width: 2.w),
          Flexible(
            child: GestureDetector(
              onLongPress: () => _showReactionPicker(context),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                decoration: BoxDecoration(
                  color: isMe
                      ? theme.colorScheme.primary
                      : theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(12.0),
                    topRight: Radius.circular(12.0),
                    bottomLeft: Radius.circular(isMe ? 12.0 : 0),
                    bottomRight: Radius.circular(isMe ? 0 : 12.0),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      content,
                      style: GoogleFonts.inter(
                        fontSize: 13.sp,
                        color: isMe
                            ? theme.colorScheme.onPrimary
                            : theme.colorScheme.onSurface,
                      ),
                    ),
                    SizedBox(height: 0.5.h),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          timeString,
                          style: GoogleFonts.inter(
                            fontSize: 10.sp,
                            color: isMe
                                ? theme.colorScheme.onPrimary.withValues(
                                    alpha: 0.7,
                                  )
                                : theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        if (isMe) ...[
                          SizedBox(width: 1.w),
                          Icon(
                            isRead ? Icons.done_all : Icons.done,
                            size: 4.w,
                            color: isRead
                                ? AppTheme.accentLight
                                : theme.colorScheme.onPrimary.withValues(
                                    alpha: 0.7,
                                  ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(BuildContext context) {
    final theme = Theme.of(context);
    return CircleAvatar(
      radius: 4.w,
      backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.2),
      child: Text(
        'U',
        style: GoogleFonts.inter(
          fontSize: 11.sp,
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }

  void _showReactionPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: EdgeInsets.all(4.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'React to message',
              style: GoogleFonts.inter(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 2.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: ['👍', '❤️', '😂', '😮', '😢', '🔥'].map((emoji) {
                return GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    onReaction(emoji);
                  },
                  child: Text(emoji, style: TextStyle(fontSize: 30.sp)),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

/// Parses duration from content like "Voice message • 0:15" or "Voice message • 1:02".
String? _parseDurationFromContent(String content) {
  const separator = ' • ';
  final idx = content.lastIndexOf(separator);
  if (idx == -1) return null;
  final part = content.substring(idx + separator.length).trim();
  if (RegExp(r'^\d{1,2}:\d{2}$').hasMatch(part)) return part;
  return null;
}

/// Voice message bubble with play/pause and duration.
class _VoiceBubble extends StatefulWidget {
  final String mediaUrl;
  final bool isMe;
  final dynamic createdAt;
  final String content;

  const _VoiceBubble({
    required this.mediaUrl,
    required this.isMe,
    this.createdAt,
    this.content = '',
  });

  @override
  State<_VoiceBubble> createState() => _VoiceBubbleState();
}

class _VoiceBubbleState extends State<_VoiceBubble> {
  final AudioPlayer _player = AudioPlayer();
  bool _playing = false;
  Duration? _loadedDuration;

  String? get _durationLabel {
    final fromContent = _parseDurationFromContent(widget.content);
    if (fromContent != null) return fromContent;
    if (_loadedDuration != null) {
      final s = _loadedDuration!.inSeconds;
      final m = s ~/ 60;
      final sec = s % 60;
      return '${m.toString().padLeft(1, '0')}:${sec.toString().padLeft(2, '0')}';
    }
    return null;
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _togglePlay() async {
    if (widget.mediaUrl.isEmpty) return;
    if (_playing) {
      await _player.pause();
    } else {
      await _player.play(UrlSource(widget.mediaUrl));
    }
    setState(() => _playing = !_playing);
  }

  @override
  void initState() {
    super.initState();
    _player.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _playing = false);
    });
    _player.onDurationChanged.listen((d) {
      if (mounted) setState(() => _loadedDuration = d);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.5.h),
      decoration: BoxDecoration(
        color: widget.isMe
            ? theme.colorScheme.primary
            : theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
          bottomLeft: Radius.circular(widget.isMe ? 12 : 0),
          bottomRight: Radius.circular(widget.isMe ? 0 : 12),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(
              _playing ? Icons.pause : Icons.play_arrow,
              color: widget.isMe
                  ? theme.colorScheme.onPrimary
                  : theme.colorScheme.onSurface,
              size: 28.sp,
            ),
            onPressed: _togglePlay,
          ),
          SizedBox(width: 2.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Voice message',
                style: GoogleFonts.inter(
                  fontSize: 13.sp,
                  color: widget.isMe
                      ? theme.colorScheme.onPrimary
                      : theme.colorScheme.onSurface,
                ),
              ),
              if (_durationLabel != null) ...[
                SizedBox(height: 0.3.h),
                Text(
                  _durationLabel!,
                  style: GoogleFonts.inter(
                    fontSize: 11.sp,
                    color: widget.isMe
                        ? theme.colorScheme.onPrimary.withValues(alpha: 0.8)
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
