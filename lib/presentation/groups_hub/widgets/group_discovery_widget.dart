import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';
import './group_card_widget.dart';

/// Group Discovery Widget - Trending and recommended groups
class GroupDiscoveryWidget extends StatelessWidget {
  final List<Map<String, dynamic>> groups;
  final Function(String) onJoinGroup;
  final Function(Map<String, dynamic>) onGroupTap;
  final bool isTrending;

  const GroupDiscoveryWidget({
    super.key,
    required this.groups,
    required this.onJoinGroup,
    required this.onGroupTap,
    this.isTrending = false,
  });

  @override
  Widget build(BuildContext context) {
    if (groups.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isTrending ? Icons.trending_up : Icons.explore_outlined,
              size: 20.w,
              color: AppTheme.textSecondaryLight,
            ),
            SizedBox(height: 2.h),
            Text(
              isTrending ? 'No trending groups' : 'No groups to discover',
              style: GoogleFonts.inter(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimaryLight,
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              'Check back later for new groups',
              style: GoogleFonts.inter(
                fontSize: 13.sp,
                color: AppTheme.textSecondaryLight,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: EdgeInsets.all(4.w),
      itemCount: groups.length,
      separatorBuilder: (context, index) => SizedBox(height: 2.h),
      itemBuilder: (context, index) {
        final group = groups[index];
        return GroupCardWidget(
          group: group,
          isMember: false,
          onTap: () => onGroupTap(group),
          onJoin: () => onJoinGroup(group['id'] as String),
        );
      },
    );
  }
}
