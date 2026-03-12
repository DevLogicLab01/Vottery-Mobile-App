import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import '../../../services/realtime_gamification_notification_service.dart';

class RetryConfigPanelWidget extends StatelessWidget {
  final RetryConfig config;

  const RetryConfigPanelWidget({super.key, required this.config});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.settings_backup_restore,
                  color: Colors.blue[600],
                  size: 20,
                ),
                SizedBox(width: 2.w),
                Text(
                  'Retry Configuration',
                  style: GoogleFonts.inter(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            SizedBox(height: 2.h),
            _buildConfigRow(
              'Max Retries',
              '${config.maxRetries}',
              Icons.repeat,
            ),
            _buildConfigRow(
              'Initial Delay',
              '${config.initialDelay.inSeconds}s',
              Icons.timer,
            ),
            _buildConfigRow(
              'Backoff Multiplier',
              '${config.backoffMultiplier}x',
              Icons.trending_up,
            ),
            _buildConfigRow(
              'Max Delay',
              '${config.maxDelay.inSeconds}s',
              Icons.timer_off,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfigRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12.sp,
                color: Colors.grey[700],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(6.0),
            ),
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 12.sp,
                fontWeight: FontWeight.w700,
                color: Colors.blue[700],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
