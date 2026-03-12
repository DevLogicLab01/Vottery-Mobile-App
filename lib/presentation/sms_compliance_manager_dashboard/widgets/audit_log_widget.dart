import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../services/sms_compliance_service.dart';
import '../../../theme/app_theme.dart';

class AuditLogWidget extends StatefulWidget {
  const AuditLogWidget({super.key});

  @override
  State<AuditLogWidget> createState() => _AuditLogWidgetState();
}

class _AuditLogWidgetState extends State<AuditLogWidget> {
  final SMSComplianceService _service = SMSComplianceService.instance;

  List<Map<String, dynamic>> _auditLogs = [];
  bool _isLoading = true;
  String? _filterEventType;

  @override
  void initState() {
    super.initState();
    _loadAuditLogs();
  }

  Future<void> _loadAuditLogs() async {
    setState(() => _isLoading = true);
    final logs = await _service.getAuditLogs(eventType: _filterEventType);
    if (mounted) {
      setState(() {
        _auditLogs = logs;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildFilterBar(),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _auditLogs.isEmpty
                  ? _buildEmptyState()
                  : _buildAuditList(),
        ),
      ],
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: AppThemeColors.cardBackground,
        border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
      ),
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<String>(
              initialValue: _filterEventType,
              decoration: InputDecoration(
                labelText: 'Filter by Event',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('All Events')),
                const DropdownMenuItem(value: 'consent_granted', child: Text('Consent Granted')),
                const DropdownMenuItem(value: 'consent_revoked', child: Text('Consent Revoked')),
                const DropdownMenuItem(value: 'phone_suppressed', child: Text('Phone Suppressed')),
                const DropdownMenuItem(value: 'data_access_request', child: Text('Data Access')),
              ],
              onChanged: (value) {
                setState(() => _filterEventType = value);
                _loadAuditLogs();
              },
            ),
          ),
          SizedBox(width: 2.w),
          IconButton(
            onPressed: _loadAuditLogs,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 48.sp, color: AppTheme.textSecondary),
          SizedBox(height: 2.h),
          Text(
            'No audit logs found',
            style: TextStyle(fontSize: 14.sp, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildAuditList() {
    return ListView.builder(
      padding: EdgeInsets.all(3.w),
      itemCount: _auditLogs.length,
      itemBuilder: (context, index) {
        final log = _auditLogs[index];
        return _buildAuditCard(log);
      },
    );
  }

  Widget _buildAuditCard(Map<String, dynamic> log) {
    final eventType = log['event_type'] as String;
    final timestamp = DateTime.parse(log['timestamp']);

    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: AppThemeColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_getEventIcon(eventType), color: AppTheme.primaryLight, size: 20.sp),
              SizedBox(width: 2.w),
              Expanded(
                child: Text(
                  _formatEventType(eventType),
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryLight,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Text(
            'Time: ${timestamp.toString().split('.')[0]}',
            style: TextStyle(fontSize: 12.sp, color: AppTheme.textSecondary),
          ),
          if (log['event_details'] != null) ...[
            SizedBox(height: 0.5.h),
            Text(
              'Details: ${log['event_details']}',
              style: TextStyle(fontSize: 11.sp, color: AppTheme.textSecondary),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  IconData _getEventIcon(String eventType) {
    switch (eventType) {
      case 'consent_granted':
        return Icons.check_circle;
      case 'consent_revoked':
        return Icons.cancel;
      case 'phone_suppressed':
        return Icons.block;
      case 'data_access_request':
        return Icons.download;
      default:
        return Icons.info;
    }
  }

  String _formatEventType(String eventType) {
    return eventType
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }
}