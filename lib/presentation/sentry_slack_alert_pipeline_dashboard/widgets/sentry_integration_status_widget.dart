import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

class SentryIntegrationStatusWidget extends StatelessWidget {
  final Map<String, dynamic> errorStats;
  final List<Map<String, dynamic>> recentAlerts;
  final int crashThreshold;
  final int aiFailureThreshold;
  final Function(int crash, int ai) onThresholdChanged;

  const SentryIntegrationStatusWidget({
    super.key,
    required this.errorStats,
    required this.recentAlerts,
    required this.crashThreshold,
    required this.aiFailureThreshold,
    required this.onThresholdChanged,
  });

  @override
  Widget build(BuildContext context) {
    final totalIncidents =
        (errorStats['total_incidents'] as num?)?.toInt() ?? 0;
    final criticalCount = (errorStats['critical_count'] as num?)?.toInt() ?? 0;
    final openCount = (errorStats['open_count'] as num?)?.toInt() ?? 0;
    final errorRate = (errorStats['error_rate'] as num?)?.toDouble() ?? 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildConnectionHealthCard(
          totalIncidents,
          criticalCount,
          openCount,
          errorRate,
        ),
        SizedBox(height: 2.h),
        _buildErrorMetricsGrid(),
        SizedBox(height: 2.h),
        _buildThresholdConfig(context),
        SizedBox(height: 2.h),
        _buildRecentErrorStream(),
      ],
    );
  }

  Widget _buildConnectionHealthCard(
    int total,
    int critical,
    int open,
    double rate,
  ) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1117),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: const Color(0xFF6366F1).withAlpha(60)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(1.5.w),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withAlpha(30),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: const Icon(
                  Icons.bug_report,
                  color: Color(0xFF6366F1),
                  size: 20,
                ),
              ),
              SizedBox(width: 2.w),
              Text(
                'Sentry Integration Status',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                decoration: BoxDecoration(
                  color: Colors.green.withAlpha(30),
                  borderRadius: BorderRadius.circular(20.0),
                  border: Border.all(color: Colors.green.withAlpha(80)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.green,
                      ),
                    ),
                    SizedBox(width: 1.w),
                    Text(
                      'CONNECTED',
                      style: GoogleFonts.inter(
                        color: Colors.green,
                        fontSize: 9.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              Expanded(
                child: _buildMetricTile('Total (24h)', '$total', Colors.blue),
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: _buildMetricTile('Critical', '$critical', Colors.red),
              ),
              SizedBox(width: 2.w),
              Expanded(child: _buildMetricTile('Open', '$open', Colors.orange)),
              SizedBox(width: 2.w),
              Expanded(
                child: _buildMetricTile(
                  'Rate/hr',
                  rate.toStringAsFixed(1),
                  Colors.purple,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile(String label, String value, Color color) {
    return Container(
      padding: EdgeInsets.all(2.w),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Column(
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
      ),
    );
  }

  Widget _buildErrorMetricsGrid() {
    final metrics = [
      {
        'label': 'App Crashes',
        'value': '${(errorStats['critical_count'] as num?)?.toInt() ?? 0}',
        'threshold': '$crashThreshold/hr',
        'color': Colors.red,
        'icon': Icons.error_outline,
      },
      {
        'label': 'AI Failures',
        'value': '${(errorStats['high_count'] as num?)?.toInt() ?? 0}',
        'threshold': '$aiFailureThreshold/hr',
        'color': Colors.orange,
        'icon': Icons.psychology_outlined,
      },
      {
        'label': 'Resolved',
        'value': '${(errorStats['resolved_count'] as num?)?.toInt() ?? 0}',
        'threshold': 'Auto-close',
        'color': Colors.green,
        'icon': Icons.check_circle_outline,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Error Tracking Metrics',
          style: GoogleFonts.inter(
            color: Colors.white70,
            fontSize: 11.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 1.h),
        Row(
          children: metrics
              .map(
                (m) => Expanded(
                  child: Container(
                    margin: EdgeInsets.only(right: 2.w),
                    padding: EdgeInsets.all(2.5.w),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D1117),
                      borderRadius: BorderRadius.circular(10.0),
                      border: Border.all(
                        color: (m['color'] as Color).withAlpha(60),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          m['icon'] as IconData,
                          color: m['color'] as Color,
                          size: 18,
                        ),
                        SizedBox(height: 0.5.h),
                        Text(
                          m['value'] as String,
                          style: GoogleFonts.inter(
                            color: m['color'] as Color,
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          m['label'] as String,
                          style: GoogleFonts.inter(
                            color: Colors.white70,
                            fontSize: 9.sp,
                          ),
                        ),
                        Text(
                          'Threshold: ${m['threshold']}',
                          style: GoogleFonts.inter(
                            color: Colors.white38,
                            fontSize: 8.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  Widget _buildThresholdConfig(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1117),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Alert Threshold Configuration',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 12.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 1.5.h),
          _buildThresholdRow(
            'Crash Rate Threshold',
            '$crashThreshold crashes/hour',
            Colors.red,
            Icons.error_outline,
          ),
          SizedBox(height: 1.h),
          _buildThresholdRow(
            'AI Failure Threshold',
            '$aiFailureThreshold failures/hour',
            Colors.orange,
            Icons.psychology_outlined,
          ),
          SizedBox(height: 1.5.h),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showThresholdDialog(context),
              icon: const Icon(Icons.tune, size: 16),
              label: Text(
                'Configure Thresholds',
                style: GoogleFonts.inter(fontSize: 10.sp),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 1.2.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThresholdRow(
    String label,
    String value,
    Color color,
    IconData icon,
  ) {
    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        SizedBox(width: 2.w),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.inter(color: Colors.white70, fontSize: 10.sp),
          ),
        ),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.4.h),
          decoration: BoxDecoration(
            color: color.withAlpha(30),
            borderRadius: BorderRadius.circular(6.0),
          ),
          child: Text(
            value,
            style: GoogleFonts.inter(
              color: color,
              fontSize: 10.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  void _showThresholdDialog(BuildContext context) {
    int tempCrash = crashThreshold;
    int tempAi = aiFailureThreshold;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF0D1117),
          title: Text(
            'Configure Alert Thresholds',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Crash Rate Threshold: $tempCrash/hour',
                style: GoogleFonts.inter(color: Colors.white70),
              ),
              Slider(
                value: tempCrash.toDouble(),
                min: 1,
                max: 50,
                divisions: 49,
                activeColor: Colors.red,
                onChanged: (v) => setDialogState(() => tempCrash = v.toInt()),
              ),
              Text(
                'AI Failure Threshold: $tempAi/hour',
                style: GoogleFonts.inter(color: Colors.white70),
              ),
              Slider(
                value: tempAi.toDouble(),
                min: 1,
                max: 30,
                divisions: 29,
                activeColor: Colors.orange,
                onChanged: (v) => setDialogState(() => tempAi = v.toInt()),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Cancel',
                style: GoogleFonts.inter(color: Colors.white54),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                onThresholdChanged(tempCrash, tempAi);
                Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
              ),
              child: Text(
                'Save',
                style: GoogleFonts.inter(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentErrorStream() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Real-Time Error Stream',
          style: GoogleFonts.inter(
            color: Colors.white70,
            fontSize: 11.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 1.h),
        if (recentAlerts.isEmpty)
          Container(
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: const Color(0xFF0D1117),
              borderRadius: BorderRadius.circular(10.0),
            ),
            child: Center(
              child: Text(
                'No critical errors in the last 24 hours',
                style: GoogleFonts.inter(color: Colors.green, fontSize: 10.sp),
              ),
            ),
          )
        else
          ...recentAlerts.take(5).map((alert) => _buildErrorStreamCard(alert)),
      ],
    );
  }

  Widget _buildErrorStreamCard(Map<String, dynamic> alert) {
    final severity = alert['severity'] as String? ?? 'medium';
    final color = severity == 'critical'
        ? Colors.red
        : severity == 'high'
        ? Colors.orange
        : Colors.yellow;

    return Container(
      margin: EdgeInsets.only(bottom: 1.h),
      padding: EdgeInsets.all(2.5.w),
      decoration: BoxDecoration(
        color: color.withAlpha(15),
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
          SizedBox(width: 2.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alert['error_message'] as String? ?? 'Unknown error',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  alert['affected_feature'] as String? ?? 'Unknown feature',
                  style: GoogleFonts.inter(
                    color: Colors.white54,
                    fontSize: 9.sp,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 1.5.w, vertical: 0.3.h),
            decoration: BoxDecoration(
              color: color.withAlpha(30),
              borderRadius: BorderRadius.circular(4.0),
            ),
            child: Text(
              severity.toUpperCase(),
              style: GoogleFonts.inter(
                color: color,
                fontSize: 8.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
