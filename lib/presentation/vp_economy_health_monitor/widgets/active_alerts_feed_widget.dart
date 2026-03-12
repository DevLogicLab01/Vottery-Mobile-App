import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

class ActiveAlertsFeedWidget extends StatelessWidget {
  final List<Map<String, dynamic>> alerts;
  final VoidCallback? onRefresh;

  const ActiveAlertsFeedWidget({
    super.key,
    required this.alerts,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final displayAlerts = alerts.isEmpty ? _mockAlerts() : alerts;

    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.notifications_active_rounded,
                color: Color(0xFFFF6B6B),
                size: 20,
              ),
              SizedBox(width: 2.w),
              Text(
                'Active Alerts Feed',
                style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1A1A2E),
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.refresh_rounded, size: 18),
                onPressed: onRefresh,
                color: Colors.grey[500],
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          SizedBox(height: 1.5.h),
          ...displayAlerts.map((alert) => _buildAlertCard(alert)),
          if (displayAlerts.isEmpty)
            Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 3.h),
                child: Column(
                  children: [
                    const Icon(
                      Icons.check_circle_rounded,
                      color: Color(0xFF4CAF50),
                      size: 36,
                    ),
                    SizedBox(height: 1.h),
                    Text(
                      'No active alerts',
                      style: GoogleFonts.inter(
                        fontSize: 12.sp,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAlertCard(Map<String, dynamic> alert) {
    final severity = alert['alert_severity']?.toString() ?? 'medium';
    final metricName = alert['metric_name']?.toString() ?? 'Unknown Metric';
    final currentValue =
        (alert['current_value'] as num?)?.toStringAsFixed(2) ?? '0';
    final thresholdValue =
        (alert['threshold_value'] as num?)?.toStringAsFixed(2) ?? '0';
    final deviation =
        (alert['deviation_percentage'] as num?)?.toStringAsFixed(1) ?? '0';
    final timestamp =
        alert['timestamp']?.toString() ?? DateTime.now().toIso8601String();

    final severityColor = severity == 'critical'
        ? const Color(0xFFFF6B6B)
        : severity == 'high'
        ? const Color(0xFFFF8C42)
        : const Color(0xFFFFB347);

    return Container(
      margin: EdgeInsets.only(bottom: 1.5.h),
      padding: EdgeInsets.all(2.5.w),
      decoration: BoxDecoration(
        color: severityColor.withAlpha(13),
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: severityColor.withAlpha(64)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 1.5.w,
                  vertical: 0.3.h,
                ),
                decoration: BoxDecoration(
                  color: severityColor,
                  borderRadius: BorderRadius.circular(4.0),
                ),
                child: Text(
                  severity.toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 8.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: Text(
                  metricName.replaceAll('_', ' ').toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1A1A2E),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                _formatTime(timestamp),
                style: GoogleFonts.inter(
                  fontSize: 9.sp,
                  color: Colors.grey[400],
                ),
              ),
            ],
          ),
          SizedBox(height: 0.8.h),
          Row(
            children: [
              _buildValueChip('Current', currentValue, severityColor),
              SizedBox(width: 2.w),
              _buildValueChip('Threshold', thresholdValue, Colors.grey),
              SizedBox(width: 2.w),
              _buildValueChip('Deviation', '$deviation%', severityColor),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildValueChip(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 8.sp, color: Colors.grey[500]),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 10.sp,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  String _formatTime(String iso) {
    try {
      final dt = DateTime.parse(iso);
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      return '${diff.inDays}d ago';
    } catch (_) {
      return 'Just now';
    }
  }

  List<Map<String, dynamic>> _mockAlerts() {
    return [
      {
        'alert_severity': 'high',
        'metric_name': 'inflation_rate',
        'current_value': 18.5,
        'threshold_value': 15.0,
        'deviation_percentage': 23.3,
        'timestamp': DateTime.now()
            .subtract(const Duration(minutes: 12))
            .toIso8601String(),
      },
      {
        'alert_severity': 'medium',
        'metric_name': 'earning_spending_ratio',
        'current_value': 1.42,
        'threshold_value': 1.2,
        'deviation_percentage': 18.3,
        'timestamp': DateTime.now()
            .subtract(const Duration(hours: 2))
            .toIso8601String(),
      },
    ];
  }
}
