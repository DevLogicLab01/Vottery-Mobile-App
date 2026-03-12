import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

/// Group Discovery Algorithm Widget - AI-powered group recommendations
class GroupDiscoveryAlgorithmWidget extends StatelessWidget {
  final List<Map<String, dynamic>> discoveredGroups;
  final List<Map<String, dynamic>> recommendedGroups;
  final Function(String) onJoinGroup;

  const GroupDiscoveryAlgorithmWidget({
    super.key,
    required this.discoveredGroups,
    required this.recommendedGroups,
    required this.onJoinGroup,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Recommended Section
          if (recommendedGroups.isNotEmpty) ...[
            Padding(
              padding: EdgeInsets.all(4.w),
              child: Row(
                children: [
                  Icon(
                    Icons.auto_awesome,
                    color: AppTheme.vibrantYellow,
                    size: 6.w,
                  ),
                  SizedBox(width: 2.w),
                  Text(
                    'Recommended For You',
                    style: GoogleFonts.inter(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimaryLight,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 35.h,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: 4.w),
                itemCount: recommendedGroups.length,
                separatorBuilder: (context, index) => SizedBox(width: 4.w),
                itemBuilder: (context, index) {
                  final group = recommendedGroups[index];
                  return _buildRecommendedCard(context, group);
                },
              ),
            ),
            SizedBox(height: 3.h),
          ],

          // Discovered Groups Section
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            child: Text(
              'Discover Groups',
              style: GoogleFonts.inter(
                fontSize: 16.sp,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimaryLight,
              ),
            ),
          ),
          SizedBox(height: 2.h),
          ListView.separated(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            itemCount: discoveredGroups.length,
            separatorBuilder: (context, index) => SizedBox(height: 2.h),
            itemBuilder: (context, index) {
              final group = discoveredGroups[index];
              return _buildDiscoveredCard(context, group);
            },
          ),
          SizedBox(height: 4.h),
        ],
      ),
    );
  }

  Widget _buildRecommendedCard(
    BuildContext context,
    Map<String, dynamic> group,
  ) {
    return Container(
      width: 70.w,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: AppTheme.vibrantYellow, width: 2),
        boxShadow: [
          BoxShadow(
            color: AppTheme.vibrantYellow.withAlpha(51),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.vertical(top: Radius.circular(12.0)),
            child: CustomImageWidget(
              imageUrl: group['cover_image_url'],
              height: 15.h,
              width: double.infinity,
              fit: BoxFit.cover,
              semanticLabel: 'Recommended group cover for ${group['name']}',
            ),
          ),
          Padding(
            padding: EdgeInsets.all(3.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 2.w,
                        vertical: 0.5.h,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.accentLight,
                        borderRadius: BorderRadius.circular(4.0),
                      ),
                      child: Text(
                        '${group['match_score']}% Match',
                        style: GoogleFonts.inter(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 1.h),
                Text(
                  group['name'],
                  style: GoogleFonts.inter(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimaryLight,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 0.5.h),
                Text(
                  group['reason'],
                  style: GoogleFonts.inter(
                    fontSize: 11.sp,
                    color: AppTheme.textSecondaryLight,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 1.h),
                Row(
                  children: [
                    Icon(
                      Icons.people_outline,
                      size: 3.w,
                      color: AppTheme.textSecondaryLight,
                    ),
                    SizedBox(width: 1.w),
                    Text(
                      '${group['member_count']} members',
                      style: GoogleFonts.inter(
                        fontSize: 10.sp,
                        color: AppTheme.textSecondaryLight,
                      ),
                    ),
                    if (group['mutual_members'] > 0) ...[
                      SizedBox(width: 2.w),
                      Icon(Icons.group, size: 3.w, color: AppTheme.accentLight),
                      SizedBox(width: 1.w),
                      Text(
                        '${group['mutual_members']} mutual',
                        style: GoogleFonts.inter(
                          fontSize: 10.sp,
                          color: AppTheme.accentLight,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
                SizedBox(height: 1.5.h),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => onJoinGroup(group['id']),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryLight,
                      padding: EdgeInsets.symmetric(vertical: 1.2.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    child: Text(
                      'Join Group',
                      style: GoogleFonts.inter(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
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

  Widget _buildDiscoveredCard(
    BuildContext context,
    Map<String, dynamic> group,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
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
          ClipRRect(
            borderRadius: BorderRadius.vertical(top: Radius.circular(12.0)),
            child: CustomImageWidget(
              imageUrl: group['cover_image_url'],
              height: 18.h,
              width: double.infinity,
              fit: BoxFit.cover,
              semanticLabel: 'Group cover for ${group['name']}',
            ),
          ),
          Padding(
            padding: EdgeInsets.all(4.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        group['name'],
                        style: GoogleFonts.inter(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimaryLight,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 2.w,
                        vertical: 0.5.h,
                      ),
                      decoration: BoxDecoration(
                        color: _getActivityColor(
                          group['activity_level'],
                        ).withAlpha(51),
                        borderRadius: BorderRadius.circular(4.0),
                      ),
                      child: Text(
                        group['activity_level'].toString().toUpperCase(),
                        style: GoogleFonts.inter(
                          fontSize: 9.sp,
                          fontWeight: FontWeight.w700,
                          color: _getActivityColor(group['activity_level']),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 1.h),
                Text(
                  group['description'],
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    color: AppTheme.textSecondaryLight,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 1.5.h),
                Wrap(
                  spacing: 2.w,
                  runSpacing: 1.h,
                  children: [
                    _buildMetricChip(
                      Icons.people_outline,
                      '${group['member_count']} members',
                    ),
                    _buildMetricChip(
                      Icons.trending_up,
                      '${(group['engagement_rate'] * 100).toInt()}% engaged',
                    ),
                    _buildMetricChip(Icons.schedule, group['post_frequency']),
                  ],
                ),
                SizedBox(height: 1.5.h),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Join Probability',
                            style: GoogleFonts.inter(
                              fontSize: 10.sp,
                              color: AppTheme.textSecondaryLight,
                            ),
                          ),
                          SizedBox(height: 0.5.h),
                          LinearProgressIndicator(
                            value: group['join_probability'],
                            backgroundColor: AppTheme.borderLight,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppTheme.accentLight,
                            ),
                            minHeight: 0.8.h,
                            borderRadius: BorderRadius.circular(4.0),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 4.w),
                    ElevatedButton(
                      onPressed: () => onJoinGroup(group['id']),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryLight,
                        padding: EdgeInsets.symmetric(
                          horizontal: 6.w,
                          vertical: 1.h,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                      child: Text(
                        'Join',
                        style: GoogleFonts.inter(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricChip(IconData icon, String label) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(6.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 3.w, color: AppTheme.textSecondaryLight),
          SizedBox(width: 1.w),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10.sp,
              color: AppTheme.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }

  Color _getActivityColor(String level) {
    switch (level) {
      case 'high':
        return AppTheme.accentLight;
      case 'medium':
        return AppTheme.warningLight;
      default:
        return AppTheme.textSecondaryLight;
    }
  }
}
