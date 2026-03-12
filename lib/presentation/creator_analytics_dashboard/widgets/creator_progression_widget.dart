import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class CreatorProgressionWidget extends StatelessWidget {
  final Map<String, dynamic> creatorTier;

  const CreatorProgressionWidget({super.key, required this.creatorTier});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Creator Progression',
          style: GoogleFonts.inter(
            fontSize: 16.sp,
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurface,
          ),
        ),
        SizedBox(height: 2.h),
        _buildCurrentTierCard(theme),
        SizedBox(height: 2.h),
        _buildProgressToNextTierCard(theme),
        SizedBox(height: 2.h),
        _buildMilestonesCard(theme),
        SizedBox(height: 2.h),
        _buildBenefitsCard(theme),
      ],
    );
  }

  Widget _buildCurrentTierCard(ThemeData theme) {
    final tierName = creatorTier['tier_name'] ?? 'Starter';
    final tierLevel = creatorTier['tier_level'] ?? 1;

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
        ),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        children: [
          Icon(Icons.workspace_premium, color: Colors.white, size: 15.w),
          SizedBox(height: 1.h),
          Text(
            tierName,
            style: GoogleFonts.inter(
              fontSize: 18.sp,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          Text(
            'Level $tierLevel Creator',
            style: GoogleFonts.inter(fontSize: 12.sp, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressToNextTierCard(ThemeData theme) {
    final currentPoints = creatorTier['current_points'] ?? 0;
    final requiredPoints = creatorTier['required_points'] ?? 1000;
    final progress = currentPoints / requiredPoints;

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Progress to Next Tier',
                style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              Text(
                '${(progress * 100).toStringAsFixed(0)}%',
                style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.vibrantYellow,
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(8.0),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.vibrantYellow),
              minHeight: 2.h,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            '$currentPoints / $requiredPoints points',
            style: GoogleFonts.inter(
              fontSize: 11.sp,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            'Requirements for Next Level',
            style: GoogleFonts.inter(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 1.h),
          _buildRequirementItem(
            theme,
            'Total Earnings',
            '\$5,000',
            Icons.attach_money,
            true,
          ),
          _buildRequirementItem(
            theme,
            'Followers',
            '10,000',
            Icons.people,
            false,
          ),
          _buildRequirementItem(
            theme,
            'Content Published',
            '50 pieces',
            Icons.article,
            true,
          ),
        ],
      ),
    );
  }

  Widget _buildRequirementItem(
    ThemeData theme,
    String label,
    String target,
    IconData icon,
    bool completed,
  ) {
    return Padding(
      padding: EdgeInsets.only(bottom: 1.h),
      child: Row(
        children: [
          Icon(
            completed ? Icons.check_circle : Icons.radio_button_unchecked,
            color: completed
                ? Colors.green
                : theme.colorScheme.onSurfaceVariant,
            size: 5.w,
          ),
          SizedBox(width: 2.w),
          Icon(icon, color: theme.colorScheme.onSurfaceVariant, size: 4.w),
          SizedBox(width: 2.w),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11.sp,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
          Text(
            target,
            style: GoogleFonts.inter(
              fontSize: 11.sp,
              fontWeight: FontWeight.w600,
              color: completed
                  ? Colors.green
                  : theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMilestonesCard(ThemeData theme) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Milestone Achievements',
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 2.h),
          _buildMilestoneItem(
            theme,
            'First 1K Followers',
            'Completed 2 months ago',
            Icons.emoji_events,
            Colors.amber,
            true,
          ),
          SizedBox(height: 1.h),
          _buildMilestoneItem(
            theme,
            'First \$1K Earned',
            'Completed 1 month ago',
            Icons.monetization_on,
            Colors.green,
            true,
          ),
          SizedBox(height: 1.h),
          _buildMilestoneItem(
            theme,
            '100 Content Pieces',
            'In progress (78/100)',
            Icons.article,
            Colors.blue,
            false,
          ),
        ],
      ),
    );
  }

  Widget _buildMilestoneItem(
    ThemeData theme,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    bool completed,
  ) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(2.w),
          decoration: BoxDecoration(
            color: color.withAlpha(51),
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Icon(icon, color: color, size: 6.w),
        ),
        SizedBox(width: 3.w),
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
              Text(
                subtitle,
                style: GoogleFonts.inter(
                  fontSize: 10.sp,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        if (completed) Icon(Icons.check_circle, color: Colors.green, size: 6.w),
      ],
    );
  }

  Widget _buildBenefitsCard(ThemeData theme) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Unlocked Benefits',
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 2.h),
          _buildBenefitItem(
            theme,
            'Priority Support',
            'Get faster response times',
            Icons.support_agent,
            true,
          ),
          _buildBenefitItem(
            theme,
            'Advanced Analytics',
            'Access detailed insights',
            Icons.analytics,
            true,
          ),
          _buildBenefitItem(
            theme,
            'Brand Partnerships',
            'Connect with premium brands',
            Icons.handshake,
            false,
          ),
          _buildBenefitItem(
            theme,
            'Custom Badge',
            'Display verified creator badge',
            Icons.verified,
            false,
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitItem(
    ThemeData theme,
    String title,
    String description,
    IconData icon,
    bool unlocked,
  ) {
    return Padding(
      padding: EdgeInsets.only(bottom: 1.5.h),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(2.w),
            decoration: BoxDecoration(
              color: unlocked
                  ? AppTheme.vibrantYellow.withAlpha(51)
                  : theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Icon(
              icon,
              color: unlocked
                  ? AppTheme.vibrantYellow
                  : theme.colorScheme.onSurfaceVariant,
              size: 5.w,
            ),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: unlocked
                        ? theme.colorScheme.onSurface
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  description,
                  style: GoogleFonts.inter(
                    fontSize: 10.sp,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (unlocked)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
              decoration: BoxDecoration(
                color: Colors.green.withAlpha(51),
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Text(
                'Unlocked',
                style: GoogleFonts.inter(
                  fontSize: 9.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.green,
                ),
              ),
            )
          else
            Icon(
              Icons.lock,
              color: theme.colorScheme.onSurfaceVariant,
              size: 5.w,
            ),
        ],
      ),
    );
  }
}
