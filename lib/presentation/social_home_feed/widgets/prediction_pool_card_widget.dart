import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

/// Prediction pool card with entry button and prize pool display
class PredictionPoolCardWidget extends StatelessWidget {
  final Map<String, dynamic> pool;
  final Function(String) onEnter;

  const PredictionPoolCardWidget({
    super.key,
    required this.pool,
    required this.onEnter,
  });

  @override
  Widget build(BuildContext context) {
    final title = pool['title'] as String? ?? 'Prediction Pool';
    final question = pool['question'] as String? ?? '';
    final entryFee = pool['entry_fee_vp'] as int? ?? 0;
    final prizePool = pool['prize_pool_vp'] as int? ?? 0;
    final participantCount = pool['participant_count'] as int? ?? 0;
    final closesAt = pool['closes_at'] as String?;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: AppTheme.accentLight.withAlpha(77), width: 2),
        boxShadow: [
          BoxShadow(
            color: AppTheme.shadowLight,
            blurRadius: 8,
            offset: Offset(0, 2),
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
              color: AppTheme.accentLight.withAlpha(26),
              borderRadius: BorderRadius.vertical(top: Radius.circular(12.0)),
            ),
            child: Row(
              children: [
                CustomIconWidget(
                  iconName: 'trending_up',
                  size: 5.w,
                  color: AppTheme.accentLight,
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: Text(
                    'Prediction Pool',
                    style: _textStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.accentLight,
                    ),
                  ),
                ),
                Text(
                  _formatTimeRemaining(closesAt),
                  style: _textStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),

          // Content
          Padding(
            padding: EdgeInsets.all(3.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: _textStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimaryLight,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 1.h),
                Text(
                  question,
                  style: _textStyle(
                    fontSize: 13.sp,
                    color: AppTheme.textSecondaryLight,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 2.h),

                // Stats
                Row(
                  children: [
                    _buildStat(
                      'Prize Pool',
                      '$prizePool VP',
                      AppTheme.accentLight,
                    ),
                    SizedBox(width: 4.w),
                    _buildStat(
                      'Entry Fee',
                      '$entryFee VP',
                      AppTheme.primaryLight,
                    ),
                    SizedBox(width: 4.w),
                    _buildStat(
                      'Participants',
                      '$participantCount',
                      AppTheme.secondaryLight,
                    ),
                  ],
                ),
                SizedBox(height: 2.h),

                // Enter button
                ElevatedButton(
                  onPressed: () => onEnter(pool['id'] as String),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentLight,
                    foregroundColor: Colors.white,
                    minimumSize: Size(double.infinity, 5.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  child: Text(
                    'Enter Prediction',
                    style: _textStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value, Color color) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: _textStyle(
              fontSize: 10.sp,
              color: AppTheme.textSecondaryLight,
            ),
          ),
          Text(
            value,
            style: _textStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  TextStyle _textStyle({
    required double fontSize,
    FontWeight? fontWeight,
    Color? color,
  }) {
    return GoogleFonts.inter(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
    );
  }

  String _formatTimeRemaining(String? closesAt) {
    if (closesAt == null) return '';
    try {
      final closeTime = DateTime.parse(closesAt);
      final now = DateTime.now();
      final difference = closeTime.difference(now);

      if (difference.inDays > 0) {
        return '${difference.inDays}d left';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h left';
      } else {
        return '${difference.inMinutes}m left';
      }
    } catch (e) {
      return '';
    }
  }
}
