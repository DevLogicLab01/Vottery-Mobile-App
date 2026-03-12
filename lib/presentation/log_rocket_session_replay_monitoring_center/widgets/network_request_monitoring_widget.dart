import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import 'package:timeago/timeago.dart' as timeago;

class NetworkRequestMonitoringWidget extends StatelessWidget {
  final List<Map<String, dynamic>> requests;

  const NetworkRequestMonitoringWidget({super.key, required this.requests});

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
              Icon(
                Icons.network_check,
                color: const Color(0xFFF59E0B),
                size: 20.sp,
              ),
              SizedBox(width: 2.w),
              Text(
                'Network Request Monitoring',
                style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          ...requests.take(8).map((request) => _buildRequestCard(request)),
        ],
      ),
    );
  }

  Widget _buildRequestCard(Map<String, dynamic> request) {
    final statusCode = request['status_code'] as int;
    final isError = statusCode >= 400;
    final method = request['method'] as String;

    return Container(
      margin: EdgeInsets.only(bottom: 1.5.h),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: isError ? Colors.red[50] : Colors.grey[50],
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(
          color: isError ? Colors.red[200]! : Colors.grey[200]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildMethodBadge(method),
              SizedBox(width: 2.w),
              Expanded(
                child: Text(
                  request['endpoint'] as String,
                  style: GoogleFonts.inter(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              _buildStatusBadge(statusCode),
            ],
          ),
          SizedBox(height: 1.h),
          Row(
            children: [
              _buildInfoChip(
                Icons.timer,
                '${request['duration_ms']}ms',
                isError ? Colors.red[700]! : Colors.grey[600]!,
              ),
              SizedBox(width: 2.w),
              _buildInfoChip(
                Icons.data_usage,
                request['payload_size'] as String,
                Colors.grey[600]!,
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: Text(
                  timeago.format(request['timestamp'] as DateTime),
                  style: GoogleFonts.inter(
                    fontSize: 9.sp,
                    color: Colors.grey[500],
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMethodBadge(String method) {
    final colors = _getMethodColors(method);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
      decoration: BoxDecoration(
        color: colors['bg'],
        borderRadius: BorderRadius.circular(4.0),
      ),
      child: Text(
        method,
        style: GoogleFonts.inter(
          fontSize: 9.sp,
          fontWeight: FontWeight.bold,
          color: colors['text'],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(int statusCode) {
    final isSuccess = statusCode >= 200 && statusCode < 300;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
      decoration: BoxDecoration(
        color: isSuccess ? Colors.green[100] : Colors.red[100],
        borderRadius: BorderRadius.circular(4.0),
      ),
      child: Text(
        statusCode.toString(),
        style: GoogleFonts.inter(
          fontSize: 9.sp,
          fontWeight: FontWeight.bold,
          color: isSuccess ? Colors.green[700] : Colors.red[700],
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12.sp, color: color),
        SizedBox(width: 1.w),
        Text(
          text,
          style: GoogleFonts.inter(fontSize: 9.sp, color: color),
        ),
      ],
    );
  }

  Map<String, Color> _getMethodColors(String method) {
    switch (method) {
      case 'GET':
        return {'bg': Colors.blue[100]!, 'text': Colors.blue[700]!};
      case 'POST':
        return {'bg': Colors.green[100]!, 'text': Colors.green[700]!};
      case 'PUT':
        return {'bg': Colors.orange[100]!, 'text': Colors.orange[700]!};
      case 'DELETE':
        return {'bg': Colors.red[100]!, 'text': Colors.red[700]!};
      default:
        return {'bg': Colors.grey[100]!, 'text': Colors.grey[700]!};
    }
  }
}
