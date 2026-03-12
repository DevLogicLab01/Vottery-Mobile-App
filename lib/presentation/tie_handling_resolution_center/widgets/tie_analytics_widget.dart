import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../../theme/app_theme.dart';

/// Widget displaying tie analytics by voting method
class TieAnalyticsWidget extends StatelessWidget {
  final List<Map<String, dynamic>> analyticsData;

  const TieAnalyticsWidget({super.key, required this.analyticsData});

  @override
  Widget build(BuildContext context) {
    if (analyticsData.isEmpty) {
      return Center(
        child: Text(
          'No tie analytics available',
          style: GoogleFonts.inter(fontSize: 13.sp, color: Colors.grey),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tie Frequency by Voting Method',
          style: GoogleFonts.inter(
            fontSize: 15.sp,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimaryLight,
          ),
        ),
        SizedBox(height: 2.h),
        ...analyticsData.map((data) => _buildAnalyticsCard(data)),
      ],
    );
  }

  Widget _buildAnalyticsCard(Map<String, dynamic> data) {
    final votingMethod = data['voting_method'] ?? 'Unknown';
    final totalTies = data['total_ties'] ?? 0;
    final runoffResolutions = data['runoff_resolutions'] ?? 0;
    final manualResolutions = data['manual_resolutions'] ?? 0;
    final lotteryResolutions = data['lottery_resolutions'] ?? 0;
    final avgResolutionTime =
        (data['average_resolution_time_hours'] as num?)?.toDouble() ?? 0.0;

    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Text(
                _formatVotingMethod(votingMethod),
                style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimaryLight,
                ),
              ),
              const Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                decoration: BoxDecoration(
                  color: AppTheme.primaryLight.withAlpha(26),
                  borderRadius: BorderRadius.circular(6.0),
                ),
                child: Text(
                  '$totalTies ties',
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryLight,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          // Resolution breakdown
          _buildStatRow('Runoff Resolutions', runoffResolutions, Colors.blue),
          SizedBox(height: 1.h),
          _buildStatRow('Manual Resolutions', manualResolutions, Colors.green),
          SizedBox(height: 1.h),
          _buildStatRow(
            'Lottery Resolutions',
            lotteryResolutions,
            Colors.purple,
          ),
          SizedBox(height: 2.h),
          // Average resolution time
          Row(
            children: [
              Icon(Icons.timer, size: 18.0, color: Colors.orange),
              SizedBox(width: 2.w),
              Text(
                'Avg Resolution Time: ${avgResolutionTime.toStringAsFixed(1)} hours',
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  color: AppTheme.textSecondaryLight,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, int value, Color color) {
    return Row(
      children: [
        Container(
          width: 8.0,
          height: 8.0,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        SizedBox(width: 2.w),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12.sp,
              color: AppTheme.textSecondaryLight,
            ),
          ),
        ),
        Text(
          value.toString(),
          style: GoogleFonts.inter(
            fontSize: 13.sp,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimaryLight,
          ),
        ),
      ],
    );
  }

  String _formatVotingMethod(String method) {
    switch (method) {
      case 'plurality':
        return 'Plurality Voting';
      case 'ranked_choice':
        return 'Ranked Choice Voting';
      case 'approval':
        return 'Approval Voting';
      case 'plus_minus':
        return 'Plus-Minus Voting';
      default:
        return method;
    }
  }
}
