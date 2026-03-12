import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

class AnomalyAlertPanelWidget extends StatelessWidget {
  final List<Map<String, dynamic>> anomalies;
  const AnomalyAlertPanelWidget({super.key, required this.anomalies});

  @override
  Widget build(BuildContext context) {
    if (anomalies.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.shield_outlined,
              size: 48,
              color: Color(0xFF4CAF50),
            ),
            SizedBox(height: 2.h),
            Text(
              'No Active Anomalies',
              style: GoogleFonts.inter(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF4CAF50),
              ),
            ),
            Text(
              'All voting patterns are within normal range',
              style: GoogleFonts.inter(
                fontSize: 12.sp,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: EdgeInsets.all(3.w),
      itemCount: anomalies.length,
      itemBuilder: (context, index) =>
          _AnomalyAlertCard(anomaly: anomalies[index]),
    );
  }
}

class _AnomalyAlertCard extends StatelessWidget {
  final Map<String, dynamic> anomaly;
  const _AnomalyAlertCard({required this.anomaly});

  Color _severityColor(String severity) {
    switch (severity) {
      case 'critical':
        return const Color(0xFFE53935);
      case 'high':
        return const Color(0xFFFF6B35);
      case 'medium':
        return const Color(0xFFFF9800);
      default:
        return const Color(0xFF4CAF50);
    }
  }

  @override
  Widget build(BuildContext context) {
    final severity = anomaly['severity']?.toString() ?? 'low';
    final color = _severityColor(severity);
    final anomalyType = anomaly['anomaly_type']?.toString() ?? 'unknown';

    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(color: color.withAlpha(77)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
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
              Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.3.h),
                decoration: BoxDecoration(
                  color: color.withAlpha(26),
                  borderRadius: BorderRadius.circular(4.0),
                ),
                child: Text(
                  severity.toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: Text(
                  anomalyType.replaceAll('_', ' ').toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              TextButton(
                onPressed: () {},
                child: Text(
                  'Investigate',
                  style: GoogleFonts.inter(
                    fontSize: 11.sp,
                    color: const Color(0xFF6C63FF),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (anomaly['details'] != null) ...[
            SizedBox(height: 0.5.h),
            Text(
              anomaly['details'].toString(),
              style: GoogleFonts.inter(
                fontSize: 11.sp,
                color: Colors.grey.shade600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}
