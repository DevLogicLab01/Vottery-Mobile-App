import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../../theme/app_theme.dart';

/// Widget providing tie prevention recommendations
class TiePreventionWidget extends StatelessWidget {
  const TiePreventionWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tie Prevention Recommendations',
          style: GoogleFonts.inter(
            fontSize: 15.sp,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimaryLight,
          ),
        ),
        SizedBox(height: 2.h),
        _buildRecommendationCard(
          icon: Icons.how_to_vote,
          title: 'Use Approval Voting',
          description:
              'For elections with 2 candidates, approval voting reduces tie probability by allowing voters to approve multiple candidates.',
          riskReduction: 'High',
          color: Colors.green,
        ),
        _buildRecommendationCard(
          icon: Icons.format_list_numbered,
          title: 'Ranked Choice Voting',
          description:
              'Ranked choice voting provides tie-breaking through preference rankings, reducing the need for runoff elections.',
          riskReduction: 'Medium',
          color: Colors.blue,
        ),
        _buildRecommendationCard(
          icon: Icons.people,
          title: 'Increase Candidate Count',
          description:
              'Elections with 3+ candidates have lower tie probability than binary choices.',
          riskReduction: 'Medium',
          color: Colors.orange,
        ),
        _buildRecommendationCard(
          icon: Icons.casino,
          title: 'Enable Lottery Tie-Breaking',
          description:
              'For gamified elections, automatic lottery tie-breaking ensures winners are always selected.',
          riskReduction: 'Guaranteed',
          color: Colors.purple,
        ),
      ],
    );
  }

  Widget _buildRecommendationCard({
    required IconData icon,
    required String title,
    required String description,
    required String riskReduction,
    required Color color,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: color.withAlpha(77)),
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
              Container(
                padding: EdgeInsets.all(2.w),
                decoration: BoxDecoration(
                  color: color.withAlpha(26),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Icon(icon, color: color, size: 24.0),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimaryLight,
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                decoration: BoxDecoration(
                  color: color.withAlpha(26),
                  borderRadius: BorderRadius.circular(6.0),
                ),
                child: Text(
                  riskReduction,
                  style: GoogleFonts.inter(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 1.5.h),
          Text(
            description,
            style: GoogleFonts.inter(
              fontSize: 12.sp,
              color: AppTheme.textSecondaryLight,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
