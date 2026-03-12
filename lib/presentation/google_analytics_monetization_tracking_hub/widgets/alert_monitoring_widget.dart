import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class AlertMonitoringWidget extends StatefulWidget {
  const AlertMonitoringWidget({super.key});

  @override
  State<AlertMonitoringWidget> createState() => _AlertMonitoringWidgetState();
}

class _AlertMonitoringWidgetState extends State<AlertMonitoringWidget> {
  final List<Map<String, dynamic>> _activeAlerts = [
    {
      'type': 'Withdrawal Spike',
      'severity': 'high',
      'message': 'Withdrawal requests increased by 45% in last hour',
      'timestamp': '2 minutes ago',
    },
    {
      'type': 'KYC Rejection Increase',
      'severity': 'medium',
      'message': 'KYC rejection rate up 12% from baseline',
      'timestamp': '15 minutes ago',
    },
    {
      'type': 'Settlement Delay',
      'severity': 'low',
      'message': '3 settlements exceeding expected processing time',
      'timestamp': '1 hour ago',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.all(3.w),
      children: [
        _buildActiveAlerts(),
        SizedBox(height: 2.h),
        _buildAlertThresholds(),
        SizedBox(height: 2.h),
        _buildAlertHistory(),
      ],
    );
  }

  Widget _buildActiveAlerts() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Active Alerts',
                  style: GoogleFonts.inter(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 2.w,
                    vertical: 0.5.h,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red.withAlpha(51),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Text(
                    '${_activeAlerts.length}',
                    style: GoogleFonts.inter(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 2.h),
            ..._activeAlerts.map((alert) => _buildAlertCard(alert)),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertCard(Map<String, dynamic> alert) {
    Color severityColor;
    IconData severityIcon;

    switch (alert['severity']) {
      case 'high':
        severityColor = Colors.red;
        severityIcon = Icons.error;
        break;
      case 'medium':
        severityColor = Colors.orange;
        severityIcon = Icons.warning;
        break;
      case 'low':
        severityColor = Colors.blue;
        severityIcon = Icons.info;
        break;
      default:
        severityColor = Colors.grey;
        severityIcon = Icons.notifications;
    }

    return Container(
      margin: EdgeInsets.only(bottom: 1.5.h),
      padding: EdgeInsets.all(2.w),
      decoration: BoxDecoration(
        color: severityColor.withAlpha(26),
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: severityColor.withAlpha(77)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(severityIcon, color: severityColor, size: 20),
              SizedBox(width: 2.w),
              Expanded(
                child: Text(
                  alert['type'],
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                    color: severityColor,
                  ),
                ),
              ),
              Text(
                alert['timestamp'],
                style: GoogleFonts.inter(
                  fontSize: 10.sp,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          SizedBox(height: 0.5.h),
          Text(
            alert['message'],
            style: GoogleFonts.inter(fontSize: 11.sp, color: Colors.grey[800]),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertThresholds() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Alert Thresholds',
              style: GoogleFonts.inter(
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 2.h),
            _buildThresholdRow('Withdrawal Spike', '> 30% increase', true),
            _buildThresholdRow('KYC Rejection Rate', '> 15% baseline', true),
            _buildThresholdRow('Settlement Failures', '> 5 per hour', true),
            _buildThresholdRow(
              'Processing Delays',
              '> 2x expected time',
              false,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThresholdRow(String metric, String threshold, bool enabled) {
    return Padding(
      padding: EdgeInsets.only(bottom: 1.h),
      child: Row(
        children: [
          Switch(
            value: enabled,
            onChanged: (value) {
              setState(() {
                // Toggle threshold
              });
            },
            activeThumbColor: AppTheme.accentLight,
          ),
          SizedBox(width: 2.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  metric,
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  threshold,
                  style: GoogleFonts.inter(
                    fontSize: 10.sp,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertHistory() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Alert History (Last 24h)',
              style: GoogleFonts.inter(
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 2.h),
            _buildHistoryRow('Withdrawal Spike', 12, Colors.red),
            _buildHistoryRow('KYC Rejection Increase', 8, Colors.orange),
            _buildHistoryRow('Settlement Delay', 5, Colors.blue),
            _buildHistoryRow('Processing Anomaly', 3, Colors.purple),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryRow(String type, int count, Color color) {
    return Padding(
      padding: EdgeInsets.only(bottom: 1.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(type, style: GoogleFonts.inter(fontSize: 12.sp)),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
            decoration: BoxDecoration(
              color: color.withAlpha(51),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Text(
              '$count alerts',
              style: GoogleFonts.inter(
                fontSize: 11.sp,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
