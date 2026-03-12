import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';


class OpportunityCardsWidget extends StatelessWidget {
  final List<Map<String, dynamic>> opportunities;

  const OpportunityCardsWidget({super.key, required this.opportunities});

  Color _getImpactColor(String impact) {
    switch (impact.toUpperCase()) {
      case 'HIGH':
        return const Color(0xFF10B981);
      case 'MEDIUM':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF6B7280);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Growth Opportunities',
          style: GoogleFonts.inter(
            fontSize: 15.sp,
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurface,
          ),
        ),
        SizedBox(height: 1.5.h),
        ...opportunities.take(3).map((opp) {
          final impact = opp['impact'] as String? ?? 'MEDIUM';
          final impactColor = _getImpactColor(impact);
          final revenueIncrease =
              (opp['expected_revenue_increase'] as num?)?.toDouble() ?? 0.0;

          return Container(
            margin: EdgeInsets.only(bottom: 1.5.h),
            padding: EdgeInsets.all(3.5.w),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12.0),
              border: Border.all(color: impactColor.withAlpha(77)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 2.w,
                    vertical: 0.5.h,
                  ),
                  decoration: BoxDecoration(
                    color: impactColor.withAlpha(26),
                    borderRadius: BorderRadius.circular(6.0),
                    border: Border.all(color: impactColor.withAlpha(77)),
                  ),
                  child: Text(
                    impact,
                    style: GoogleFonts.inter(
                      fontSize: 9.sp,
                      fontWeight: FontWeight.w700,
                      color: impactColor,
                    ),
                  ),
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        opp['title'] as String? ?? '',
                        style: GoogleFonts.inter(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      SizedBox(height: 0.5.h),
                      Text(
                        opp['description'] as String? ?? '',
                        style: GoogleFonts.inter(
                          fontSize: 10.sp,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 2.w),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '+${revenueIncrease.toInt()}%',
                      style: GoogleFonts.inter(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF10B981),
                      ),
                    ),
                    Text(
                      'revenue',
                      style: GoogleFonts.inter(
                        fontSize: 9.sp,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
