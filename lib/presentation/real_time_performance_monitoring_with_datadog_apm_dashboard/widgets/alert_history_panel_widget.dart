import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

class AlertHistoryPanelWidget extends StatefulWidget {
  const AlertHistoryPanelWidget({super.key});

  @override
  State<AlertHistoryPanelWidget> createState() =>
      _AlertHistoryPanelWidgetState();
}

class _AlertHistoryPanelWidgetState extends State<AlertHistoryPanelWidget> {
  bool _slackEnabled = true;
  bool _emailEnabled = true;
  bool _smsEnabled = false;

  final List<Map<String, dynamic>> _alerts = [
    {
      'time': '14:32',
      'type': 'Query Latency',
      'severity': 'warning',
      'msg': 'P95 exceeded 100ms for 5min',
      'ack': 'DevOps Team',
    },
    {
      'time': '11:15',
      'type': 'Cache Hit Rate',
      'severity': 'warning',
      'msg': 'Hit rate dropped to 82% for 10min',
      'ack': 'Backend Team',
    },
    {
      'time': '09:44',
      'type': 'Error Rate',
      'severity': 'critical',
      'msg': 'Error rate exceeded 1% for 3min',
      'ack': 'On-Call Engineer',
    },
    {
      'time': 'Yesterday',
      'type': 'Connection Pool',
      'severity': 'info',
      'msg': 'Pool utilization at 85%',
      'ack': 'Auto-resolved',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      padding: EdgeInsets.all(3.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.notifications_active,
                color: Color(0xFFF59E0B),
                size: 20,
              ),
              SizedBox(width: 2.w),
              Text(
                'Alert History & Configuration',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Text(
            'Recent Alerts',
            style: GoogleFonts.inter(
              color: const Color(0xFF94A3B8),
              fontSize: 11.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 1.h),
          ..._alerts.map((a) => _alertCard(a)),
          SizedBox(height: 2.h),
          Text(
            'Alert Channels',
            style: GoogleFonts.inter(
              color: const Color(0xFF94A3B8),
              fontSize: 11.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 1.h),
          _channelToggle(
            'Slack #performance-alerts',
            Icons.chat_bubble_outline,
            _slackEnabled,
            (v) => setState(() => _slackEnabled = v),
          ),
          _channelToggle(
            'Email to DevOps Team',
            Icons.email_outlined,
            _emailEnabled,
            (v) => setState(() => _emailEnabled = v),
          ),
          _channelToggle(
            'SMS to On-Call Engineer',
            Icons.sms_outlined,
            _smsEnabled,
            (v) => setState(() => _smsEnabled = v),
          ),
          SizedBox(height: 2.h),
          Text(
            'Alert Thresholds',
            style: GoogleFonts.inter(
              color: const Color(0xFF94A3B8),
              fontSize: 11.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 1.h),
          _thresholdRow('Query Latency P95', '> 100ms', '5 min'),
          _thresholdRow('Cache Hit Rate', '< 85%', '10 min'),
          _thresholdRow('Connection Pool', '> 90%', 'Immediate'),
          _thresholdRow('Error Rate', '> 1%', '3 min'),
        ],
      ),
    );
  }

  Widget _alertCard(Map<String, dynamic> a) {
    final severity = a['severity'] as String;
    final color = severity == 'critical'
        ? const Color(0xFFEF4444)
        : severity == 'warning'
        ? const Color(0xFFF59E0B)
        : const Color(0xFF3B82F6);
    return Container(
      margin: EdgeInsets.only(bottom: 1.h),
      padding: EdgeInsets.all(2.w),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: color.withAlpha(64)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            severity == 'critical'
                ? Icons.error
                : severity == 'warning'
                ? Icons.warning_amber
                : Icons.info_outline,
            color: color,
            size: 16,
          ),
          SizedBox(width: 2.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      a['type'] as String,
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      a['time'] as String,
                      style: GoogleFonts.inter(
                        color: const Color(0xFF94A3B8),
                        fontSize: 9.sp,
                      ),
                    ),
                  ],
                ),
                Text(
                  a['msg'] as String,
                  style: GoogleFonts.inter(
                    color: const Color(0xFF94A3B8),
                    fontSize: 9.sp,
                  ),
                ),
                Text(
                  'Ack: ${a['ack']}',
                  style: GoogleFonts.inter(color: color, fontSize: 9.sp),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _channelToggle(
    String label,
    IconData icon,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 0.5.h),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF94A3B8), size: 16),
          SizedBox(width: 2.w),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.inter(color: Colors.white, fontSize: 10.sp),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: const Color(0xFF6366F1),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],
      ),
    );
  }

  Widget _thresholdRow(String metric, String condition, String duration) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 0.4.h),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              metric,
              style: GoogleFonts.inter(color: Colors.white, fontSize: 10.sp),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 1.5.w, vertical: 0.3.h),
            decoration: BoxDecoration(
              color: const Color(0xFFEF4444).withAlpha(26),
              borderRadius: BorderRadius.circular(4.0),
            ),
            child: Text(
              condition,
              style: GoogleFonts.inter(
                color: const Color(0xFFEF4444),
                fontSize: 9.sp,
              ),
            ),
          ),
          SizedBox(width: 2.w),
          Text(
            duration,
            style: GoogleFonts.inter(
              color: const Color(0xFF94A3B8),
              fontSize: 9.sp,
            ),
          ),
        ],
      ),
    );
  }
}
