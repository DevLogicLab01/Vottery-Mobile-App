import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

class VotingAnomaly {
  final String id;
  final String anomalyType;
  final String severity; // low | medium | high | critical
  final String affectedElectionId;
  final String details;
  final DateTime detectedAt;

  const VotingAnomaly({
    required this.id,
    required this.anomalyType,
    required this.severity,
    required this.affectedElectionId,
    required this.details,
    required this.detectedAt,
  });
}

class AnomalyAlertCardWidget extends StatelessWidget {
  final VotingAnomaly anomaly;
  final VoidCallback onInvestigate;

  const AnomalyAlertCardWidget({
    super.key,
    required this.anomaly,
    required this.onInvestigate,
  });

  Color _severityColor(String severity) {
    switch (severity) {
      case 'critical':
        return const Color(0xFFEF4444);
      case 'high':
        return const Color(0xFFF97316);
      case 'medium':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF3B82F6);
    }
  }

  IconData _anomalyIcon(String type) {
    switch (type) {
      case 'vote_spike':
        return Icons.trending_up;
      case 'geographic_concentration':
        return Icons.location_on;
      case 'demographic_anomaly':
        return Icons.people;
      case 'timing_burst':
        return Icons.timer;
      case 'blockchain_mismatch':
        return Icons.link_off;
      default:
        return Icons.warning;
    }
  }

  String _formatType(String type) {
    return type
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : w)
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final color = _severityColor(anomaly.severity);
    return Container(
      margin: EdgeInsets.only(bottom: 1.h),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: color.withAlpha(13),
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(color: color.withAlpha(77)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_anomalyIcon(anomaly.anomalyType), color: color, size: 18),
              SizedBox(width: 1.5.w),
              Expanded(
                child: Text(
                  _formatType(anomaly.anomalyType),
                  style: GoogleFonts.inter(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1A1A2E),
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.3.h),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(6.0),
                ),
                child: Text(
                  anomaly.severity.toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 8.sp,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 0.5.h),
          Text(
            anomaly.details,
            style: GoogleFonts.inter(
              fontSize: 10.sp,
              color: const Color(0xFF6B7280),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 0.5.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Election: ${anomaly.affectedElectionId.length > 8 ? anomaly.affectedElectionId.substring(0, 8) : anomaly.affectedElectionId}...',
                style: GoogleFonts.inter(
                  fontSize: 9.sp,
                  color: const Color(0xFF9CA3AF),
                ),
              ),
              TextButton(
                onPressed: onInvestigate,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.symmetric(
                    horizontal: 2.w,
                    vertical: 0.3.h,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'Investigate →',
                  style: GoogleFonts.inter(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w700,
                    color: color,
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
