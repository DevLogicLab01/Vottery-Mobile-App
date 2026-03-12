import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../services/enhanced_ai_orchestrator_service.dart';

class IncidentResponseWidget extends StatelessWidget {
  final List<FailoverEvent> failoverHistory;
  final VoidCallback onRefresh;

  const IncidentResponseWidget({
    super.key,
    required this.failoverHistory,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Incident Response & History',
                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: onRefresh,
                tooltip: 'Refresh History',
              ),
            ],
          ),
          SizedBox(height: 2.h),
          _buildIncidentStats(),
          SizedBox(height: 2.h),
          _buildFailoverTimeline(),
        ],
      ),
    );
  }

  Widget _buildIncidentStats() {
    final totalIncidents = failoverHistory.length;
    final failoverSuccesses = failoverHistory
        .where((e) => e.eventType == 'failover_success')
        .length;
    final failoverFailures = failoverHistory
        .where((e) => e.eventType == 'failover_failed')
        .length;
    final manualFailovers = failoverHistory
        .where((e) => e.eventType == 'manual_failover')
        .length;

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            label: 'Total Incidents',
            value: '$totalIncidents',
            color: Colors.blue,
            icon: Icons.warning,
          ),
        ),
        SizedBox(width: 2.w),
        Expanded(
          child: _buildStatCard(
            label: 'Successful',
            value: '$failoverSuccesses',
            color: Colors.green,
            icon: Icons.check_circle,
          ),
        ),
        SizedBox(width: 2.w),
        Expanded(
          child: _buildStatCard(
            label: 'Failed',
            value: '$failoverFailures',
            color: Colors.red,
            icon: Icons.error,
          ),
        ),
        SizedBox(width: 2.w),
        Expanded(
          child: _buildStatCard(
            label: 'Manual',
            value: '$manualFailovers',
            color: Colors.orange,
            icon: Icons.touch_app,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String label,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: EdgeInsets.all(2.w),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(77)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20.sp),
          SizedBox(height: 0.5.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 9.sp, color: Colors.grey.shade700),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFailoverTimeline() {
    if (failoverHistory.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(4.h),
          child: Column(
            children: [
              Icon(
                Icons.check_circle_outline,
                size: 48.sp,
                color: Colors.green,
              ),
              SizedBox(height: 2.h),
              Text(
                'No Failover Events',
                style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 1.h),
              Text(
                'All services are operating normally',
                style: TextStyle(fontSize: 12.sp, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Failover Events',
          style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
        ),
        SizedBox(height: 1.h),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: failoverHistory.length > 10 ? 10 : failoverHistory.length,
          separatorBuilder: (context, index) => SizedBox(height: 1.h),
          itemBuilder: (context, index) {
            final event = failoverHistory[index];
            return _buildFailoverEventCard(event);
          },
        ),
      ],
    );
  }

  Widget _buildFailoverEventCard(FailoverEvent event) {
    final eventColor = _getEventColor(event.eventType);
    final eventIcon = _getEventIcon(event.eventType);

    return Container(
      padding: EdgeInsets.all(2.w),
      decoration: BoxDecoration(
        color: eventColor.withAlpha(13),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: eventColor.withAlpha(51)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(1.w),
            decoration: BoxDecoration(
              color: eventColor,
              shape: BoxShape.circle,
            ),
            child: Icon(eventIcon, color: Colors.white, size: 16.sp),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      event.provider.toUpperCase(),
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      _formatTimestamp(event.timestamp),
                      style: TextStyle(fontSize: 10.sp, color: Colors.grey),
                    ),
                  ],
                ),
                SizedBox(height: 0.5.h),
                Text(
                  _formatEventType(event.eventType),
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: eventColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 0.5.h),
                Text(
                  event.error,
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: Colors.grey.shade700,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (event.retryCount > 0)
                  Padding(
                    padding: EdgeInsets.only(top: 0.5.h),
                    child: Text(
                      'Retry Count: ${event.retryCount}',
                      style: TextStyle(
                        fontSize: 9.sp,
                        color: Colors.grey,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getEventColor(String eventType) {
    switch (eventType) {
      case 'failover_success':
        return Colors.green;
      case 'failover_failed':
        return Colors.red;
      case 'manual_failover':
        return Colors.orange;
      case 'timeout':
        return Colors.amber;
      case 'error':
        return Colors.red.shade300;
      default:
        return Colors.blue;
    }
  }

  IconData _getEventIcon(String eventType) {
    switch (eventType) {
      case 'failover_success':
        return Icons.check_circle;
      case 'failover_failed':
        return Icons.error;
      case 'manual_failover':
        return Icons.touch_app;
      case 'timeout':
        return Icons.timer_off;
      case 'error':
        return Icons.warning;
      default:
        return Icons.info;
    }
  }

  String _formatEventType(String eventType) {
    return eventType
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  String _formatTimestamp(DateTime timestamp) {
    final diff = DateTime.now().difference(timestamp);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
