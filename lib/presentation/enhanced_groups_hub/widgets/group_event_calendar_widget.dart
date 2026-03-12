import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

/// Group Event Calendar Widget - Event scheduling and management
class GroupEventCalendarWidget extends StatefulWidget {
  final String groupId;

  const GroupEventCalendarWidget({super.key, required this.groupId});

  @override
  State<GroupEventCalendarWidget> createState() =>
      _GroupEventCalendarWidgetState();
}

class _GroupEventCalendarWidgetState extends State<GroupEventCalendarWidget> {
  List<Map<String, dynamic>> _upcomingEvents = [];

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  void _loadEvents() {
    setState(() {
      _upcomingEvents = [
        {
          'id': 'event_1',
          'title': 'Community Town Hall',
          'date': '2026-02-15',
          'time': '6:00 PM',
          'location': 'Virtual',
          'rsvp_count': 245,
          'description': 'Discuss upcoming local elections and policy changes',
        },
        {
          'id': 'event_2',
          'title': 'Voter Registration Drive',
          'date': '2026-02-20',
          'time': '10:00 AM',
          'location': 'City Hall',
          'rsvp_count': 128,
          'description': 'Help register new voters in our community',
        },
      ];
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.groupId.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_outlined,
              size: 20.w,
              color: AppTheme.textSecondaryLight,
            ),
            SizedBox(height: 2.h),
            Text(
              'Select a group to view events',
              style: TextStyle(
                fontSize: 14.sp,
                color: AppTheme.textSecondaryLight,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Create Event Button
        Container(
          color: Colors.white,
          padding: EdgeInsets.all(4.w),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _showCreateEventDialog,
              icon: Icon(Icons.add, size: 6.w),
              label: Text('Create Event'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryLight,
                padding: EdgeInsets.symmetric(vertical: 1.5.h),
              ),
            ),
          ),
        ),

        // Events List
        Expanded(
          child: _upcomingEvents.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.event_busy,
                        size: 20.w,
                        color: AppTheme.textSecondaryLight,
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        'No upcoming events',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimaryLight,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: EdgeInsets.all(4.w),
                  itemCount: _upcomingEvents.length,
                  separatorBuilder: (context, index) => SizedBox(height: 2.h),
                  itemBuilder: (context, index) {
                    final event = _upcomingEvents[index];
                    return _buildEventCard(event);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildEventCard(Map<String, dynamic> event) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: AppTheme.shadowLight,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: AppTheme.primaryLight.withAlpha(26),
              borderRadius: BorderRadius.vertical(top: Radius.circular(12.0)),
            ),
            child: Row(
              children: [
                Icon(Icons.event, color: AppTheme.primaryLight, size: 6.w),
                SizedBox(width: 3.w),
                Expanded(
                  child: Text(
                    event['title'],
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimaryLight,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(4.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 4.w,
                      color: AppTheme.textSecondaryLight,
                    ),
                    SizedBox(width: 2.w),
                    Text(
                      '${event['date']} at ${event['time']}',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: AppTheme.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 1.h),
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 4.w,
                      color: AppTheme.textSecondaryLight,
                    ),
                    SizedBox(width: 2.w),
                    Text(
                      event['location'],
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: AppTheme.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 1.5.h),
                Text(
                  event['description'],
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: AppTheme.textPrimaryLight,
                  ),
                ),
                SizedBox(height: 2.h),
                Row(
                  children: [
                    Icon(Icons.people, size: 4.w, color: AppTheme.accentLight),
                    SizedBox(width: 1.w),
                    Text(
                      '${event['rsvp_count']} going',
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.accentLight,
                      ),
                    ),
                    Spacer(),
                    ElevatedButton(
                      onPressed: () => _rsvpToEvent(event['id']),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryLight,
                        padding: EdgeInsets.symmetric(
                          horizontal: 6.w,
                          vertical: 1.h,
                        ),
                      ),
                      child: Text(
                        'RSVP',
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showCreateEventDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Create Event'),
        content: Text('Event creation form would appear here'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Event created successfully'),
                  backgroundColor: AppTheme.accentLight,
                ),
              );
            },
            child: Text('Create'),
          ),
        ],
      ),
    );
  }

  void _rsvpToEvent(String eventId) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ RSVP confirmed! +5 VP earned'),
        backgroundColor: AppTheme.accentLight,
      ),
    );
  }
}
