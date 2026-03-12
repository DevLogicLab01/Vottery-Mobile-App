import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../services/user_security_service.dart';

class SecurityAuditExportWidget extends StatefulWidget {
  const SecurityAuditExportWidget({super.key});

  @override
  State<SecurityAuditExportWidget> createState() =>
      _SecurityAuditExportWidgetState();
}

class _SecurityAuditExportWidgetState extends State<SecurityAuditExportWidget> {
  List<Map<String, dynamic>> _auditTrail = [];
  bool _isLoading = true;
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    _loadAuditTrail();
  }

  Future<void> _loadAuditTrail() async {
    setState(() => _isLoading = true);

    try {
      final trail = await UserSecurityService.instance.getSecurityAuditTrail();

      if (mounted) {
        setState(() {
          _auditTrail = trail;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _exportAuditTrail() async {
    setState(() => _isExporting = true);

    try {
      final csvData = await UserSecurityService.instance
          .exportSecurityAuditTrail();

      if (csvData != null && mounted) {
        // In a real app, this would trigger a file download
        // For now, show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Audit trail exported successfully (${csvData.split('\n').length - 1} records)',
            ),
            backgroundColor: Colors.green,
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No audit trail data to export'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Export failed: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        // Export button
        Padding(
          padding: EdgeInsets.all(3.w),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isExporting ? null : _exportAuditTrail,
              icon: _isExporting
                  ? SizedBox(
                      height: 2.h,
                      width: 2.h,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.0,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.download),
              label: Text(
                _isExporting ? 'Exporting...' : 'Export Audit Trail (CSV)',
              ),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 1.5.h),
                backgroundColor: theme.colorScheme.primary,
              ),
            ),
          ),
        ),

        // Info card
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 3.w),
          child: Container(
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue),
                SizedBox(width: 2.w),
                Expanded(
                  child: Text(
                    'Export your complete security audit trail for compliance and personal record keeping',
                    style: TextStyle(fontSize: 11.sp),
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 2.h),

        // Audit trail list
        Expanded(
          child: _isLoading
              ? Center(child: CircularProgressIndicator())
              : _auditTrail.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history, size: 30.sp, color: Colors.grey),
                      SizedBox(height: 2.h),
                      Text(
                        'No audit trail records',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: 3.w),
                  itemCount: _auditTrail.length,
                  itemBuilder: (context, index) {
                    final entry = _auditTrail[index];
                    final actionType = entry['action_type'] ?? '';
                    final description = entry['action_description'] ?? '';
                    final ipAddress = entry['ip_address'];
                    final timestamp = entry['created_at'] != null
                        ? DateTime.parse(entry['created_at'])
                        : null;

                    IconData actionIcon;
                    Color actionColor;
                    switch (actionType) {
                      case 'two_factor_enabled':
                      case 'device_authorized':
                        actionIcon = Icons.check_circle;
                        actionColor = Colors.green;
                        break;
                      case 'password_changed':
                      case 'security_settings_updated':
                        actionIcon = Icons.settings;
                        actionColor = Colors.blue;
                        break;
                      case 'device_revoked':
                      case 'session_terminated':
                        actionIcon = Icons.block;
                        actionColor = Colors.red;
                        break;
                      default:
                        actionIcon = Icons.history;
                        actionColor = Colors.grey;
                    }

                    return Card(
                      margin: EdgeInsets.only(bottom: 1.h),
                      child: ListTile(
                        leading: Icon(actionIcon, color: actionColor),
                        title: Text(
                          actionType.replaceAll('_', ' ').toUpperCase(),
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: 0.5.h),
                            Text(
                              description,
                              style: TextStyle(fontSize: 11.sp),
                            ),
                            if (ipAddress != null)
                              Text(
                                'IP: $ipAddress',
                                style: TextStyle(
                                  fontSize: 10.sp,
                                  color: Colors.grey[600],
                                ),
                              ),
                            if (timestamp != null)
                              Text(
                                timestamp.toString().substring(0, 16),
                                style: TextStyle(
                                  fontSize: 10.sp,
                                  color: Colors.grey[600],
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
