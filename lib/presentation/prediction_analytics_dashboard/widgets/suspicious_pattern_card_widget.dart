import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

class SuspiciousPatternCardWidget extends StatelessWidget {
  final Map<String, dynamic> pattern;
  final VoidCallback? onInvestigate;

  const SuspiciousPatternCardWidget({
    super.key,
    required this.pattern,
    this.onInvestigate,
  });

  @override
  Widget build(BuildContext context) {
    final patternType =
        pattern['pattern_type']?.toString() ?? 'Unknown Pattern';
    final affectedUsers = pattern['affected_users'] ?? 0;
    final confidenceScore =
        (pattern['confidence_score'] as num?)?.toDouble() ?? 0.0;
    final severity = pattern['severity']?.toString() ?? 'medium';

    final severityColor = severity == 'high'
        ? const Color(0xFFFF6B6B)
        : severity == 'medium'
        ? const Color(0xFFFFB347)
        : const Color(0xFF4ECDC4);

    return Container(
      margin: EdgeInsets.only(bottom: 1.5.h),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(color: severityColor.withAlpha(77)),
        boxShadow: [
          BoxShadow(
            color: severityColor.withAlpha(20),
            blurRadius: 6,
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
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.4.h),
                decoration: BoxDecoration(
                  color: severityColor.withAlpha(38),
                  borderRadius: BorderRadius.circular(6.0),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      severity == 'high'
                          ? Icons.warning_rounded
                          : Icons.info_rounded,
                      color: severityColor,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      severity.toUpperCase(),
                      style: GoogleFonts.inter(
                        fontSize: 9.sp,
                        fontWeight: FontWeight.w700,
                        color: severityColor,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                'Confidence: ${(confidenceScore * 100).toStringAsFixed(0)}%',
                style: GoogleFonts.inter(
                  fontSize: 10.sp,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Text(
            _formatPatternType(patternType),
            style: GoogleFonts.inter(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1A1A2E),
            ),
          ),
          SizedBox(height: 0.5.h),
          Row(
            children: [
              Icon(Icons.people_rounded, size: 14, color: Colors.grey[500]),
              const SizedBox(width: 4),
              Text(
                '$affectedUsers users affected',
                style: GoogleFonts.inter(
                  fontSize: 10.sp,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onInvestigate,
              icon: const Icon(Icons.search_rounded, size: 14),
              label: Text(
                'Investigate',
                style: GoogleFonts.inter(
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: severityColor,
                side: BorderSide(color: severityColor),
                padding: EdgeInsets.symmetric(vertical: 0.8.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatPatternType(String type) {
    switch (type) {
      case 'coordinated_prediction_groups':
        return 'Coordinated Prediction Groups';
      case 'impossible_accuracy':
        return 'Impossible Accuracy Detected';
      case 'bot_prediction_patterns':
        return 'Bot Prediction Patterns';
      default:
        return type
            .replaceAll('_', ' ')
            .split(' ')
            .map(
              (w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}',
            )
            .join(' ');
    }
  }
}
