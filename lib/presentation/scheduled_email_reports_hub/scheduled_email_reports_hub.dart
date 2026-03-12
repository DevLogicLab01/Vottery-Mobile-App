import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/resend_email_service.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/enhanced_empty_state_widget.dart';
import '../../widgets/error_boundary_wrapper.dart';
import '../../widgets/shimmer_skeleton_loader.dart';

/// Scheduled Email Reports Hub for automated report distribution
class ScheduledEmailReportsHub extends StatefulWidget {
  const ScheduledEmailReportsHub({super.key});

  @override
  State<ScheduledEmailReportsHub> createState() =>
      _ScheduledEmailReportsHubState();
}

class _ScheduledEmailReportsHubState extends State<ScheduledEmailReportsHub> {
  final ResendEmailService _emailService = ResendEmailService.instance;
  bool _isLoading = true;
  List<Map<String, dynamic>> _scheduledReports = [];

  @override
  void initState() {
    super.initState();
    _loadScheduledReports();
  }

  Future<void> _loadScheduledReports() async {
    setState(() => _isLoading = true);

    try {
      final reports = await _emailService.getScheduledReports();
      setState(() {
        _scheduledReports = reports;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Load scheduled reports error: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _createScheduledReport() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _ScheduleReportDialog(),
    );

    if (result != null) {
      final response = await _emailService.scheduleEmailReport(
        recipientEmail: result['email'],
        reportType: result['type'],
        frequency: result['frequency'],
        reportConfig: result['config'],
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message']),
            backgroundColor: response['success'] ? Colors.green : Colors.red,
          ),
        );
        if (response['success']) _loadScheduledReports();
      }
    }
  }

