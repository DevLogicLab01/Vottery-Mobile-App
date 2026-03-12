import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class AlertFeedWidget extends StatefulWidget {
  final List<Map<String, dynamic>> alerts;
  final VoidCallback onRefresh;
  const AlertFeedWidget({
    super.key,
    required this.alerts,
    required this.onRefresh,
  });
  @override
  State<AlertFeedWidget> createState() => _AlertFeedWidgetState();
}

class _AlertFeedWidgetState extends State<AlertFeedWidget> {
  bool _churnAlertsEnabled = true;
  bool _growthAlertsEnabled = true;
  bool _performanceAlertsEnabled = true;
  double _churnThreshold = 0.7;
  double _engagementDeclineThreshold = 15.0;

  Color _priorityColor(String p) {
    switch (p) {
      case 'critical':
        return const Color(0xFFEF4444);
      case 'high':
        return const Color(0xFFF97316);
      case 'medium':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF3B82F6);
    }
  }

  IconData _alertIcon(String type) {
    switch (type) {
      case 'churn_risk':
        return Icons.warning_amber;
      case 'growth_milestone':
        return Icons.celebration;
      case 'performance_decline':
        return Icons.trending_down;
      default:
        return Icons.notifications;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Live Alert Feed',
          style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w700),
        ),
        SizedBox(height: 1.h),
        ...widget.alerts.map((alert) {
          final priority = alert['severity'] as String? ?? 'medium';
          final type = alert['alert_type'] as String? ?? 'churn_risk';
          final color = _priorityColor(priority);
          return Container(
            margin: EdgeInsets.only(bottom: 1.h),
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: color.withAlpha(13),
              borderRadius: BorderRadius.circular(10.0),
              border: Border.all(color: color.withAlpha(77)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withAlpha(26),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(_alertIcon(type), color: color, size: 18),
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        alert['message'] as String? ?? 'Alert',
                        style: TextStyle(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 0.3.h),
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 1.5.w,
                              vertical: 0.2.h,
                            ),
                            decoration: BoxDecoration(
                              color: color.withAlpha(26),
                              borderRadius: BorderRadius.circular(4.0),
                            ),
                            child: Text(
                              priority.toUpperCase(),
                              style: TextStyle(
                                fontSize: 8.sp,
                                color: color,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          SizedBox(width: 2.w),
                          Text(
                            alert['time'] as String? ?? 'Just now',
                            style: TextStyle(
                              fontSize: 9.sp,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (type == 'performance_decline')
                  TextButton(
                    onPressed: () {},
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 2.w),
                    ),
                    child: Text(
                      'Investigate',
                      style: TextStyle(fontSize: 9.sp),
                    ),
                  ),
              ],
            ),
          );
        }),
        SizedBox(height: 2.h),
        Container(
          padding: EdgeInsets.all(3.w),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(10.0),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Alert Settings',
                style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w700),
              ),
              SizedBox(height: 1.h),
              SwitchListTile(
                title: Text('Churn Alerts', style: TextStyle(fontSize: 11.sp)),
                value: _churnAlertsEnabled,
                onChanged: (v) => setState(() => _churnAlertsEnabled = v),
                dense: true,
                contentPadding: EdgeInsets.zero,
              ),
              SwitchListTile(
                title: Text('Growth Alerts', style: TextStyle(fontSize: 11.sp)),
                value: _growthAlertsEnabled,
                onChanged: (v) => setState(() => _growthAlertsEnabled = v),
                dense: true,
                contentPadding: EdgeInsets.zero,
              ),
              SwitchListTile(
                title: Text(
                  'Performance Alerts',
                  style: TextStyle(fontSize: 11.sp),
                ),
                value: _performanceAlertsEnabled,
                onChanged: (v) => setState(() => _performanceAlertsEnabled = v),
                dense: true,
                contentPadding: EdgeInsets.zero,
              ),
              SizedBox(height: 1.h),
              Text(
                'Churn Threshold: ${(_churnThreshold * 100).round()}%',
                style: TextStyle(fontSize: 11.sp),
              ),
              Slider(
                value: _churnThreshold,
                min: 0.3,
                max: 0.9,
                divisions: 6,
                onChanged: (v) => setState(() => _churnThreshold = v),
                activeColor: const Color(0xFFEF4444),
              ),
              Text(
                'Engagement Decline: ${_engagementDeclineThreshold.round()}%',
                style: TextStyle(fontSize: 11.sp),
              ),
              Slider(
                value: _engagementDeclineThreshold,
                min: 5,
                max: 50,
                divisions: 9,
                onChanged: (v) =>
                    setState(() => _engagementDeclineThreshold = v),
                activeColor: const Color(0xFFF59E0B),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
