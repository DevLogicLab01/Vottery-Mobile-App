import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

class AlertCardWidget extends StatelessWidget {
  final Map<String, dynamic> alert;
  final VoidCallback onAcknowledge;
  final VoidCallback onEscalate;

  const AlertCardWidget({
    super.key,
    required this.alert,
    required this.onAcknowledge,
    required this.onEscalate,
  });

  Color get _severityColor {
    switch ((alert['severity'] as String? ?? '').toLowerCase()) {
      case 'critical':
        return const Color(0xFFEF4444);
      case 'high':
        return const Color(0xFFF97316);
      case 'medium':
        return const Color(0xFFF59E0B);
      case 'low':
        return const Color(0xFF3B82F6);
      default:
        return const Color(0xFF6B7280);
    }
  }

  IconData get _sourceIcon {
    switch ((alert['source'] as String? ?? '').toLowerCase()) {
      case 'datadog':
        return Icons.monitor_heart;
      case 'supabase':
        return Icons.storage;
      case 'performance':
        return Icons.speed;
      case 'ads':
        return Icons.ads_click;
      default:
        return Icons.notifications;
    }
  }

  @override
  Widget build(BuildContext context) {
    final severity = alert['severity'] as String? ?? 'low';
    final source = alert['source'] as String? ?? 'unknown';
    final message = alert['message'] as String? ?? '';
    final affectedComponent = alert['affected_component'] as String? ?? 'N/A';
    final timestamp = alert['created_at'] as String? ?? '';
    final acknowledged = alert['acknowledged'] as bool? ?? false;

    return Container(
      margin: EdgeInsets.only(bottom: 1.5.h),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: _severityColor.withAlpha(77), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_sourceIcon, color: _severityColor, size: 4.w),
              SizedBox(width: 2.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 2.w,
                            vertical: 0.3.h,
                          ),
                          decoration: BoxDecoration(
                            color: _severityColor,
                            borderRadius: BorderRadius.circular(4.0),
                          ),
                          child: Text(
                            severity.toUpperCase(),
                            style: GoogleFonts.inter(
                              fontSize: 8.sp,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        SizedBox(width: 2.w),
                        Text(
                          source.toUpperCase(),
                          style: GoogleFonts.inter(
                            fontSize: 9.sp,
                            color: const Color(0xFF6B7280),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (acknowledged) ...[
                          SizedBox(width: 2.w),
                          Icon(
                            Icons.check_circle,
                            color: const Color(0xFF22C55E),
                            size: 3.5.w,
                          ),
                        ],
                      ],
                    ),
                    SizedBox(height: 0.3.h),
                    Text(
                      timestamp,
                      style: GoogleFonts.inter(
                        fontSize: 8.sp,
                        color: const Color(0xFF9CA3AF),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Text(
            message,
            style: GoogleFonts.inter(
              fontSize: 11.sp,
              color: const Color(0xFF374151),
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 0.5.h),
          Text(
            'Component: $affectedComponent',
            style: GoogleFonts.inter(
              fontSize: 9.sp,
              color: const Color(0xFF6B7280),
            ),
          ),
          SizedBox(height: 1.h),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: acknowledged ? null : onAcknowledge,
                  icon: Icon(Icons.check, size: 3.5.w),
                  label: Text(
                    'Acknowledge',
                    style: GoogleFonts.inter(fontSize: 9.sp),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF22C55E),
                    side: const BorderSide(color: Color(0xFF22C55E)),
                    padding: EdgeInsets.symmetric(vertical: 0.8.h),
                  ),
                ),
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onEscalate,
                  icon: Icon(Icons.arrow_upward, size: 3.5.w),
                  label: Text(
                    'Escalate',
                    style: GoogleFonts.inter(fontSize: 9.sp),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _severityColor,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 0.8.h),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
