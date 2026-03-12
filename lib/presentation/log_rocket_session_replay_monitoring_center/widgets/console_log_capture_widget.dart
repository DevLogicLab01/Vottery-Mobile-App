import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import 'package:timeago/timeago.dart' as timeago;

class ConsoleLogCaptureWidget extends StatelessWidget {
  final List<Map<String, dynamic>> logs;

  const ConsoleLogCaptureWidget({super.key, required this.logs});

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
              Icon(Icons.terminal, color: const Color(0xFF10B981), size: 20.sp),
              SizedBox(width: 2.w),
              Text(
                'Console Log Capture',
                style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const Spacer(),
              _buildLegend(),
            ],
          ),
          SizedBox(height: 2.h),
          ...logs.take(10).map((log) => _buildLogEntry(log)),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    return Row(
      children: [
        _buildLegendItem('Debug', Colors.blue[100]!, Colors.blue[700]!),
        SizedBox(width: 2.w),
        _buildLegendItem('Info', Colors.green[100]!, Colors.green[700]!),
        SizedBox(width: 2.w),
        _buildLegendItem('Warning', Colors.orange[100]!, Colors.orange[700]!),
        SizedBox(width: 2.w),
        _buildLegendItem('Error', Colors.red[100]!, Colors.red[700]!),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color bgColor, Color textColor) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4.0),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 8.sp,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildLogEntry(Map<String, dynamic> log) {
    final level = log['level'] as String;
    final colors = _getLogColors(level);

    return Container(
      margin: EdgeInsets.only(bottom: 1.h),
      padding: EdgeInsets.all(2.w),
      decoration: BoxDecoration(
        color: colors['bg'],
        borderRadius: BorderRadius.circular(6.0),
        border: Border.all(color: colors['border']!),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
            decoration: BoxDecoration(
              color: colors['badge'],
              borderRadius: BorderRadius.circular(4.0),
            ),
            child: Text(
              level.toUpperCase(),
              style: GoogleFonts.inter(
                fontSize: 8.sp,
                fontWeight: FontWeight.bold,
                color: colors['text'],
              ),
            ),
          ),
          SizedBox(width: 2.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  log['message'] as String,
                  style: GoogleFonts.inter(
                    fontSize: 10.sp,
                    color: Colors.grey[800],
                  ),
                ),
                SizedBox(height: 0.5.h),
                Text(
                  '${log['screen']} • ${timeago.format(log['timestamp'] as DateTime)}',
                  style: GoogleFonts.inter(
                    fontSize: 9.sp,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Map<String, Color> _getLogColors(String level) {
    switch (level) {
      case 'error':
        return {
          'bg': Colors.red[50]!,
          'border': Colors.red[200]!,
          'badge': Colors.red[100]!,
          'text': Colors.red[700]!,
        };
      case 'warning':
        return {
          'bg': Colors.orange[50]!,
          'border': Colors.orange[200]!,
          'badge': Colors.orange[100]!,
          'text': Colors.orange[700]!,
        };
      case 'info':
        return {
          'bg': Colors.green[50]!,
          'border': Colors.green[200]!,
          'badge': Colors.green[100]!,
          'text': Colors.green[700]!,
        };
      default:
        return {
          'bg': Colors.blue[50]!,
          'border': Colors.blue[200]!,
          'badge': Colors.blue[100]!,
          'text': Colors.blue[700]!,
        };
    }
  }
}
