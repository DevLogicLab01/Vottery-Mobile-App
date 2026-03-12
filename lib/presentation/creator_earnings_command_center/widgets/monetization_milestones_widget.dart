import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class MonetizationMilestonesWidget extends StatelessWidget {
  final List<Map<String, dynamic>> milestones;
  final Function(Map<String, dynamic>) onMilestoneAchieved;

  const MonetizationMilestonesWidget({
    super.key,
    required this.milestones,
    required this.onMilestoneAchieved,
  });

  @override
  Widget build(BuildContext context) {
    final achievedMilestones = milestones
        .where((m) => m['achieved'] == true)
        .toList();
    final pendingMilestones = milestones
        .where((m) => m['achieved'] != true)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildMilestonesHeader(context, achievedMilestones.length),
        SizedBox(height: 2.h),
        if (pendingMilestones.isNotEmpty) ...[
          _buildSectionTitle('In Progress', Icons.trending_up, Colors.blue),
          SizedBox(height: 1.h),
          ...pendingMilestones.map(
            (milestone) => _buildMilestoneCard(context, milestone, false),
          ),
          SizedBox(height: 2.h),
        ],
        if (achievedMilestones.isNotEmpty) ...[
          _buildSectionTitle('Achieved', Icons.emoji_events, Colors.amber),
          SizedBox(height: 1.h),
          ...achievedMilestones.map(
            (milestone) => _buildMilestoneCard(context, milestone, true),
          ),
        ],
      ],
    );
  }

  Widget _buildMilestonesHeader(BuildContext context, int achievedCount) {
    final totalCount = milestones.length;
    final progress = totalCount > 0 ? achievedCount / totalCount : 0.0;

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.amber.withAlpha(51), Colors.orange.withAlpha(51)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Monetization Milestones',
                style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                decoration: BoxDecoration(
                  color: Colors.amber,
                  borderRadius: BorderRadius.circular(20.0),
                ),
                child: Text(
                  '$achievedCount/$totalCount',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(10.0),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey[300],
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
              minHeight: 10.0,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            '${(progress * 100).toStringAsFixed(0)}% Complete',
            style: TextStyle(
              fontSize: 12.sp,
              color: Colors.grey[700],
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20.sp),
        SizedBox(width: 2.w),
        Text(
          title,
          style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildMilestoneCard(
    BuildContext context,
    Map<String, dynamic> milestone,
    bool achieved,
  ) {
    final target = milestone['target'] ?? 100.0;
    final current = milestone['current'] ?? 0.0;
    final progressPercentage = target > 0
        ? (current / target).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: achieved
            ? Colors.amber.withAlpha(26)
            : Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: achieved ? Colors.amber : Colors.grey[300]!,
          width: achieved ? 2.0 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 4.0,
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
                  color: achieved
                      ? Colors.amber.withAlpha(51)
                      : Colors.blue.withAlpha(26),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  achieved ? Icons.check_circle : Icons.flag,
                  color: achieved ? Colors.amber : Colors.blue,
                  size: 24.sp,
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      milestone['title'] ?? 'Milestone',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 0.5.h),
                    Text(
                      milestone['description'] ?? '',
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              if (achieved)
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 2.w,
                    vertical: 0.5.h,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.amber,
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: Text(
                    'Achieved',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          if (!achieved) ...[
            SizedBox(height: 2.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Progress',
                  style: TextStyle(fontSize: 11.sp, color: Colors.grey[600]),
                ),
                Text(
                  '${current.toStringAsFixed(0)} / ${target.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
            SizedBox(height: 1.h),
            ClipRRect(
              borderRadius: BorderRadius.circular(10.0),
              child: LinearProgressIndicator(
                value: progressPercentage,
                backgroundColor: Colors.grey[200],
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                minHeight: 6.0,
              ),
            ),
          ],
          if (milestone['reward'] != null) ...[
            SizedBox(height: 2.h),
            Container(
              padding: EdgeInsets.all(2.w),
              decoration: BoxDecoration(
                color: achieved ? Colors.green.withAlpha(26) : Colors.grey[100],
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.card_giftcard,
                    color: achieved ? Colors.green : Colors.grey,
                    size: 16.sp,
                  ),
                  SizedBox(width: 2.w),
                  Text(
                    'Reward: ${milestone['reward']}',
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                      color: achieved ? Colors.green : Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (achieved && milestone['achieved_date'] != null) ...[
            SizedBox(height: 1.h),
            Text(
              'Achieved on ${_formatDate(milestone['achieved_date'])}',
              style: TextStyle(
                fontSize: 10.sp,
                color: Colors.grey[500],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(dynamic date) {
    if (date == null) return '';
    try {
      final DateTime dateTime = date is DateTime
          ? date
          : DateTime.parse(date.toString());
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } catch (e) {
      return date.toString();
    }
  }
}
