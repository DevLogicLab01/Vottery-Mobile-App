import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../services/sla_monitoring_service.dart';

class SlaReportGeneratorWidget extends StatefulWidget {
  const SlaReportGeneratorWidget({super.key});

  @override
  State<SlaReportGeneratorWidget> createState() =>
      _SlaReportGeneratorWidgetState();
}

class _SlaReportGeneratorWidgetState extends State<SlaReportGeneratorWidget> {
  final SLAMonitoringService _service = SLAMonitoringService.instance;

  String _selectedPeriod = 'last_30_days';
  bool _includeCharts = true;
  bool _includeIncidents = true;
  bool _includeRecommendations = true;
  bool _isGenerating = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Generate SLA Report',
              style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 2.h),
            DropdownButtonFormField<String>(
              initialValue: _selectedPeriod,
              decoration: InputDecoration(
                labelText: 'Report Period',
                border: OutlineInputBorder(),
              ),
              items: [
                DropdownMenuItem(
                  value: 'last_7_days',
                  child: Text('Last 7 Days'),
                ),
                DropdownMenuItem(
                  value: 'last_30_days',
                  child: Text('Last 30 Days'),
                ),
                DropdownMenuItem(
                  value: 'last_quarter',
                  child: Text('Last Quarter'),
                ),
                DropdownMenuItem(value: 'last_year', child: Text('Last Year')),
              ],
              onChanged: (value) {
                setState(() => _selectedPeriod = value!);
              },
            ),
            SizedBox(height: 2.h),
            CheckboxListTile(
              title: Text('Include Charts', style: TextStyle(fontSize: 12.sp)),
              value: _includeCharts,
              onChanged: (value) {
                setState(() => _includeCharts = value!);
              },
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
            CheckboxListTile(
              title: Text(
                'Include Incident Details',
                style: TextStyle(fontSize: 12.sp),
              ),
              value: _includeIncidents,
              onChanged: (value) {
                setState(() => _includeIncidents = value!);
              },
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
            CheckboxListTile(
              title: Text(
                'Include AI Recommendations',
                style: TextStyle(fontSize: 12.sp),
              ),
              value: _includeRecommendations,
              onChanged: (value) {
                setState(() => _includeRecommendations = value!);
              },
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
            SizedBox(height: 2.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isGenerating ? null : _generateReport,
                icon: _isGenerating
                    ? SizedBox(
                        width: 16.sp,
                        height: 16.sp,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : Icon(Icons.description),
                label: Text(
                  _isGenerating ? 'Generating...' : 'Generate Report',
                  style: TextStyle(fontSize: 13.sp),
                ),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 1.5.h),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _generateReport() async {
    setState(() => _isGenerating = true);

    try {
      final report = await _service.generateSLAReport(period: _selectedPeriod);

      setState(() => _isGenerating = false);

      if (report.isEmpty) {
        _showErrorDialog('Failed to generate report');
        return;
      }

      _showReportPreview(report);
    } catch (e) {
      setState(() => _isGenerating = false);
      _showErrorDialog('Error: $e');
    }
  }

  void _showReportPreview(Map<String, dynamic> report) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('SLA Compliance Report'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Executive Summary',
                style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 1.h),
              _buildReportRow(
                'Overall Uptime',
                '${(report['executive_summary']['overall_uptime'] ?? 0.0).toStringAsFixed(2)}%',
              ),
              _buildReportRow(
                'SLA Compliance',
                report['executive_summary']['sla_compliance'] ?? 'N/A',
              ),
              _buildReportRow(
                'Major Incidents',
                '${report['executive_summary']['major_incidents'] ?? 0}',
              ),
              _buildReportRow(
                'Total Downtime',
                '${(report['executive_summary']['total_downtime_minutes'] ?? 0.0).toStringAsFixed(1)} min',
              ),
              SizedBox(height: 2.h),
              if (_includeRecommendations &&
                  report['recommendations'] != null) ...[
                Text(
                  'AI Recommendations',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 1.h),
                ...(report['recommendations'] as List).map(
                  (rec) => Padding(
                    padding: EdgeInsets.only(bottom: 0.5.h),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('• ', style: TextStyle(fontSize: 12.sp)),
                        Expanded(
                          child: Text(
                            rec.toString(),
                            style: TextStyle(fontSize: 11.sp),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _downloadReport(report);
            },
            child: Text('Download'),
          ),
        ],
      ),
    );
  }

  Widget _buildReportRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 1.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 11.sp, color: Colors.grey[600]),
          ),
          Text(
            value,
            style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  void _downloadReport(Map<String, dynamic> report) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Report downloaded successfully'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }
}
