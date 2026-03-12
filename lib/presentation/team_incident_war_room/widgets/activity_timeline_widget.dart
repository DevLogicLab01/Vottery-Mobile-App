import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../services/supabase_service.dart';

class ActivityTimelineWidget extends StatefulWidget {
  final String roomId;

  const ActivityTimelineWidget({super.key, required this.roomId});

  @override
  State<ActivityTimelineWidget> createState() => _ActivityTimelineWidgetState();
}

class _ActivityTimelineWidgetState extends State<ActivityTimelineWidget> {
  final _supabase = SupabaseService.instance.client;
  List<Map<String, dynamic>> _activities = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadActivities();
  }

  Future<void> _loadActivities() async {
    setState(() => _isLoading = true);

    try {
      final response = await _supabase
          .from('war_room_activity')
          .select()
          .eq('room_id', widget.roomId)
          .order('created_at', ascending: false)
          .limit(100);

      setState(() {
        _activities = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Load activities error: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_activities.isEmpty) {
      return Center(
        child: Text(
          'No activity yet',
          style: TextStyle(fontSize: 12.sp, color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(2.w),
      itemCount: _activities.length,
      itemBuilder: (context, index) {
        final activity = _activities[index];
        return _buildActivityItem(activity);
      },
    );
  }

  Widget _buildActivityItem(Map<String, dynamic> activity) {
    final activityType = activity['activity_type'] as String;
    final description = activity['description'] as String;
    final createdAt = DateTime.parse(activity['created_at']);

    final icon = _getActivityIcon(activityType);
    final color = _getActivityColor(activityType);

    return Padding(
      padding: EdgeInsets.only(bottom: 2.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline indicator
          Column(
            children: [
              Container(
                width: 40.0,
                height: 40.0,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withAlpha(51),
                ),
                child: Icon(icon, color: color, size: 20.sp),
              ),
              if (activity != _activities.last)
                Container(width: 2.0, height: 40.0, color: Colors.grey[300]),
            ],
          ),
          SizedBox(width: 3.w),
          // Activity content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 0.5.h),
                Text(
                  timeago.format(createdAt),
                  style: TextStyle(fontSize: 10.sp, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getActivityIcon(String activityType) {
    switch (activityType) {
      case 'war_room_created':
        return Icons.add_circle;
      case 'team_member_joined':
        return Icons.person_add;
      case 'message_sent':
        return Icons.message;
      case 'task_created':
        return Icons.task;
      case 'task_completed':
        return Icons.check_circle;
      case 'decision_made':
        return Icons.gavel;
      case 'evidence_added':
        return Icons.attach_file;
      case 'escalation':
        return Icons.warning;
      case 'war_room_closed':
        return Icons.check;
      default:
        return Icons.info;
    }
  }

  Color _getActivityColor(String activityType) {
    switch (activityType) {
      case 'war_room_created':
        return Colors.blue;
      case 'team_member_joined':
        return Colors.green;
      case 'message_sent':
        return Colors.purple;
      case 'task_created':
      case 'task_completed':
        return Colors.orange;
      case 'decision_made':
        return Colors.indigo;
      case 'evidence_added':
        return Colors.teal;
      case 'escalation':
        return Colors.red;
      case 'war_room_closed':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}
