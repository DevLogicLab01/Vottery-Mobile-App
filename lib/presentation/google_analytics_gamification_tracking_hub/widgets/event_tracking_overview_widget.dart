import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

class EventTrackingOverviewWidget extends StatelessWidget {
  final Map<String, dynamic> trackingData;

  const EventTrackingOverviewWidget({super.key, required this.trackingData});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Gamification Event Tracking',
            style: GoogleFonts.inter(
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 2.h),
          _buildEventCard(
            'vp_earned',
            'VP Earned Events',
            trackingData['vp_earned_events'] ?? 0,
            'Tracks VP earning from elections (10 VP), ads (5 VP), Jolts (50 VP), predictions (up to 1000 VP), social (5 VP)',
            Icons.stars,
            Colors.green,
            theme,
          ),
          SizedBox(height: 2.h),
          _buildEventCard(
            'vp_spent',
            'VP Spent Events',
            trackingData['vp_spent_events'] ?? 0,
            'Tracks VP spending in rewards shop with item category, item name, VP amount, user balance',
            Icons.shopping_cart,
            Colors.orange,
            theme,
          ),
          SizedBox(height: 2.h),
          _buildEventCard(
            'badge_unlocked',
            'Badge Unlocked Events',
            trackingData['badge_unlocked_events'] ?? 0,
            'Tracks badge unlocks with badge ID, name, rarity, unlock date, total badges earned',
            Icons.military_tech,
            Colors.purple,
            theme,
          ),
          SizedBox(height: 2.h),
          _buildEventCard(
            'streak_milestone',
            'Streak Milestone Events',
            trackingData['streak_milestone_events'] ?? 0,
            'Tracks streak milestones (voting/feed/ad/jolt) with streak days, multiplier, longest streak',
            Icons.local_fire_department,
            Colors.red,
            theme,
          ),
          SizedBox(height: 2.h),
          _buildEventCard(
            'prediction_accuracy',
            'Prediction Accuracy Events',
            trackingData['prediction_accuracy_events'] ?? 0,
            'Tracks prediction pool results with Brier score, VP reward, leaderboard rank',
            Icons.psychology,
            Colors.blue,
            theme,
          ),
          SizedBox(height: 2.h),
          _buildEventCard(
            'leaderboard_change',
            'Leaderboard Change Events',
            trackingData['leaderboard_change_events'] ?? 0,
            'Tracks leaderboard rank changes (global/regional/friends) with old rank, new rank, rank change',
            Icons.leaderboard,
            Colors.teal,
            theme,
          ),
          SizedBox(height: 2.h),
          _buildEventCard(
            'quest_completed',
            'Quest Completed Events',
            trackingData['quest_completed_events'] ?? 0,
            'Tracks quest completions (daily/weekly) with quest ID, type, VP reward, completion time',
            Icons.flag,
            Colors.indigo,
            theme,
          ),
        ],
      ),
    );
  }

  Widget _buildEventCard(
    String eventName,
    String title,
    int count,
    String description,
    IconData icon,
    Color color,
    ThemeData theme,
  ) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: color, width: 2.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 10.0,
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
                  color: color.withAlpha(51),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 24.sp),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      eventName,
                      style: GoogleFonts.inter(
                        fontSize: 10.sp,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Text(
                  count.toString(),
                  style: GoogleFonts.inter(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Text(
            description,
            style: GoogleFonts.inter(fontSize: 12.sp, color: Colors.grey[700]),
          ),
        ],
      ),
    );
  }
}
