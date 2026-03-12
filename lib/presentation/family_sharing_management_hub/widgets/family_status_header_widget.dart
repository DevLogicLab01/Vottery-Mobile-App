import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class FamilyStatusHeaderWidget extends StatelessWidget {
  final int activeMembersCount;
  final int totalMembers;
  final Map<String, dynamic>? subscription;

  const FamilyStatusHeaderWidget({
    super.key,
    required this.activeMembersCount,
    required this.totalMembers,
    this.subscription,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: EdgeInsets.all(4.w),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(25),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildMetricCard(
              'Active Members',
              activeMembersCount.toString(),
              Icons.people,
              Colors.green,
            ),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: _buildMetricCard(
              'Total Slots',
              '$totalMembers / 5',
              Icons.family_restroom,
              Colors.blue,
            ),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: _buildMetricCard(
              'Subscription',
              subscription?['tier']?.toString().toUpperCase() ?? 'NONE',
              Icons.workspace_premium,
              Colors.purple,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, size: 8.w, color: color),
        SizedBox(height: 1.h),
        Text(
          value,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimaryLight,
          ),
        ),
        SizedBox(height: 0.5.h),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 10.sp, color: AppTheme.textSecondaryLight),
        ),
      ],
    );
  }
}
