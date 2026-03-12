import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class TeamAnalyticsWidget extends StatelessWidget {
  final Map<String, dynamic> roleAnalytics;

  const TeamAnalyticsWidget({super.key, required this.roleAnalytics});

  @override
  Widget build(BuildContext context) {
    final analytics = roleAnalytics['analytics'] as List? ?? [];
    final totalMembers = roleAnalytics['total_team_members'] ?? 0;

    return SingleChildScrollView(
      padding: EdgeInsets.all(3.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTotalMembersCard(totalMembers),
          SizedBox(height: 3.h),
          _buildRoleDistributionChart(analytics),
          SizedBox(height: 3.h),
          _buildRoleActivityList(analytics),
        ],
      ),
    );
  }

  Widget _buildTotalMembersCard(int totalMembers) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade400, Colors.blue.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Row(
        children: [
          Icon(Icons.people, color: Colors.white, size: 32.sp),
          SizedBox(width: 3.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Total Team Members',
                style: TextStyle(fontSize: 12.sp, color: Colors.white70),
              ),
              Text(
                totalMembers.toString(),
                style: TextStyle(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRoleDistributionChart(List analytics) {
    if (analytics.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(26),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Role Distribution',
            style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 2.h),
          SizedBox(
            height: 25.h,
            child: PieChart(
              PieChartData(
                sections: analytics.map((item) {
                  final role = item['role'] ?? '';
                  final activeMembers = item['active_members'] ?? 0;
                  return PieChartSectionData(
                    value: activeMembers.toDouble(),
                    title: role,
                    color: _getRoleColor(role),
                    radius: 50,
                    titleStyle: TextStyle(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  );
                }).toList(),
                sectionsSpace: 2,
                centerSpaceRadius: 40,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleActivityList(List analytics) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Role Activity',
          style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
        ),
        SizedBox(height: 1.h),
        ...analytics.map((item) {
          final role = item['role'] ?? '';
          final activeMembers = item['active_members'] ?? 0;
          final totalActions = item['total_actions'] ?? 0;

          return Card(
            margin: EdgeInsets.only(bottom: 1.h),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: _getRoleColor(role).withAlpha(51),
                child: Icon(_getRoleIcon(role), color: _getRoleColor(role)),
              ),
              title: Text(
                role.toUpperCase(),
                style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                '$activeMembers members • $totalActions actions',
                style: TextStyle(fontSize: 11.sp, color: Colors.grey[600]),
              ),
            ),
          );
        }),
      ],
    );
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'manager':
        return Colors.purple;
      case 'admin':
        return Colors.red;
      case 'moderator':
        return Colors.blue;
      case 'auditor':
        return Colors.green;
      case 'editor':
        return Colors.orange;
      case 'advertiser':
        return Colors.amber;
      case 'analyst':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  IconData _getRoleIcon(String role) {
    switch (role.toLowerCase()) {
      case 'manager':
        return Icons.manage_accounts;
      case 'admin':
        return Icons.admin_panel_settings;
      case 'moderator':
        return Icons.shield;
      case 'auditor':
        return Icons.fact_check;
      case 'editor':
        return Icons.edit;
      case 'advertiser':
        return Icons.campaign;
      case 'analyst':
        return Icons.analytics;
      default:
        return Icons.person;
    }
  }
}
