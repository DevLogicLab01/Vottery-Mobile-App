import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../services/supabase_service.dart';
import '../../../services/auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ElectionCommentsWidget extends StatefulWidget {
  final String electionId;

  const ElectionCommentsWidget({super.key, required this.electionId});

  @override
  State<ElectionCommentsWidget> createState() => _ElectionCommentsWidgetState();
}

class _ElectionCommentsWidgetState extends State<ElectionCommentsWidget> {
  final _commentController = TextEditingController();
  final _client = SupabaseService.instance.client;
  final _auth = AuthService.instance;
  List<Map<String, dynamic>> _comments = [];
  bool _isLoading = true;
  bool _isSubmitting = false;
  RealtimeChannel? _channel;

  @override
  void initState() {
    super.initState();
    _loadComments();
    _subscribeToComments();
  }

  @override
  void dispose() {
    _commentController.dispose();
    _channel?.unsubscribe();
    super.dispose();
  }

  Future<void> _loadComments() async {
    try {
      final response = await _client
          .from('election_comments')
          .select('*, user_profiles(username, avatar_url)')
          .eq('election_id', widget.electionId)
          .order('created_at', ascending: true)
          .limit(50);
      if (mounted) {
        setState(() {
          _comments = List<Map<String, dynamic>>.from(response);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Load comments error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _subscribeToComments() {
    try {
      _channel = _client
          .channel('election_comments_${widget.electionId}')
          .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: 'election_comments',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'election_id',
              value: widget.electionId,
            ),
            callback: (_) => _loadComments(),
          )
          .subscribe();
    } catch (e) {
      debugPrint('Subscribe comments error: $e');
    }
  }

  Future<void> _submitComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty || !_auth.isAuthenticated) return;

    setState(() => _isSubmitting = true);
    try {
      await _client.from('election_comments').insert({
        'election_id': widget.electionId,
        'user_id': _auth.currentUser!.id,
        'content': text,
      });
      _commentController.clear();
      await _loadComments();
    } catch (e) {
      debugPrint('Submit comment error: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Failed to post comment')));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w),
          child: Text(
            'Comments',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ),
        SizedBox(height: 1.h),
        // Comment Input
        if (_auth.isAuthenticated)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: InputDecoration(
                      hintText: 'Add a comment...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 3.w,
                        vertical: 1.h,
                      ),
                    ),
                    maxLines: 2,
                    minLines: 1,
                    style: TextStyle(fontSize: 12.sp),
                  ),
                ),
                SizedBox(width: 2.w),
                _isSubmitting
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : IconButton(
                        onPressed: _submitComment,
                        icon: const Icon(Icons.send),
                        color: theme.colorScheme.primary,
                      ),
              ],
            ),
          ),
        SizedBox(height: 1.h),
        // Comments List
        _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _comments.isEmpty
            ? Padding(
                padding: EdgeInsets.all(4.w),
                child: Text(
                  'No comments yet. Be the first!',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: theme.colorScheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              )
            : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _comments.length,
                itemBuilder: (context, index) {
                  final comment = _comments[index];
                  final profile = comment['user_profiles'] as Map?;
                  final username =
                      profile?['username'] as String? ?? 'Anonymous';
                  final avatarUrl = profile?['avatar_url'] as String?;
                  final content = comment['content'] as String? ?? '';
                  return ListTile(
                    leading: CircleAvatar(
                      radius: 16,
                      backgroundImage: avatarUrl != null
                          ? NetworkImage(avatarUrl)
                          : null,
                      child: avatarUrl == null
                          ? Text(
                              username.isNotEmpty
                                  ? username[0].toUpperCase()
                                  : 'A',
                              style: const TextStyle(fontSize: 12),
                            )
                          : null,
                    ),
                    title: Text(
                      username,
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(content, style: TextStyle(fontSize: 11.sp)),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 4.w,
                      vertical: 0,
                    ),
                  );
                },
              ),
      ],
    );
  }
}