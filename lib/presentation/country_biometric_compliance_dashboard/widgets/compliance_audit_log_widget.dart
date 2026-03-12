import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../widgets/custom_icon_widget.dart';
import '../../../theme/app_theme.dart';

class ComplianceAuditLogWidget extends StatelessWidget {
  final List<Map<String, dynamic>> auditLog;

  const ComplianceAuditLogWidget({super.key, required this.auditLog});

  @override
  Widget build(BuildContext context) {
    if (auditLog.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomIconWidget(
              iconName: 'history',
              size: 15.w,
              color: Colors.grey.shade400,
            ),
            SizedBox(height: 2.h),
            Text(
              'No audit logs found',
              style: TextStyle(fontSize: 14.sp, color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(4.w),
      itemCount: auditLog.length,
      itemBuilder: (context, index) {
        return _buildAuditLogItem(auditLog[index]);
      },
    );
  }

  Widget _buildAuditLogItem(Map<String, dynamic> log) {
    final countryCode = log['country_code'] as String;
    final action = log['action'] as String;
    final newValue = log['new_value'] as bool;
    final createdAt = DateTime.parse(log['created_at'] as String);
    final justification = log['justification'] as String?;
    final adminData = log['user_profiles'] as Map<String, dynamic>?;
    final adminName = adminData?['username'] as String? ?? 'System';

    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(2.w),
                decoration: BoxDecoration(
                  color: _getActionColor(action).withAlpha(26),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Icon(
                  _getActionIcon(action),
                  size: 5.w,
                  color: _getActionColor(action),
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$countryCode - ${_getActionLabel(action)}',
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'by $adminName',
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                timeago.format(createdAt),
                style: TextStyle(fontSize: 10.sp, color: Colors.grey.shade500),
              ),
            ],
          ),
          if (justification != null) ...[
            SizedBox(height: 2.h),
            Container(
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: AppTheme.backgroundLight,
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.notes, size: 4.w, color: Colors.grey.shade600),
                  SizedBox(width: 2.w),
                  Expanded(
                    child: Text(
                      justification,
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  IconData _getActionIcon(String action) {
    switch (action) {
      case 'enabled':
      case 'override_enabled':
        return Icons.check_circle;
      case 'disabled':
      case 'override_disabled':
        return Icons.block;
      default:
        return Icons.info;
    }
  }

  Color _getActionColor(String action) {
    switch (action) {
      case 'enabled':
      case 'override_enabled':
        return Colors.green;
      case 'disabled':
      case 'override_disabled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getActionLabel(String action) {
    switch (action) {
      case 'enabled':
        return 'Biometric Enabled';
      case 'disabled':
        return 'Biometric Disabled';
      case 'override_enabled':
        return 'GDPR Override - Enabled';
      case 'override_disabled':
        return 'GDPR Override - Disabled';
      default:
        return action;
    }
  }
}
