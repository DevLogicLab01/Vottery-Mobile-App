import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

class AlertPipelineStatusWidget extends StatelessWidget {
  final Map<String, dynamic> pipelineStatus;
  final bool isPipelineSuspended;
  final Map<String, dynamic> errorStats;
  final String slackChannel;

  const AlertPipelineStatusWidget({
    super.key,
    required this.pipelineStatus,
    required this.isPipelineSuspended,
    required this.errorStats,
    required this.slackChannel,
  });

  @override
  Widget build(BuildContext context) {
    final deliveryRate =
        (pipelineStatus['delivery_rate'] as num?)?.toDouble() ?? 98.5;
    final activeIntegrations =
        (pipelineStatus['active_integrations'] as num?)?.toInt() ?? 3;
    final totalSent24h =
        (pipelineStatus['total_sent_24h'] as num?)?.toInt() ?? 0;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isPipelineSuspended
              ? [const Color(0xFF7C3A00), const Color(0xFF1A0A00)]
              : [const Color(0xFF1A1F3A), const Color(0xFF0D1117)],
        ),
        border: Border(
          bottom: BorderSide(
            color: isPipelineSuspended
                ? Colors.orange.withAlpha(100)
                : const Color(0xFF6366F1).withAlpha(80),
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isPipelineSuspended ? Colors.orange : Colors.green,
              boxShadow: [
                BoxShadow(
                  color: (isPipelineSuspended ? Colors.orange : Colors.green)
                      .withAlpha(150),
                  blurRadius: 6,
                ),
              ],
            ),
          ),
          SizedBox(width: 2.w),
          Text(
            isPipelineSuspended ? 'PIPELINE SUSPENDED' : 'PIPELINE ACTIVE',
            style: GoogleFonts.inter(
              color: isPipelineSuspended ? Colors.orange : Colors.green,
              fontSize: 10.sp,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          SizedBox(width: 4.w),
          Text(
            slackChannel,
            style: GoogleFonts.inter(
              color: const Color(0xFF6366F1),
              fontSize: 10.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          _buildStatChip(
            '${deliveryRate.toStringAsFixed(1)}%',
            'Delivery',
            Colors.green,
          ),
          SizedBox(width: 2.w),
          _buildStatChip(
            '$activeIntegrations',
            'Integrations',
            const Color(0xFF6366F1),
          ),
          SizedBox(width: 2.w),
          _buildStatChip('$totalSent24h', '24h Alerts', Colors.blue),
        ],
      ),
    );
  }

  Widget _buildStatChip(String value, String label, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(6.0),
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: GoogleFonts.inter(
              color: color,
              fontSize: 11.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.inter(color: Colors.white54, fontSize: 8.sp),
          ),
        ],
      ),
    );
  }
}
