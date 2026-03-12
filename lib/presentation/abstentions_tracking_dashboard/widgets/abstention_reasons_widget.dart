import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../../theme/app_theme.dart';

/// Widget displaying categorized abstention reasons
class AbstentionReasonsWidget extends StatelessWidget {
  const AbstentionReasonsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock data for demonstration
    final reasons = [
      {
        'reason': 'Lack of Information',
        'count': 145,
        'percentage': 38.5,
        'color': Colors.blue,
        'icon': Icons.info_outline,
      },
      {
        'reason': 'Neutral Stance',
        'count': 98,
        'percentage': 26.0,
        'color': Colors.orange,
        'icon': Icons.balance,
      },
      {
        'reason': 'Protest Vote',
        'count': 67,
        'percentage': 17.8,
        'color': Colors.red,
        'icon': Icons.campaign,
      },
      {
        'reason': 'Unspecified',
        'count': 67,
        'percentage': 17.7,
        'color': Colors.grey,
        'icon': Icons.help_outline,
      },
    ];

    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 8.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: reasons.map((reason) {
          return Container(
            margin: EdgeInsets.only(bottom: 2.h),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(2.w),
                      decoration: BoxDecoration(
                        color: (reason['color'] as Color).withAlpha(26),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: Icon(
                        reason['icon'] as IconData,
                        color: reason['color'] as Color,
                        size: 20.0,
                      ),
                    ),
                    SizedBox(width: 3.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            reason['reason'] as String,
                            style: GoogleFonts.inter(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimaryLight,
                            ),
                          ),
                          SizedBox(height: 0.5.h),
                          Text(
                            '${reason['count']} abstentions',
                            style: GoogleFonts.inter(
                              fontSize: 11.sp,
                              color: AppTheme.textSecondaryLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${(reason['percentage'] as num).toStringAsFixed(1)}%',
                      style: GoogleFonts.inter(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                        color: reason['color'] as Color,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 1.h),
                LinearProgressIndicator(
                  value: (reason['percentage'] as num) / 100,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    reason['color'] as Color,
                  ),
                  minHeight: 6,
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
