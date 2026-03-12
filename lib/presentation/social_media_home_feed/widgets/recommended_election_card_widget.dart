import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../../theme/app_theme.dart'
    as app_theme; // Add alias to resolve ambiguous import

/// Enhanced Recommended Election Card Widget
/// Match score, prize pool, participant count, time remaining, why recommended
class RecommendedElectionCardWidget extends StatelessWidget {
  final Map<String, dynamic> election;
  final VoidCallback? onSwipeRight;
  final VoidCallback? onSwipeLeft;

  const RecommendedElectionCardWidget({
    super.key,
    required this.election,
    this.onSwipeRight,
    this.onSwipeLeft,
  });

  @override
  Widget build(BuildContext context) {
    final title = election['title'] as String? ?? 'Election';
    final category = election['category'] as String? ?? 'General';
    final matchScore = (election['match_score'] as num? ?? 87).toInt();
    final prizePool = (election['prize_pool'] as num? ?? 0).toDouble();
    final participantCount = election['participant_count'] as int? ?? 0;
    final endsAt = election['ends_at'] != null
        ? DateTime.tryParse(election['ends_at'] as String)
        : null;
    final hoursLeft = endsAt != null
        ? endsAt.difference(DateTime.now()).inHours
        : 24;
    final whyRecommended =
        election['why_recommended'] as String? ?? 'Based on your interests';

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20.0),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: category + match score
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 2.5.w,
                    vertical: 0.5.h,
                  ),
                  decoration: BoxDecoration(
                    color: app_theme.AppThemeColors.electricGold.withAlpha(30),
                    borderRadius: BorderRadius.circular(20.0),
                    border: Border.all(
                      color: app_theme.AppThemeColors.electricGold.withAlpha(
                        80,
                      ),
                    ),
                  ),
                  child: Text(
                    category,
                    style: GoogleFonts.inter(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w700,
                      color: app_theme.AppThemeColors.electricGold,
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 2.5.w,
                    vertical: 0.5.h,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF2ED573),
                        const Color(0xFF00D2FF),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                  child: Text(
                    '$matchScore% match',
                    style: GoogleFonts.inter(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 1.5.h),
            // Title
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 14.sp,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF1A1A2E),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 1.h),
            // Prize pool highlight
            if (prizePool > 0)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      app_theme.AppThemeColors.electricGold.withAlpha(40),
                      app_theme.AppThemeColors.electricGold.withAlpha(20),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12.0),
                  border: Border.all(
                    color: app_theme.AppThemeColors.electricGold.withAlpha(100),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('🏆', style: TextStyle(fontSize: 12.sp)),
                    SizedBox(width: 1.w),
                    Text(
                      'Prize Pool: \$${_formatAmount(prizePool)}',
                      style: GoogleFonts.inter(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w800,
                        color: app_theme.AppThemeColors.electricGold,
                      ),
                    ),
                  ],
                ),
              ),
            SizedBox(height: 1.h),
            // Stats
            Row(
              children: [
                _buildStat(
                  Icons.people_rounded,
                  '${_formatCount(participantCount)} voters',
                ),
                SizedBox(width: 3.w),
                _buildStat(
                  Icons.timer_rounded,
                  hoursLeft > 24
                      ? '${(hoursLeft / 24).floor()}d left'
                      : '${hoursLeft}h left',
                  color: hoursLeft < 6 ? const Color(0xFFFF4757) : null,
                ),
              ],
            ),
            SizedBox(height: 0.8.h),
            // Why recommended
            Row(
              children: [
                Icon(
                  Icons.lightbulb_rounded,
                  color: const Color(0xFF7B2FF7),
                  size: 3.5.w,
                ),
                SizedBox(width: 1.w),
                Expanded(
                  child: Text(
                    whyRecommended,
                    style: GoogleFonts.inter(
                      fontSize: 9.sp,
                      color: const Color(0xFF7B2FF7),
                      fontStyle: FontStyle.italic,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const Spacer(),
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: onSwipeLeft,
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 1.2.h),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: Center(
                        child: Text(
                          'Not Now',
                          style: GoogleFonts.inter(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 2.w),
                Expanded(
                  flex: 2,
                  child: GestureDetector(
                    onTap: onSwipeRight,
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 1.2.h),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF7B2FF7),
                            const Color(0xFF4776E6),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12.0),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF7B2FF7).withAlpha(80),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          '🗳️ Vote Now',
                          style: GoogleFonts.inter(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(IconData icon, String label, {Color? color}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color ?? Colors.grey[500], size: 3.5.w),
        SizedBox(width: 0.8.w),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 9.sp,
            fontWeight: FontWeight.w600,
            color: color ?? Colors.grey[600],
          ),
        ),
      ],
    );
  }

  String _formatAmount(double amount) {
    if (amount >= 1000000) return '${(amount / 1000000).toStringAsFixed(1)}M';
    if (amount >= 1000) return '${(amount / 1000).toStringAsFixed(1)}K';
    return amount.toStringAsFixed(0);
  }

  String _formatCount(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return count.toString();
  }
}
