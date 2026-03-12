import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

class RecommendationCardWidget extends StatelessWidget {
  final Map<String, dynamic> recommendation;
  final VoidCallback onViewDetails;
  final VoidCallback onApply;
  final VoidCallback onScheduleAbTest;

  const RecommendationCardWidget({
    super.key,
    required this.recommendation,
    required this.onViewDetails,
    required this.onApply,
    required this.onScheduleAbTest,
  });

  Color get _priorityColor {
    switch ((recommendation['implementation_priority'] as String? ?? '')
        .toLowerCase()) {
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

  @override
  Widget build(BuildContext context) {
    final screenName = recommendation['screen_name'] as String? ?? 'Unknown';
    final issueType = recommendation['issue_type'] as String? ?? '';
    final recommendationText =
        recommendation['recommendation_text'] as String? ?? '';
    final priority =
        recommendation['implementation_priority'] as String? ?? 'low';
    final expectedImpact =
        recommendation['expected_impact'] as Map<String, dynamic>? ?? {};
    final status = recommendation['status'] as String? ?? 'pending';

    final latencyReduction =
        (expectedImpact['latency_reduction_percent'] as num?)?.toDouble() ?? 0;
    final memorySavings =
        (expectedImpact['memory_savings_percent'] as num?)?.toDouble() ?? 0;

    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: _priorityColor.withAlpha(51), width: 1.5),
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
          // Header
          Container(
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: _priorityColor.withAlpha(13),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        screenName,
                        style: GoogleFonts.inter(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1F2937),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (issueType.isNotEmpty)
                        Text(
                          issueType,
                          style: GoogleFonts.inter(
                            fontSize: 9.sp,
                            color: const Color(0xFF6B7280),
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 2.5.w,
                    vertical: 0.4.h,
                  ),
                  decoration: BoxDecoration(
                    color: _priorityColor,
                    borderRadius: BorderRadius.circular(6.0),
                  ),
                  child: Text(
                    priority.toUpperCase(),
                    style: GoogleFonts.inter(
                      fontSize: 8.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
                SizedBox(width: 2.w),
                _StatusBadge(status: status),
              ],
            ),
          ),
          // Body
          Padding(
            padding: EdgeInsets.all(3.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  recommendationText,
                  style: GoogleFonts.inter(
                    fontSize: 11.sp,
                    color: const Color(0xFF374151),
                    height: 1.5,
                  ),
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 1.5.h),
                // Impact metrics
                Row(
                  children: [
                    if (latencyReduction > 0)
                      _ImpactChip(
                        icon: Icons.speed,
                        label:
                            '-${latencyReduction.toStringAsFixed(0)}% latency',
                        color: const Color(0xFF22C55E),
                      ),
                    if (latencyReduction > 0) SizedBox(width: 2.w),
                    if (memorySavings > 0)
                      _ImpactChip(
                        icon: Icons.memory,
                        label: '-${memorySavings.toStringAsFixed(0)}% memory',
                        color: const Color(0xFF3B82F6),
                      ),
                  ],
                ),
                SizedBox(height: 1.5.h),
                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: onViewDetails,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF7C3AED),
                          side: const BorderSide(color: Color(0xFF7C3AED)),
                          padding: EdgeInsets.symmetric(vertical: 0.8.h),
                        ),
                        child: Text(
                          'Details',
                          style: GoogleFonts.inter(fontSize: 9.sp),
                        ),
                      ),
                    ),
                    SizedBox(width: 1.5.w),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: status == 'pending' ? onApply : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 0.8.h),
                        ),
                        child: Text(
                          'Apply',
                          style: GoogleFonts.inter(fontSize: 9.sp),
                        ),
                      ),
                    ),
                    SizedBox(width: 1.5.w),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: onScheduleAbTest,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3B82F6),
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 0.8.h),
                        ),
                        child: Text(
                          'A/B Test',
                          style: GoogleFonts.inter(fontSize: 9.sp),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ImpactChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _ImpactChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.4.h),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(6.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 3.w, color: color),
          SizedBox(width: 1.w),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 9.sp,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case 'completed':
        color = const Color(0xFF22C55E);
        break;
      case 'in_progress':
        color = const Color(0xFF3B82F6);
        break;
      default:
        color = const Color(0xFF9CA3AF);
    }
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.3.h),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(4.0),
      ),
      child: Text(
        status.replaceAll('_', ' ').toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 7.sp,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
