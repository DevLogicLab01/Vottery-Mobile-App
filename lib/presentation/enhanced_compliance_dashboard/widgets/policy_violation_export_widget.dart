import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

class PolicyViolationExportWidget extends StatefulWidget {
  const PolicyViolationExportWidget({super.key});

  @override
  State<PolicyViolationExportWidget> createState() =>
      _PolicyViolationExportWidgetState();
}

class _PolicyViolationExportWidgetState
    extends State<PolicyViolationExportWidget> {
  bool _isLoading = false;
  final List<Map<String, dynamic>> _violations = [
    {
      'id': 'V001',
      'type': 'Data Processing',
      'severity': 'high',
      'description': 'Unauthorized data access attempt detected',
      'date': DateTime.now().subtract(Duration(hours: 2)),
      'status': 'escalated',
    },
    {
      'id': 'V002',
      'type': 'Privacy Policy',
      'severity': 'medium',
      'description': 'Consent withdrawal not processed within 24h',
      'date': DateTime.now().subtract(Duration(days: 1)),
      'status': 'pending',
    },
    {
      'id': 'V003',
      'type': 'Data Retention',
      'severity': 'low',
      'description': 'Data retention period exceeded by 7 days',
      'date': DateTime.now().subtract(Duration(days: 3)),
      'status': 'resolved',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(4.w),
          color: theme.cardColor,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Policy Violations',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
              ElevatedButton.icon(
                onPressed: _exportViolations,
                icon: Icon(Icons.download, size: 16),
                label: Text('Export'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _isLoading
              ? Center(
                  child: CircularProgressIndicator(
                    color: theme.colorScheme.primary,
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.all(4.w),
                  itemCount: _violations.length,
                  itemBuilder: (context, index) {
                    return _buildViolationCard(context, _violations[index]);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildViolationCard(
    BuildContext context,
    Map<String, dynamic> violation,
  ) {
    final theme = Theme.of(context);
    final severity = violation['severity'] as String;
    final severityColor = _getSeverityColor(severity);
    final status = violation['status'] as String;
    final statusColor = _getStatusColor(status);

    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: severityColor.withAlpha(51)),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow,
            blurRadius: 4,
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
                  color: severityColor.withAlpha(26),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: CustomIconWidget(
                  iconName: _getSeverityIcon(severity),
                  color: severityColor,
                  size: 20,
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      violation['id'],
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      violation['type'],
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 2.w,
                      vertical: 0.5.h,
                    ),
                    decoration: BoxDecoration(
                      color: severityColor.withAlpha(26),
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: Text(
                      severity.toUpperCase(),
                      style: TextStyle(
                        fontSize: 9.sp,
                        fontWeight: FontWeight.w600,
                        color: severityColor,
                      ),
                    ),
                  ),
                  SizedBox(height: 0.5.h),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 2.w,
                      vertical: 0.5.h,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withAlpha(26),
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: Text(
                      status.toUpperCase(),
                      style: TextStyle(
                        fontSize: 9.sp,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Text(
            violation['description'],
            style: TextStyle(
              fontSize: 12.sp,
              color: theme.colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 1.h),
          Row(
            children: [
              Icon(
                Icons.access_time,
                size: 14,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              SizedBox(width: 1.w),
              Text(
                _formatDate(violation['date']),
                style: TextStyle(
                  fontSize: 10.sp,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          if (status == 'pending') ...[
            SizedBox(height: 2.h),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _resolveViolation(violation['id']),
                    child: Text('Resolve'),
                  ),
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _escalateViolation(violation['id']),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    child: Text('Escalate'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.yellow.shade700;
      default:
        return Colors.grey;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'resolved':
        return Colors.green;
      case 'escalated':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _getSeverityIcon(String severity) {
    switch (severity.toLowerCase()) {
      case 'high':
        return 'error';
      case 'medium':
        return 'warning';
      case 'low':
        return 'info';
      default:
        return 'help';
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  Future<void> _exportViolations() async {
    setState(() => _isLoading = true);
    await Future.delayed(Duration(seconds: 1));
    setState(() => _isLoading = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Violations exported successfully'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _resolveViolation(String id) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Violation $id marked as resolved'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _escalateViolation(String id) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Violation $id escalated to compliance team'),
        backgroundColor: Colors.red,
      ),
    );
  }
}
