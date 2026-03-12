import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class InterventionWorkflowsWidget extends StatelessWidget {
  final List<Map<String, dynamic>> activeInterventions;
  final Function(String) onViewDetails;

  const InterventionWorkflowsWidget({
    super.key,
    required this.activeInterventions,
    required this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.account_tree, color: Colors.purple.shade700, size: 20),
                SizedBox(width: 2.w),
                Text(
                  'Intervention Workflows',
                  style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Text(
                  '${activeInterventions.length} active',
                  style: TextStyle(color: Colors.purple.shade700, fontSize: 10.sp),
                ),
              ],
            ),
            SizedBox(height: 1.5.h),
            _buildChannelRow(
              icon: Icons.sms,
              label: 'SMS via UnifiedSMSService',
              description: 'Personalized re-engagement messages',
              color: Colors.green,
              count: activeInterventions
                  .where((i) => i['type'] == 'sms')
                  .length,
            ),
            const Divider(height: 16),
            _buildChannelRow(
              icon: Icons.email,
              label: 'HTML Email via ResendEmailService',
              description: 'Earnings snapshots & tier benefits',
              color: Colors.blue,
              count: activeInterventions
                  .where((i) => i['type'] == 'email')
                  .length,
            ),
            const Divider(height: 16),
            _buildChannelRow(
              icon: Icons.notifications_active,
              label: 'Push Notifications',
              description: 'Deep-link to CreatorAnalyticsDashboard',
              color: Colors.orange,
              count: activeInterventions
                  .where((i) => i['type'] == 'push')
                  .length,
            ),
            if (activeInterventions.isNotEmpty) ...[
              SizedBox(height: 1.5.h),
              const Divider(),
              SizedBox(height: 1.h),
              Text(
                'Recent Campaigns',
                style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 1.h),
              ...activeInterventions.take(3).map(
                (intervention) => _buildInterventionCard(intervention),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildChannelRow({
    required IconData icon,
    required String label,
    required String description,
    required Color color,
    required int count,
  }) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(1.5.w),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        SizedBox(width: 2.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 10.sp, fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                description,
                style: TextStyle(fontSize: 9.sp, color: Colors.grey),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.3.h),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Text(
            '$count sent',
            style: TextStyle(color: color, fontSize: 9.sp, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildInterventionCard(Map<String, dynamic> intervention) {
    final type = intervention['type'] ?? 'sms';
    final creatorName = intervention['creator_name'] ?? 'Unknown';
    final status = intervention['status'] ?? 'sent';
    final sentAt = intervention['sent_at'] ?? '';

    final typeColor = type == 'sms'
        ? Colors.green
        : type == 'email'
            ? Colors.blue
            : Colors.orange;
    final typeIcon = type == 'sms'
        ? Icons.sms
        : type == 'email'
            ? Icons.email
            : Icons.notifications;

    return Padding(
      padding: EdgeInsets.only(bottom: 1.h),
      child: Row(
        children: [
          Icon(typeIcon, color: typeColor, size: 16),
          SizedBox(width: 2.w),
          Expanded(
            child: Text(
              creatorName,
              style: TextStyle(fontSize: 10.sp),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 1.5.w, vertical: 0.2.h),
            decoration: BoxDecoration(
              color: status == 'responded'
                  ? Colors.green.shade50
                  : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(6.0),
            ),
            child: Text(
              status.toUpperCase(),
              style: TextStyle(
                color: status == 'responded' ? Colors.green : Colors.grey,
                fontSize: 8.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
