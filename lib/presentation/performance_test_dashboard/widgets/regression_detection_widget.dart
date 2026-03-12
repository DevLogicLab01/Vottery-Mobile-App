import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../theme/app_theme.dart';

class RegressionDetectionWidget extends StatelessWidget {
  final List<Map<String, dynamic>> regressions;
  final VoidCallback onRefresh;

  const RegressionDetectionWidget({
    super.key,
    required this.regressions,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (regressions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 20.w, color: Colors.green),
            SizedBox(height: 2.h),
            Text(
              'No Performance Regressions',
              style: GoogleFonts.inter(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              'All metrics are within acceptable thresholds',
              style: GoogleFonts.inter(
                fontSize: 14.sp,
                color: AppTheme.textSecondaryLight,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(4.w),
      itemCount: regressions.length,
      itemBuilder: (context, index) {
        return _buildRegressionCard(regressions[index]);
      },
    );
  }

  Widget _buildRegressionCard(Map<String, dynamic> regression) {
    final type = regression['type'] ?? 'unknown';
    final metric = regression['metric'] ?? 'Unknown Metric';
    final currentValue = regression['current_value'] ?? 0.0;
    final baselineValue = regression['baseline_value'] ?? 0.0;
    final degradation = regression['degradation_percentage'] ?? 0.0;
    final severity = regression['severity'] ?? 'medium';

    final severityColor = _getSeverityColor(severity);
    final icon = _getTypeIcon(type);

    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: severityColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: severityColor, size: 6.w),
              SizedBox(width: 3.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      metric,
                      style: GoogleFonts.inter(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 0.5.h),
                    Text(
                      _getTypeLabel(type),
                      style: GoogleFonts.inter(
                        fontSize: 12.sp,
                        color: AppTheme.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.5.h),
                decoration: BoxDecoration(
                  color: severityColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12.0),
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
          SizedBox(height: 2.h),
          Row(
            children: [
              Expanded(
                child: _buildValueCard(
                  'Baseline',
                  baselineValue.toString(),
                  Colors.grey,
                ),
              ),
              SizedBox(width: 2.w),
              Icon(Icons.arrow_forward, color: AppTheme.textSecondaryLight),
              SizedBox(width: 2.w),
              Expanded(
                child: _buildValueCard(
                  'Current',
                  currentValue.toString(),
                  severityColor,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Container(
            padding: EdgeInsets.all(2.w),
            decoration: BoxDecoration(
              color: severityColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Row(
              children: [
                Icon(Icons.trending_down, color: severityColor, size: 5.w),
                SizedBox(width: 2.w),
                Text(
                  'Degradation: ${degradation.toStringAsFixed(1)}%',
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: severityColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildValueCard(String label, String value, Color color) {
    return Container(
      padding: EdgeInsets.all(2.w),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10.sp,
              color: AppTheme.textSecondaryLight,
            ),
          ),
          SizedBox(height: 0.5.h),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'critical':
        return Colors.red;
      case 'high':
        return Colors.orange;
      case 'medium':
        return Colors.yellow.shade700;
      case 'low':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'skeleton_loader':
        return Icons.hourglass_empty;
      case 'error_boundary':
        return Icons.healing;
      case 'sentry_delivery':
        return Icons.cloud_upload;
      default:
        return Icons.warning;
    }
  }

  String _getTypeLabel(String type) {
    switch (type) {
      case 'skeleton_loader':
        return 'Skeleton Loader Performance';
      case 'error_boundary':
        return 'Error Boundary Recovery';
      case 'sentry_delivery':
        return 'Sentry Event Delivery';
      default:
        return 'Unknown Type';
    }
  }
}
