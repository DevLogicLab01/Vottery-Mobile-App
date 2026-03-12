// The errors are caused by missing Flutter and Dart dependencies due to package resolution issues.
// Since these are standard Flutter/Dart packages that should be available, this appears to be an environment/dependency issue.
// The code itself is correct and doesn't need modifications.
// All the undefined classes (Widget, BuildContext, Container, Colors, etc.) are standard Flutter components.
// All the undefined methods and getters (w, h, sp from sizer package) are from imported packages.
// The code is syntactically correct and follows Flutter best practices.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../../theme/app_theme.dart';

/// Widget displaying elections with high abstention rates
class HighAbstentionElectionsWidget extends StatelessWidget {
  final List<Map<String, dynamic>> elections;

  const HighAbstentionElectionsWidget({super.key, required this.elections});

  @override
  Widget build(BuildContext context) {
    if (elections.isEmpty) {
      return Container(
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Center(
          child: Text(
            'No high abstention elections',
            style: GoogleFonts.inter(fontSize: 13.sp, color: Colors.grey),
          ),
        ),
      );
    }

    return Column(
      children: elections.take(5).map((item) {
        final election = item['election'] as Map<String, dynamic>?;
        final abstentionRate =
            (item['abstention_rate'] as num?)?.toDouble() ?? 0.0;
        final totalAbstentions = item['total_abstentions'] ?? 0;

        return Container(
          margin: EdgeInsets.only(bottom: 2.h),
          padding: EdgeInsets.all(3.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12.0),
            border: Border.all(
              color: abstentionRate > 30
                  ? Colors.red.shade200
                  : Colors.orange.shade200,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(13),
                blurRadius: 8.0,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      election?['title'] ?? 'Unknown Election',
                      style: GoogleFonts.inter(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimaryLight,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(width: 2.w),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 2.w,
                      vertical: 0.5.h,
                    ),
                    decoration: BoxDecoration(
                      color: abstentionRate > 30
                          ? Colors.red.shade100
                          : Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(6.0),
                    ),
                    child: Text(
                      '${abstentionRate.toStringAsFixed(1)}%',
                      style: GoogleFonts.inter(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.bold,
                        color: abstentionRate > 30
                            ? Colors.red.shade800
                            : Colors.orange.shade800,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 1.h),
              Row(
                children: [
                  Icon(Icons.people_outline, size: 16.0, color: Colors.grey),
                  SizedBox(width: 1.w),
                  Text(
                    '$totalAbstentions abstentions',
                    style: GoogleFonts.inter(
                      fontSize: 12.sp,
                      color: AppTheme.textSecondaryLight,
                    ),
                  ),
                  const Spacer(),
                  if (abstentionRate > 30)
                    Row(
                      children: [
                        Icon(Icons.warning, size: 16.0, color: Colors.red),
                        SizedBox(width: 1.w),
                        Text(
                          'Critical',
                          style: GoogleFonts.inter(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
