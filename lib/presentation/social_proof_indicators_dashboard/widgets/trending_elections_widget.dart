import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';
import './friend_avatar_stack_widget.dart';

class TrendingElectionsWidget extends StatelessWidget {
  final List<Map<String, dynamic>> elections;

  const TrendingElectionsWidget({super.key, required this.elections});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(4.w),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.trending_up, size: 5.w, color: AppTheme.primaryLight),
              SizedBox(width: 2.w),
              Text(
                'Trending Among Friends',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimaryLight,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          SizedBox(
            height: 20.h,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: elections.length,
              itemBuilder: (context, index) {
                final election = elections[index];
                return _buildTrendingCard(election, index + 1);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendingCard(Map<String, dynamic> election, int rank) {
    final friendsWhoVoted =
        election['friends_who_voted'] as List<Map<String, dynamic>>;

    return Container(
      width: 70.w,
      margin: EdgeInsets.only(right: 3.w),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryLight, AppTheme.secondaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(1.5.w),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(51),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '#$rank',
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              const Spacer(),
              Icon(Icons.local_fire_department, size: 5.w, color: Colors.white),
            ],
          ),
          SizedBox(height: 2.h),
          Text(
            election['title'] as String? ?? 'Election',
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const Spacer(),
          Row(
            children: [
              FriendAvatarStackWidget(friends: friendsWhoVoted, maxVisible: 3),
              SizedBox(width: 2.w),
              Text(
                '${friendsWhoVoted.length} friends',
                style: TextStyle(
                  fontSize: 10.sp,
                  color: Colors.white.withAlpha(204),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
