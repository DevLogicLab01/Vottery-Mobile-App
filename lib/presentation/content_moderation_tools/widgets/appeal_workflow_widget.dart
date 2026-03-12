import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

class AppealWorkflowWidget extends StatefulWidget {
  final VoidCallback onAppealResolved;

  const AppealWorkflowWidget({super.key, required this.onAppealResolved});

  @override
  State<AppealWorkflowWidget> createState() => _AppealWorkflowWidgetState();
}

class _AppealWorkflowWidgetState extends State<AppealWorkflowWidget> {
  final List<Map<String, dynamic>> _mockAppeals = [
    {
      'id': '1',
      'content': 'Community discussion about local election policies',
      'original_decision': 'Removed',
      'appeal_reason':
          'Content was educational and within community guidelines',
      'submitted_at': DateTime.now().subtract(const Duration(hours: 2)),
      'status': 'pending',
    },
    {
      'id': '2',
      'content': 'Analysis of voting system improvements',
      'original_decision': 'Flagged',
      'appeal_reason': 'Factual analysis with cited sources',
      'submitted_at': DateTime.now().subtract(const Duration(hours: 5)),
      'status': 'under_review',
    },
  ];

  @override
  Widget build(BuildContext context) {
    if (_mockAppeals.isEmpty) {
      return _buildEmptyState(context);
    }

    return ListView.builder(
      padding: EdgeInsets.all(4.w),
      itemCount: _mockAppeals.length,
      itemBuilder: (context, index) {
        return _buildAppealCard(context, _mockAppeals[index]);
      },
    );
  }

  Widget _buildAppealCard(BuildContext context, Map<String, dynamic> appeal) {
    final theme = Theme.of(context);

    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                decoration: BoxDecoration(
                  color: _getStatusColor(
                    appeal['status'],
                  ).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  appeal['status'].toString().toUpperCase(),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: _getStatusColor(appeal['status']),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                '${(DateTime.now().difference(appeal['submitted_at'] as DateTime).inHours)}h ago',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.disabledColor,
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Text(
            'Original Content',
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 0.5.h),
          Text(
            appeal['content'],
            style: theme.textTheme.bodyMedium,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 1.h),
          Container(
            padding: EdgeInsets.all(2.w),
            decoration: BoxDecoration(
              color: const Color(0xFFEF4444).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                CustomIconWidget(
                  iconName: 'block',
                  color: const Color(0xFFEF4444),
                  size: 16,
                ),
                SizedBox(width: 2.w),
                Text(
                  'Original Decision: ${appeal['original_decision']}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: const Color(0xFFEF4444),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            'Appeal Reason',
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 0.5.h),
          Text(appeal['appeal_reason'], style: theme.textTheme.bodyMedium),
          SizedBox(height: 2.h),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _handleApproveAppeal(appeal['id']),
                  icon: CustomIconWidget(
                    iconName: 'check_circle',
                    color: Colors.white,
                    size: 18,
                  ),
                  label: const Text('Approve Appeal'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _handleRejectAppeal(appeal['id']),
                  icon: CustomIconWidget(
                    iconName: 'cancel',
                    color: const Color(0xFFEF4444),
                    size: 18,
                  ),
                  label: Text(
                    'Reject',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: const Color(0xFFEF4444),
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFEF4444)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CustomIconWidget(
            iconName: 'gavel',
            color: theme.disabledColor,
            size: 64,
          ),
          SizedBox(height: 2.h),
          Text(
            'No pending appeals',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.disabledColor,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return const Color(0xFFF59E0B);
      case 'under_review':
        return const Color(0xFF3B82F6);
      case 'approved':
        return const Color(0xFF10B981);
      case 'rejected':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF6B7280);
    }
  }

  void _handleApproveAppeal(String appealId) {
    setState(() {
      _mockAppeals.removeWhere((appeal) => appeal['id'] == appealId);
    });
    widget.onAppealResolved();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Appeal approved - content restored')),
    );
  }

  void _handleRejectAppeal(String appealId) {
    setState(() {
      _mockAppeals.removeWhere((appeal) => appeal['id'] == appealId);
    });
    widget.onAppealResolved();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Appeal rejected - original decision upheld'),
      ),
    );
  }
}
