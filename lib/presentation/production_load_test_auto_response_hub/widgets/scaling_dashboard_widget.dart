import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import '../../../theme/app_theme.dart';

class ScalingDashboardWidget extends StatelessWidget {
  final List<Map<String, dynamic>> responseLog;
  final bool isScaling;

  const ScalingDashboardWidget({
    super.key,
    required this.responseLog,
    required this.isScaling,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'System Scaling Dashboard',
              style: GoogleFonts.inter(
                fontSize: 13.sp,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimaryLight,
              ),
            ),
            SizedBox(width: 2.w),
            if (isScaling)
              SizedBox(
                width: 4.w,
                height: 4.w,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppTheme.primaryLight,
                ),
              ),
          ],
        ),
        SizedBox(height: 1.h),
        _buildScalingMetrics(),
        SizedBox(height: 1.5.h),
        Text(
          'Response Action Log',
          style: GoogleFonts.inter(
            fontSize: 12.sp,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimaryLight,
          ),
        ),
        SizedBox(height: 0.5.h),
        if (responseLog.isEmpty)
          Text(
            'No actions executed yet',
            style: GoogleFonts.inter(
              fontSize: 11.sp,
              color: AppTheme.textSecondaryLight,
            ),
          )
        else
          ...responseLog.map((log) => _buildLogEntry(log)),
      ],
    );
  }

  Widget _buildScalingMetrics() {
    return Row(
      children: [
        Expanded(
          child: _buildMetricTile(
            'Connection Pool',
            '+50%',
            Icons.storage,
            Colors.blue,
          ),
        ),
        SizedBox(width: 2.w),
        Expanded(
          child: _buildMetricTile(
            'Read Replicas',
            '3 Active',
            Icons.copy,
            Colors.purple,
          ),
        ),
        SizedBox(width: 2.w),
        Expanded(
          child: _buildMetricTile(
            'Rate Limit',
            '100 RPS',
            Icons.speed,
            Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricTile(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(2.w),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 5.w),
          SizedBox(height: 0.5.h),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 11.sp,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 9.sp,
              color: AppTheme.textSecondaryLight,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLogEntry(Map<String, dynamic> log) {
    final isSuccess = log['status'] == 'success';
    return Container(
      margin: EdgeInsets.only(bottom: 0.5.h),
      padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
      decoration: BoxDecoration(
        color: isSuccess
            ? Colors.green.withAlpha(15)
            : Colors.red.withAlpha(15),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Row(
        children: [
          Icon(
            isSuccess ? Icons.check : Icons.error,
            color: isSuccess ? Colors.green : Colors.red,
            size: 4.w,
          ),
          SizedBox(width: 2.w),
          Expanded(
            child: Text(
              '${log['action'] ?? ''}: ${log['details'] ?? ''}',
              style: GoogleFonts.inter(
                fontSize: 10.sp,
                color: AppTheme.textPrimaryLight,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }
}
