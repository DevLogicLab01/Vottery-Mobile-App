import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../services/realtime_dashboard_service.dart';
import '../../../theme/app_theme.dart';

class PresenceTrackingWidget extends StatefulWidget {
  final RealtimeDashboardService dashboardService;
  final String userId;
  final String username;

  const PresenceTrackingWidget({
    super.key,
    required this.dashboardService,
    required this.userId,
    required this.username,
  });

  @override
  State<PresenceTrackingWidget> createState() => _PresenceTrackingWidgetState();
}

class _PresenceTrackingWidgetState extends State<PresenceTrackingWidget> {
  DashboardType? _selectedDashboard;

  Future<void> _joinPresence(DashboardType type) async {
    try {
      await widget.dashboardService.joinPresence(
        type,
        widget.userId,
        widget.username,
      );
      setState(() => _selectedDashboard = type);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error joining presence: $e')));
      }
    }
  }

  Future<void> _leavePresence() async {
    if (_selectedDashboard != null) {
      try {
        await widget.dashboardService.leavePresence(_selectedDashboard!);
        setState(() => _selectedDashboard = null);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error leaving presence: $e')));
        }
      }
    }
  }

  @override
  void dispose() {
    _leavePresence();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.people, color: AppTheme.primaryLight),
                SizedBox(width: 2.w),
                Text(
                  'Presence Tracking',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            SizedBox(height: 2.h),
            if (_selectedDashboard == null) ...[
              Text(
                'Join a dashboard to see active viewers',
                style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
              ),
              SizedBox(height: 1.h),
              Wrap(
                spacing: 2.w,
                runSpacing: 1.h,
                children: DashboardType.values.map((type) {
                  return ElevatedButton(
                    onPressed: () => _joinPresence(type),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor.withAlpha(26),
                      foregroundColor: AppTheme.primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    child: Text(
                      type.name[0].toUpperCase() + type.name.substring(1),
                      style: TextStyle(fontSize: 12.sp),
                    ),
                  );
                }).toList(),
              ),
            ] else ...[
              Container(
                padding: EdgeInsets.all(2.w),
                decoration: BoxDecoration(
                  color: Colors.green.withAlpha(26),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Viewing: ${_selectedDashboard!.name[0].toUpperCase()}${_selectedDashboard!.name.substring(1)}',
                          style: TextStyle(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        TextButton(
                          onPressed: _leavePresence,
                          child: Text(
                            'Leave',
                            style: TextStyle(fontSize: 12.sp),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 1.h),
                    Row(
                      children: [
                        Icon(Icons.people, size: 16, color: Colors.grey[600]),
                        SizedBox(width: 1.w),
                        Text(
                          '${widget.dashboardService.getActiveViewers(_selectedDashboard!)} users viewing',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
