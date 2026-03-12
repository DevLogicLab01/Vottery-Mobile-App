import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../../theme/app_theme.dart';

class RegressionAlertsWidget extends StatelessWidget {
  final List<Map<String, dynamic>> regressionAlerts;
  final VoidCallback onRefresh;

  const RegressionAlertsWidget({
    super.key,
    required this.regressionAlerts,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.all(4.w),
      children: [
        Text(
          'Regression Detection Alerts',
          style: GoogleFonts.inter(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 2.h),
        if (regressionAlerts.isEmpty)
          _buildNoRegressionsCard()
        else
          ...regressionAlerts.map((alert) => _buildRegressionCard(alert)),
      ],
    );
  }

  Widget _buildNoRegressionsCard() {
    return Container(
      padding: EdgeInsets.all(6.w),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        children: [
          Icon(Icons.check_circle, color: Colors.green, size: 15.w),
          SizedBox(height: 2.h),
          Text(
            'No Regressions Detected',
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            'All performance metrics are within acceptable thresholds',
            style: GoogleFonts.inter(
              fontSize: 11.sp,
              color: AppTheme.textSecondaryLight,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRegressionCard(Map<String, dynamic> alert) {
    final type = alert['type'] ?? 'unknown';
    final metric = alert['metric'] ?? 'Unknown Metric';
    final currentValue = alert['current_value'] ?? 0.0;
    final baselineValue = alert['baseline_value'] ?? 0.0;
    final degradation = alert['degradation_percentage'] ?? 0.0;
    final severity = alert['severity'] ?? 'medium';

    Color severityColor;
    switch (severity) {
      case 'critical':
        severityColor = Colors.red;
        break;
      case 'high':
        severityColor = Colors.orange;
        break;
      default:
        severityColor = Colors.yellow.shade700;
    }

    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: severityColor, width: 2.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning, color: severityColor, size: 6.w),
              SizedBox(width: 2.w),
              Expanded(
                child: Text(
                  metric,
                  style: GoogleFonts.inter(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                decoration: BoxDecoration(
                  color: severityColor.withAlpha(26),
                  borderRadius: BorderRadius.circular(4.0),
                ),
                child: Text(
                  severity.toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.bold,
                    color: severityColor,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Text(
            'Type: ${type.toUpperCase()}',
            style: GoogleFonts.inter(
              fontSize: 11.sp,
              color: AppTheme.textSecondaryLight,
            ),
          ),
          SizedBox(height: 1.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Baseline',
                    style: GoogleFonts.inter(
                      fontSize: 10.sp,
                      color: AppTheme.textSecondaryLight,
                    ),
                  ),
                  Text(
                    baselineValue.toStringAsFixed(1),
                    style: GoogleFonts.inter(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Icon(Icons.arrow_forward, color: Colors.grey, size: 5.w),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Current',
                    style: GoogleFonts.inter(
                      fontSize: 10.sp,
                      color: AppTheme.textSecondaryLight,
                    ),
                  ),
                  Text(
                    currentValue.toStringAsFixed(1),
                    style: GoogleFonts.inter(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: severityColor,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Degradation',
                    style: GoogleFonts.inter(
                      fontSize: 10.sp,
                      color: AppTheme.textSecondaryLight,
                    ),
                  ),
                  Text(
                    '+${degradation.toStringAsFixed(1)}%',
                    style: GoogleFonts.inter(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: severityColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
