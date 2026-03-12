import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../../theme/app_theme.dart';

class FraudAlertCardWidget extends StatelessWidget {
  final Map<String, dynamic> event;
  final VoidCallback onInvestigate;
  final VoidCallback onDismiss;

  const FraudAlertCardWidget({
    required this.event,
    required this.onInvestigate,
    required this.onDismiss,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final riskLevel = event['risk_level'] as String? ?? 'low';
    final fraudScore = (event['fraud_score'] as num?)?.toDouble() ?? 0.0;
    final confidence = (event['confidence'] as num?)?.toDouble() ?? 0.0;
    final eventType = event['event_type'] as String? ?? 'behavioral_anomaly';
    final userEmail = event['user_profiles']?['email'] ?? 'Unknown';

    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: _getRiskColor(riskLevel), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                decoration: BoxDecoration(
                  color: _getRiskColor(riskLevel),
                  borderRadius: BorderRadius.circular(20.0),
                ),
                child: Text(
                  riskLevel.toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: Text(
                  _formatEventType(eventType),
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimaryLight,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Text(
            'User: $userEmail',
            style: GoogleFonts.inter(
              fontSize: 11.sp,
              color: AppTheme.textSecondaryLight,
            ),
          ),
          SizedBox(height: 1.h),
          Row(
            children: [
              _buildMetricChip(
                'Fraud Score',
                '${(fraudScore * 100).toStringAsFixed(0)}%',
                Colors.red,
              ),
              SizedBox(width: 2.w),
              _buildMetricChip(
                'Confidence',
                '${(confidence * 100).toStringAsFixed(0)}%',
                Colors.orange,
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onInvestigate,
                  icon: Icon(Icons.search, size: 16.sp),
                  label: Text('Investigate'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primaryLight,
                    side: BorderSide(color: AppTheme.primaryLight),
                  ),
                ),
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onDismiss,
                  icon: Icon(Icons.close, size: 16.sp),
                  label: Text('Dismiss'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.grey,
                    side: BorderSide(color: Colors.grey),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricChip(String label, String value, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: GoogleFonts.inter(
              fontSize: 10.sp,
              color: Colors.grey.shade700,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 10.sp,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Color _getRiskColor(String riskLevel) {
    switch (riskLevel) {
      case 'critical':
        return Colors.red.shade900;
      case 'high':
        return Colors.red.shade600;
      case 'medium':
        return Colors.orange.shade600;
      case 'low':
        return Colors.yellow.shade700;
      default:
        return Colors.grey.shade500;
    }
  }

  String _formatEventType(String type) {
    return type
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }
}
