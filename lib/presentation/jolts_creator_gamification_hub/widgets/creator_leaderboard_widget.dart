import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class CreatorLeaderboardWidget extends StatelessWidget {
  final List<Map<String, dynamic>> leaderboard;
  final String currentUserId;

  const CreatorLeaderboardWidget({
    super.key,
    required this.leaderboard,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    if (leaderboard.isEmpty) {
      return Center(
        child: Text(
          'No leaderboard data available',
          style: TextStyle(fontSize: 12.sp, color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(4.w),
      itemCount: leaderboard.length,
      itemBuilder: (context, index) {
        final creator = leaderboard[index];
        final isCurrentUser = creator['user_id'] == currentUserId;
        final rank = index + 1;

        return Card(
          color: isCurrentUser ? Colors.blue.shade50 : null,
          margin: EdgeInsets.only(bottom: 2.h),
          child: ListTile(
            leading: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '#$rank',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: rank <= 3 ? Colors.amber : Colors.grey,
                  ),
                ),
                SizedBox(width: 2.w),
                CircleAvatar(
                  radius: 6.w,
                  backgroundColor: Colors.grey.shade300,
                  child: Icon(Icons.person, size: 6.w),
                ),
              ],
            ),
            title: Text(
              creator['user']?['full_name'] ?? 'Creator ${creator['user_id']}',
              style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              '${creator['total_views'] ?? 0} views • ${creator['total_likes'] ?? 0} likes',
              style: TextStyle(fontSize: 10.sp),
            ),
            trailing: _buildTierBadge(creator['total_jolts'] ?? 0),
          ),
        );
      },
    );
  }

  Widget _buildTierBadge(int totalJolts) {
    String tier = 'Bronze';
    Color color = Colors.brown;

    if (totalJolts >= 100) {
      tier = 'Platinum';
      color = Colors.cyan;
    } else if (totalJolts >= 50) {
      tier = 'Gold';
      color = Colors.amber;
    } else if (totalJolts >= 10) {
      tier = 'Silver';
      color = Colors.grey;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Text(
        tier,
        style: TextStyle(
          fontSize: 10.sp,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}
