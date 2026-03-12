import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class RemediationActionsLogWidget extends StatelessWidget {
  final List<Map<String, dynamic>> remediationActions;

  const RemediationActionsLogWidget({
    super.key,
    required this.remediationActions,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 8.0,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.healing, color: Colors.purple[700], size: 20.sp),
              SizedBox(width: 2.w),
              Text(
                'Automated Remediation Actions',
                style: GoogleFonts.inter(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Text(
            'Recent automated fixes and system adjustments',
            style: GoogleFonts.inter(fontSize: 11.sp, color: Colors.grey[600]),
          ),
          SizedBox(height: 2.h),
          ...remediationActions.map((action) => _buildActionCard(action)),
        ],
      ),
    );
  }

  Widget _buildActionCard(Map<String, dynamic> action) {
    final actionType = action['action_type'] ?? 'unknown';
    final triggerMetric = action['trigger_metric'] ?? 'Unknown';
    final actionResult = action['action_result'] ?? 'Unknown';
    final executionTime = action['execution_time'] ?? 0.0;
    final executedAt = action['executed_at'] as DateTime?;

    IconData actionIcon = Icons.settings;
    Color actionColor = Colors.blue;

    if (actionType == 'service_restart') {
      actionIcon = Icons.restart_alt;
      actionColor = Colors.orange;
    } else if (actionType == 'fallback_api_activation') {
      actionIcon = Icons.swap_horiz;
      actionColor = Colors.purple;
    } else if (actionType == 'circuit_breaker_engagement') {
      actionIcon = Icons.power_settings_new;
      actionColor = Colors.red;
    } else if (actionType == 'rate_limiting_adjustment') {
      actionIcon = Icons.tune;
      actionColor = Colors.teal;
    }

    final resultColor = actionResult == 'Success' ? Colors.green : Colors.red;

    return Container(
      margin: EdgeInsets.only(bottom: 1.5.h),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: actionColor.withAlpha(13),
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: actionColor.withAlpha(51)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(actionIcon, color: actionColor, size: 18.sp),
              SizedBox(width: 2.w),
              Expanded(
                child: Text(
                  _formatActionType(actionType),
                  style: GoogleFonts.inter(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                decoration: BoxDecoration(
                  color: resultColor,
                  borderRadius: BorderRadius.circular(4.0),
                ),
                child: Text(
                  actionResult,
                  style: GoogleFonts.inter(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Text(
            'Trigger: $triggerMetric',
            style: GoogleFonts.inter(fontSize: 11.sp, color: Colors.grey[700]),
          ),
          SizedBox(height: 0.5.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Execution: ${executionTime.toStringAsFixed(2)}s',
                style: GoogleFonts.inter(
                  fontSize: 10.sp,
                  color: Colors.grey[600],
                ),
              ),
              if (executedAt != null)
                Text(
                  DateFormat('MMM dd, HH:mm').format(executedAt),
                  style: GoogleFonts.inter(
                    fontSize: 10.sp,
                    color: Colors.grey[600],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatActionType(String actionType) {
    return actionType
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }
}
