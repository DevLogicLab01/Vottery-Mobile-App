import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

class SystemHealthCardWidget extends StatelessWidget {
  final String overallStatus;
  final double uptimePercentage;
  final int activeIncidents;
  final int compositeScore;

  const SystemHealthCardWidget({
    super.key,
    required this.overallStatus,
    required this.uptimePercentage,
    required this.activeIncidents,
    required this.compositeScore,
  });

  Color get _statusColor {
    switch (overallStatus.toLowerCase()) {
      case 'healthy':
        return const Color(0xFF22C55E);
      case 'degraded':
        return const Color(0xFFF59E0B);
      case 'critical':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF6B7280);
    }
  }

  IconData get _statusIcon {
    switch (overallStatus.toLowerCase()) {
      case 'healthy':
        return Icons.check_circle;
      case 'degraded':
        return Icons.warning_amber;
      case 'critical':
        return Icons.error;
      default:
        return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_statusColor.withAlpha(26), _statusColor.withAlpha(13)],
        ),
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: _statusColor.withAlpha(77), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_statusIcon, color: _statusColor, size: 6.w),
              SizedBox(width: 2.w),
              Text(
                'System Health',
                style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1F2937),
                ),
              ),
              const Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.5.h),
                decoration: BoxDecoration(
                  color: _statusColor,
                  borderRadius: BorderRadius.circular(20.0),
                ),
                child: Text(
                  overallStatus.toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              Expanded(
                child: _MetricTile(
                  label: 'Composite Score',
                  value: '$compositeScore/100',
                  color: _statusColor,
                ),
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: _MetricTile(
                  label: 'Uptime',
                  value: '${uptimePercentage.toStringAsFixed(2)}%',
                  color: const Color(0xFF3B82F6),
                ),
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: _MetricTile(
                  label: 'Active Incidents',
                  value: '$activeIncidents',
                  color: activeIncidents > 0
                      ? const Color(0xFFEF4444)
                      : const Color(0xFF22C55E),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MetricTile({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(2.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 13.sp,
              fontWeight: FontWeight.w700,
              color: color,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 0.3.h),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 9.sp,
              color: const Color(0xFF6B7280),
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
        ],
      ),
    );
  }
}
