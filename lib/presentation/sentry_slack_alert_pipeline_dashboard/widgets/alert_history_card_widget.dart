import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

class AlertHistoryCardWidget extends StatelessWidget {
  final List<Map<String, dynamic>> alertHistory;
  final VoidCallback onRefresh;

  const AlertHistoryCardWidget({
    super.key,
    required this.alertHistory,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Alert History',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 13.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
            TextButton.icon(
              onPressed: onRefresh,
              icon: const Icon(
                Icons.refresh,
                size: 14,
                color: Color(0xFF6366F1),
              ),
              label: Text(
                'Refresh',
                style: GoogleFonts.inter(
                  color: const Color(0xFF6366F1),
                  fontSize: 10.sp,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 1.h),
        _buildDeliveryAnalytics(),
        SizedBox(height: 2.h),
        if (alertHistory.isEmpty)
          _buildEmptyState()
        else
          ...alertHistory.map((alert) => _buildAlertCard(alert)),
      ],
    );
  }

  Widget _buildDeliveryAnalytics() {
    final delivered = alertHistory
        .where((a) => a['delivery_status'] == 'delivered')
        .length;
    final failed = alertHistory
        .where((a) => a['delivery_status'] == 'failed')
        .length;
    final total = alertHistory.length;
    final rate = total > 0 ? (delivered / total * 100) : 100.0;

    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1117),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildAnalyticTile('Total Sent', '$total', Colors.blue),
          ),
          Expanded(
            child: _buildAnalyticTile('Delivered', '$delivered', Colors.green),
          ),
          Expanded(child: _buildAnalyticTile('Failed', '$failed', Colors.red)),
          Expanded(
            child: _buildAnalyticTile(
              'Success Rate',
              '${rate.toStringAsFixed(1)}%',
              Colors.purple,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticTile(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.inter(
            color: color,
            fontSize: 16.sp,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.inter(color: Colors.white54, fontSize: 9.sp),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1117),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Center(
        child: Column(
          children: [
            const Icon(
              Icons.notifications_none,
              color: Colors.white38,
              size: 40,
            ),
            SizedBox(height: 1.h),
            Text(
              'No alert history found',
              style: GoogleFonts.inter(color: Colors.white54, fontSize: 11.sp),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertCard(Map<String, dynamic> alert) {
    final severity = alert['severity'] as String? ?? 'medium';
    final deliveryStatus = alert['delivery_status'] as String? ?? 'delivered';
    final messageType = alert['message_type'] as String? ?? 'alert';
    final sentAt = alert['sent_at'] as String? ?? '';
    final affectedUsers = (alert['affected_users'] as num?)?.toInt() ?? 0;
    final errorSummary = alert['error_summary'] as String? ?? 'Unknown error';
    final channel = alert['channel'] as String? ?? '#vottery-errors';

    final severityColor = severity == 'critical'
        ? Colors.red
        : severity == 'high'
        ? Colors.orange
        : severity == 'medium'
        ? Colors.yellow
        : Colors.blue;

    final deliveryColor = deliveryStatus == 'delivered'
        ? Colors.green
        : Colors.red;

    DateTime? parsedTime;
    try {
      parsedTime = DateTime.parse(sentAt);
    } catch (_) {}

    return Container(
      margin: EdgeInsets.only(bottom: 1.h),
      padding: EdgeInsets.all(2.5.w),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1117),
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(color: Colors.white12),
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
                  color: severityColor.withAlpha(30),
                  borderRadius: BorderRadius.circular(4.0),
                ),
                child: Text(
                  severity.toUpperCase(),
                  style: GoogleFonts.inter(
                    color: severityColor,
                    fontSize: 8.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              SizedBox(width: 2.w),
              Text(
                messageType.replaceAll('_', ' ').toUpperCase(),
                style: GoogleFonts.inter(
                  color: Colors.white70,
                  fontSize: 9.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 1.5.w,
                  vertical: 0.3.h,
                ),
                decoration: BoxDecoration(
                  color: deliveryColor.withAlpha(30),
                  borderRadius: BorderRadius.circular(4.0),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      deliveryStatus == 'delivered'
                          ? Icons.check_circle
                          : Icons.error,
                      color: deliveryColor,
                      size: 10,
                    ),
                    SizedBox(width: 1.w),
                    Text(
                      deliveryStatus.toUpperCase(),
                      style: GoogleFonts.inter(
                        color: deliveryColor,
                        fontSize: 8.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 0.8.h),
          Text(
            errorSummary,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 10.sp,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 0.5.h),
          Row(
            children: [
              Icon(Icons.tag, color: Colors.white38, size: 12),
              SizedBox(width: 1.w),
              Text(
                channel,
                style: GoogleFonts.inter(
                  color: const Color(0xFF6366F1),
                  fontSize: 9.sp,
                ),
              ),
              SizedBox(width: 3.w),
              Icon(Icons.people_outline, color: Colors.white38, size: 12),
              SizedBox(width: 1.w),
              Text(
                '$affectedUsers users affected',
                style: GoogleFonts.inter(color: Colors.white38, fontSize: 9.sp),
              ),
              const Spacer(),
              Text(
                parsedTime != null ? _formatTime(parsedTime) : 'Unknown time',
                style: GoogleFonts.inter(color: Colors.white38, fontSize: 9.sp),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