  Future<void> _cancelReport(String reportId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Scheduled Report'),
        content: const Text(
          'Are you sure you want to cancel this scheduled report?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await _emailService.cancelScheduledReport(reportId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success ? 'Report cancelled' : 'Failed to cancel report',
            ),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
        if (success) _loadScheduledReports();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ErrorBoundaryWrapper(
      screenName: 'ScheduledEmailReportsHub',
      onRetry: _loadScheduledReports,
      child: Scaffold(
        backgroundColor: AppTheme.backgroundLight,
        appBar: CustomAppBar(
          leading: Padding(
            padding: EdgeInsets.only(left: 4.w),
            child: IconButton(
              icon: CustomIconWidget(
                iconName: 'arrow_back',
                size: 6.w,
                color: AppTheme.textPrimaryLight,
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          title: 'Scheduled Email Reports',
          actions: [
            IconButton(
              icon: Icon(Icons.add, size: 6.w),
              onPressed: _createScheduledReport,
            ),
          ],
        ),
        body: _isLoading
            ? const SkeletonDashboard()
            : _scheduledReports.isEmpty
            ? NoDataEmptyState(
                title: 'No Scheduled Reports',
                description:
                    'Create automated email reports for compliance, analytics, and billing.',
                onRefresh: _loadScheduledReports,
              )
            : RefreshIndicator(
                onRefresh: _loadScheduledReports,
                child: ListView.builder(
                  padding: EdgeInsets.all(4.w),
                  itemCount: _scheduledReports.length,
                  itemBuilder: (context, index) {
                    final report = _scheduledReports[index];
                    return _buildReportCard(report);
                  },
                ),
              ),
      ),
    );
  }

  Widget _buildReportCard(Map<String, dynamic> report) {
    final isActive = report['is_active'] ?? false;
    final reportType = report['report_type'] ?? 'Unknown';
    final frequency = report['frequency'] ?? 'Unknown';
    final nextDelivery = report['next_delivery'] ?? '';

    return Card(
      margin: EdgeInsets.only(bottom: 2.h),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    _formatReportType(reportType),
                    style: GoogleFonts.inter(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimaryLight,
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 2.w,
                    vertical: 0.5.h,
                  ),
                  decoration: BoxDecoration(
                    color: isActive
                        ? Colors.green.withAlpha(26)
                        : Colors.grey.withAlpha(26),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Text(
                    isActive ? 'Active' : 'Inactive',
                    style: GoogleFonts.inter(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w600,
                      color: isActive ? Colors.green : Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 1.h),
            Row(
              children: [
                Icon(
                  Icons.schedule,
                  size: 4.w,
                  color: AppTheme.textSecondaryLight,
                ),
                SizedBox(width: 2.w),
                Text(
                  'Frequency: ${_formatFrequency(frequency)}',
                  style: GoogleFonts.inter(
                    fontSize: 11.sp,
                    color: AppTheme.textSecondaryLight,
                  ),
                ),
              ],
            ),
            SizedBox(height: 0.5.h),
            Row(
              children: [
                Icon(
                  Icons.email,
                  size: 4.w,
                  color: AppTheme.textSecondaryLight,
                ),
                SizedBox(width: 2.w),
                Text(
                  report['recipient_email'] ?? 'No email',
                  style: GoogleFonts.inter(
                    fontSize: 11.sp,
                    color: AppTheme.textSecondaryLight,
                  ),
                ),
              ],
            ),
            if (nextDelivery.isNotEmpty) ...[
              SizedBox(height: 0.5.h),
              Row(
                children: [
                  Icon(
                    Icons.send,
                    size: 4.w,
                    color: AppTheme.textSecondaryLight,
                  ),
                  SizedBox(width: 2.w),
                  Text(
                    'Next: ${_formatDate(nextDelivery)}',
                    style: GoogleFonts.inter(
                      fontSize: 11.sp,
                      color: AppTheme.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ],
            SizedBox(height: 2.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _cancelReport(report['id']),
                  icon: Icon(Icons.cancel, size: 4.w, color: Colors.red),
                  label: Text(
                    'Cancel',
                    style: GoogleFonts.inter(
                      fontSize: 11.sp,
                      color: Colors.red,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatReportType(String type) {
    return type
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  String _formatFrequency(String frequency) {
    return frequency[0].toUpperCase() + frequency.substring(1);
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateStr;
    }
  }
}

class _ScheduleReportDialog extends StatefulWidget {
  @override
  State<_ScheduleReportDialog> createState() => _ScheduleReportDialogState();
}

class _ScheduleReportDialogState extends State<_ScheduleReportDialog> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  String _selectedType = 'compliance_report';
  String _selectedFrequency = 'weekly';

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Schedule Email Report'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Recipient Email',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Required';
                  if (!value.contains('@')) return 'Invalid email';
                  return null;
                },
              ),
              SizedBox(height: 2.h),
              DropdownButtonFormField<String>(
                initialValue: _selectedType,
                decoration: const InputDecoration(
                  labelText: 'Report Type',
                  border: OutlineInputBorder(),
                ),
                items: [
                  DropdownMenuItem(
                    value: 'compliance_report',
                    child: Text('Compliance Report'),
                  ),
                  DropdownMenuItem(
                    value: 'campaign_analytics',
                    child: Text('Campaign Analytics'),
                  ),
                  DropdownMenuItem(
                    value: 'billing_summary',
                    child: Text('Billing Summary'),
                  ),
                  DropdownMenuItem(
                    value: 'settlement_confirmation',
                    child: Text('Settlement Confirmation'),
                  ),
                ],
                onChanged: (value) => setState(() => _selectedType = value!),
              ),
              SizedBox(height: 2.h),
              DropdownButtonFormField<String>(
                initialValue: _selectedFrequency,
                decoration: const InputDecoration(
                  labelText: 'Frequency',
                  border: OutlineInputBorder(),
                ),
                items: [
                  DropdownMenuItem(value: 'daily', child: Text('Daily')),
                  DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
                  DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
                ],
                onChanged: (value) =>
                    setState(() => _selectedFrequency = value!),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.pop(context, {
                'email': _emailController.text,
                'type': _selectedType,
                'frequency': _selectedFrequency,
                'config': {},
              });
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.vibrantYellow,
          ),
          child: const Text('Schedule', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
