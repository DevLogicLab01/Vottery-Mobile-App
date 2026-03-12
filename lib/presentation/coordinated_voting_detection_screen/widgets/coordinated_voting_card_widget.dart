import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../../theme/app_theme.dart';

class CoordinatedVotingCardWidget extends StatelessWidget {
  final Map<String, dynamic> vote;

  const CoordinatedVotingCardWidget({super.key, required this.vote});

  @override
  Widget build(BuildContext context) {
    final userId = vote['user_id'] as String? ?? 'Unknown';
    final votedAt = vote['voted_at'] as String?;
    final optionId = vote['selected_option_id'] as String? ?? 'N/A';

    return Container(
      margin: EdgeInsets.only(bottom: 1.h),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.person, color: Colors.red.shade700, size: 6.w),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'User: ${userId.substring(0, 8)}...',
                  style: GoogleFonts.inter(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimaryLight,
                  ),
                ),
                Text(
                  'Voted: ${votedAt?.split('T')[1].substring(0, 8) ?? 'N/A'}',
                  style: GoogleFonts.inter(
                    fontSize: 10.sp,
                    color: AppTheme.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
