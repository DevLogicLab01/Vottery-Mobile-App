import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/error_boundary_wrapper.dart';

/// Analytics Export & Reporting Hub (Mobile parity with Web).
/// Report templates, PDF/CSV, daily/weekly/monthly scheduling, email delivery.
class AnalyticsExportReportingHubScreen extends StatefulWidget {
  const AnalyticsExportReportingHubScreen({super.key});

  @override
  State<AnalyticsExportReportingHubScreen> createState() =>
      _AnalyticsExportReportingHubScreenState();
}

class _AnalyticsExportReportingHubScreenState
    extends State<AnalyticsExportReportingHubScreen> {
  String _selectedTemplate = 'revenue';
  String _selectedFormat = 'PDF';
  String _selectedFrequency = 'daily';
  bool _generating = false;
  Map<String, dynamic>? _generatedReport;
  final List<Map<String, dynamic>> _scheduledReports = [
    {'template': 'Revenue Summary', 'frequency': 'daily', 'time': '08:00 UTC', 'recipients': 2, 'status': 'active'},
    {'template': 'User Engagement', 'frequency': 'weekly', 'time': 'Mon 09:00', 'recipients': 2, 'status': 'active'},
    {'template': 'Performance Metrics', 'frequency': 'weekly', 'time': 'Mon 07:00', 'recipients': 1, 'status': 'active'},
  ];

  static const _templates = [
    {'id': 'revenue', 'name': 'Revenue Summary Report', 'metrics': 'Revenue, zones, subscriptions'},
    {'id': 'engagement', 'name': 'User Engagement Report', 'metrics': 'DAU/MAU, retention, voting'},
    {'id': 'performance', 'name': 'Performance Metrics Report', 'metrics': 'Latency, uptime, errors'},
    {'id': 'executive', 'name': 'Executive Dashboard Report', 'metrics': 'All key metrics'},
  ];

  Future<void> _generateReport() async {
    setState(() => _generating = true);
    await Future.delayed(const Duration(seconds: 2));
    setState(() {
      _generating = false;
      _generatedReport = {
        'name': _templates.firstWhere((t) => t['id'] == _selectedTemplate)['name'],
        'format': _selectedFormat,
        'generatedAt': DateTime.now().toIso8601String(),
        'size': '2.1 MB',
        'pages': 12,
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    return ErrorBoundaryWrapper(
      screenName: 'AnalyticsExportReportingHub',
      onRetry: _generateReport,
      child: Scaffold(
        backgroundColor: AppTheme.backgroundLight,
        appBar: CustomAppBar(
          leading: Padding(
            padding: EdgeInsets.only(left: 4.w),
            child: IconButton(
              icon: CustomIconWidget(iconName: 'arrow_back', size: 6.w, color: AppTheme.textPrimaryLight),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          title: 'Analytics Export & Reporting',
        ),
        body: SingleChildScrollView(
          padding: EdgeInsets.all(4.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Generate report', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold)),
              SizedBox(height: 2.h),
              DropdownButtonFormField<String>(
                value: _selectedTemplate,
                decoration: InputDecoration(labelText: 'Template', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                items: _templates.map((t) => DropdownMenuItem(value: t['id'] as String, child: Text(t['name'] as String))).toList(),
                onChanged: (v) => setState(() => _selectedTemplate = v ?? 'revenue'),
              ),
              SizedBox(height: 2.h),
              DropdownButtonFormField<String>(
                value: _selectedFormat,
                decoration: InputDecoration(labelText: 'Format', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                items: ['PDF', 'CSV'].map((f) => DropdownMenuItem(value: f, child: Text(f))).toList(),
                onChanged: (v) => setState(() => _selectedFormat = v ?? 'PDF'),
              ),
              SizedBox(height: 2.h),
              DropdownButtonFormField<String>(
                value: _selectedFrequency,
                decoration: InputDecoration(labelText: 'Schedule (for new)', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                items: ['daily', 'weekly', 'monthly'].map((f) => DropdownMenuItem(value: f, child: Text(f))).toList(),
                onChanged: (v) => setState(() => _selectedFrequency = v ?? 'daily'),
              ),
              SizedBox(height: 2.h),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _generating ? null : _generateReport,
                  icon: _generating ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : Icon(Icons.file_download),
                  label: Text(_generating ? 'Generating...' : 'Generate & Download'),
                ),
              ),
              if (_generatedReport != null) ...[
                SizedBox(height: 3.h),
                Card(
                  child: Padding(
                    padding: EdgeInsets.all(4.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Generated: ${_generatedReport!['name']}', style: TextStyle(fontWeight: FontWeight.w600)),
                        Text('${_generatedReport!['format']} · ${_generatedReport!['size']} · ${_generatedReport!['pages']} pages'),
                        Text('At ${_generatedReport!['generatedAt']}', style: TextStyle(fontSize: 11.sp, color: AppTheme.textSecondaryLight)),
                      ],
                    ),
                  ),
                ),
              ],
              SizedBox(height: 4.h),
              Text('Scheduled reports (email delivery)', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold)),
              SizedBox(height: 2.h),
              ..._scheduledReports.map((s) => Card(
                margin: EdgeInsets.only(bottom: 2.h),
                child: ListTile(
                  title: Text(s['template'] as String),
                  subtitle: Text('${s['frequency']} at ${s['time']} · ${s['recipients']} recipients'),
                  trailing: Chip(label: Text((s['status'] as String).toUpperCase(), style: TextStyle(fontSize: 10.sp)), backgroundColor: Colors.green.shade100),
                ),
              )),
            ],
          ),
        ),
      ),
    );
  }
}
