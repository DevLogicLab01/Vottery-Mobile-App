import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../../widgets/custom_icon_widget.dart';

/// Current Challenges Widget
/// Displays daily/weekly quests with real-time progress bars (75% complete indicators)
class CurrentChallengesWidget extends StatelessWidget {
  final List<Map<String, dynamic>> challenges;

  const CurrentChallengesWidget({super.key, required this.challenges});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (challenges.isEmpty) {
      return _buildEmptyState(theme);
    }

    return Column(
      children: challenges.map((challenge) {
        return _buildChallengeCard(challenge, theme);
      }).toList(),
    );
  }

  Widget _buildChallengeCard(Map<String, dynamic> challenge, ThemeData theme) {
    final quest = challenge['quest'] as Map<String, dynamic>?;
    final title = quest?['quest_name'] as String? ?? 'Challenge';
    final description = quest?['quest_description'] as String? ?? '';
    final reward = quest?['vp_reward'] as int? ?? 0;
    final progress = challenge['progress_percentage'] as int? ?? 0;
    final frequency = quest?['quest_frequency'] as String? ?? 'daily';

    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CustomIconWidget(
                iconName: frequency == 'daily' ? 'today' : 'event',
                color: theme.colorScheme.primary,
                size: 24,
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    if (description.isNotEmpty)
                      Text(
                        description,
                        style: GoogleFonts.inter(
                          fontSize: 10.sp,
                          color: theme.colorScheme.onSurface.withAlpha(153),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withAlpha(26),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Text(
                  '+$reward VP',
                  style: GoogleFonts.inter(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: LinearProgressIndicator(
                    value: progress / 100,
                    minHeight: 1.h,
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      progress >= 75 ? Colors.green : theme.colorScheme.primary,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 2.w),
              Text(
                '$progress%',
                style: GoogleFonts.inter(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomIconWidget(
              iconName: 'assignment',
              color: theme.colorScheme.onSurface.withAlpha(77),
              size: 40,
            ),
            SizedBox(height: 1.h),
            Text(
              'No Active Challenges',
              style: GoogleFonts.inter(
                fontSize: 12.sp,
                color: theme.colorScheme.onSurface.withAlpha(153),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
