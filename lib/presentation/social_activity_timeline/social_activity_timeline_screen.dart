import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/platform_analytics_service.dart';
import '../../services/supabase_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/error_boundary_wrapper.dart';

/// Social Activity Timeline: personalized feed (friend voting, achievements, likes, comments, shares) with filters.
class SocialActivityTimelineScreen extends StatefulWidget {
  const SocialActivityTimelineScreen({super.key});

  @override
  State<SocialActivityTimelineScreen> createState() =>
      _SocialActivityTimelineScreenState();
}

class _SocialActivityTimelineScreenState
    extends State<SocialActivityTimelineScreen> {
  final PlatformAnalyticsService _analytics =
      PlatformAnalyticsService.instance;
  final SupabaseService _supabase = SupabaseService.instance;

  bool _loading = true;
  bool _hasMore = true;
  int _offset = 0;
  static const int _pageSize = 20;
  String _activityType = 'all';
  String _timeRange = 'all';
  List<Map<String, dynamic>> _activities = [];
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadMore(reset: true);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        _hasMore &&
        !_loading) {
      _loadMore(reset: false);
    }
  }

  Future<void> _loadMore({bool reset = false}) async {
    if (_loading) return;
    if (reset) {
      _offset = 0;
      _hasMore = true;
      setState(() => _activities = []);
    }
    setState(() => _loading = true);
    try {
      final list = await _analytics.getActivityFeed(
        activityType: _activityType == 'all' ? null : _activityType,
        timeRange: _timeRange == 'all' ? null : _timeRange,
        limit: _pageSize,
        offset: _offset,
      );
      if (mounted) {
        setState(() {
          if (reset) {
            _activities = list;
          } else {
            _activities.addAll(list);
          }
          _offset += list.length;
          _hasMore = list.length >= _pageSize;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ErrorBoundaryWrapper(
      screenName: 'SocialActivityTimeline',
      onRetry: () => _loadMore(reset: true),
      child: Scaffold(
        backgroundColor: AppTheme.backgroundLight,
        appBar: CustomAppBar(
          title: 'Activity Feed',
          variant: CustomAppBarVariant.withBack,
        ),
        body: Column(
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
              child: Row(
                children: [
                  _chip('All', _activityType == 'all', () {
                    setState(() => _activityType = 'all');
                    _loadMore(reset: true);
                  }),
                  SizedBox(width: 2.w),
                  _chip('Vote', _activityType == 'vote', () {
                    setState(() => _activityType = 'vote');
                    _loadMore(reset: true);
                  }),
                  SizedBox(width: 2.w),
                  _chip('Achievement', _activityType == 'achievement', () {
                    setState(() => _activityType = 'achievement');
                    _loadMore(reset: true);
                  }),
                  SizedBox(width: 2.w),
                  _chip('Like', _activityType == 'like', () {
                    setState(() => _activityType = 'like');
                    _loadMore(reset: true);
                  }),
                  SizedBox(width: 2.w),
                  _chip('Comment', _activityType == 'comment', () {
                    setState(() => _activityType = 'comment');
                    _loadMore(reset: true);
                  }),
                ],
              ),
            ),
            Expanded(
              child: _loading && _activities.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : _activities.isEmpty
                      ? Center(
                          child: Text(
                            'No activity yet',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: AppTheme.textSecondaryLight,
                            ),
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: () => _loadMore(reset: true),
                          child: ListView.builder(
                            controller: _scrollController,
                            padding: EdgeInsets.symmetric(horizontal: 4.w),
                            itemCount: _activities.length + (_hasMore ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index >= _activities.length) {
                                return Padding(
                                  padding: EdgeInsets.symmetric(vertical: 2.h),
                                  child: const Center(
                                      child: SizedBox(
                                          width: 24,
                                          height: 24,
                                          child:
                                              CircularProgressIndicator())),
                                );
                              }
                              return _activityCard(
                                  theme, _activities[index]);
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
    );
  }

  Widget _activityCard(ThemeData theme, Map<String, dynamic> activity) {
    final type = activity['activity_type'] as String? ?? 'activity';
    final body = activity['body'] as String? ?? '';
    final createdAt = activity['created_at'] != null
        ? DateTime.tryParse(activity['created_at'].toString())
        : null;
    final actor = activity['actor'] as Map<String, dynamic>?;
    final name = actor?['name'] ?? actor?['username'] ?? 'Someone';

    IconData icon = Icons.notifications;
    if (type.contains('vote')) icon = Icons.how_to_vote;
    if (type.contains('achievement')) icon = Icons.emoji_events;
    if (type.contains('like')) icon = Icons.favorite;
    if (type.contains('comment')) icon = Icons.comment;

    return Card(
      margin: EdgeInsets.only(bottom: 1.5.h),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.primaryLight.withValues(alpha: 0.2),
          child: Icon(icon, color: AppTheme.primaryLight, size: 22.sp),
        ),
        title: Text(
          name,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13.sp,
          ),
        ),
        subtitle: Text(
          body.isNotEmpty ? body : type,
          style: TextStyle(fontSize: 12.sp),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: createdAt != null
            ? Text(
                _formatDate(createdAt),
                style: TextStyle(
                  fontSize: 10.sp,
                  color: AppTheme.textSecondaryLight,
                ),
              )
            : null,
      ),
    );
  }

  String _formatDate(DateTime d) {
    final now = DateTime.now();
    final diff = now.difference(d);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${d.month}/${d.day}';
  }
}
