import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../services/supabase_service.dart';
import '../../../widgets/shimmer_skeleton_loader.dart';

class WorkspaceActivityFeedWidget extends StatefulWidget {
  final String workspaceId;

  const WorkspaceActivityFeedWidget({super.key, required this.workspaceId});

  @override
  State<WorkspaceActivityFeedWidget> createState() =>
      _WorkspaceActivityFeedWidgetState();
}

class _WorkspaceActivityFeedWidgetState
    extends State<WorkspaceActivityFeedWidget> {
  final _client = SupabaseService.instance.client;

  bool _isLoading = true;
  List<Map<String, dynamic>> _activities = [];
  StreamSubscription? _activitySubscription;

  @override
  void initState() {
    super.initState();
    _loadActivities();
    _subscribeToActivities();
  }

  @override
  void dispose() {
    _activitySubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadActivities() async {
    setState(() => _isLoading = true);

    try {
      final response = await _client
          .from('workspace_activity')
          .select('*, user:user_profiles!user_id(*)')
          .eq('workspace_id', widget.workspaceId)
          .order('created_at', ascending: false)
          .limit(50);

      setState(() {
        _activities = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Load activities error: $e');
      setState(() => _isLoading = false);
    }
  }

  void _subscribeToActivities() {
    final channel = _client.channel('workspace_activity:${widget.workspaceId}');

    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'workspace_activity',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'workspace_id',
            value: widget.workspaceId,
          ),
          callback: (payload) {
            _loadActivities();
          },
        )
        .subscribe();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return ListView.builder(
        padding: EdgeInsets.all(4.w),
        itemCount: 10,
        itemBuilder: (context, index) {
          return Padding(
            padding: EdgeInsets.only(bottom: 2.h),
            child: SkeletonCard(height: 10.h, width: double.infinity),
          );
        },
      );
    }

    if (_activities.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            SizedBox(height: 2.h),
            Text('No Activity Yet', style: theme.textTheme.titleLarge),
            SizedBox(height: 1.h),
            Text(
              'Workspace activity will appear here',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadActivities,
      child: ListView.builder(
        padding: EdgeInsets.all(4.w),
        itemCount: _activities.length,
        itemBuilder: (context, index) {
          final activity = _activities[index];
          return _buildActivityCard(activity, theme);
        },
      ),
    );
  }

  Widget _buildActivityCard(Map<String, dynamic> activity, ThemeData theme) {
    final user = activity['user'];
    final userName = user != null
        ? (user['full_name'] ?? user['email'] ?? 'Unknown')
        : 'Unknown';
    final activityType = activity['activity_type'] ?? 'unknown';
    final description = activity['activity_description'] ?? '';
    final createdAt = DateTime.parse(activity['created_at']);

    IconData icon;
    Color iconColor;

    switch (activityType) {
      case 'annotation_added':
        icon = Icons.comment;
        iconColor = Colors.blue;
        break;
      case 'decision_created':
        icon = Icons.check_circle;
        iconColor = Colors.green;
        break;
      case 'insight_documented':
        icon = Icons.lightbulb;
        iconColor = Colors.amber;
        break;
      case 'dashboard_created':
        icon = Icons.dashboard;
        iconColor = Colors.purple;
        break;
      case 'member_added':
        icon = Icons.person_add;
        iconColor = Colors.teal;
        break;
      default:
        icon = Icons.circle;
        iconColor = Colors.grey;
    }

    return Card(
      margin: EdgeInsets.only(bottom: 2.h),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 10.w,
              height: 10.w,
              decoration: BoxDecoration(
                color: iconColor.withAlpha(51),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 5.w),
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      style: theme.textTheme.bodyMedium,
                      children: [
                        TextSpan(
                          text: userName,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        TextSpan(text: ' $description'),
                      ],
                    ),
                  ),
                  SizedBox(height: 0.5.h),
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
      ),
    );
  }
}
