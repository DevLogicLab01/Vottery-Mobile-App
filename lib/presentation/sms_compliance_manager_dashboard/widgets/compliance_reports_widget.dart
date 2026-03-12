import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../services/sms_compliance_service.dart';
import '../../../theme/app_theme.dart';

class ComplianceReportsWidget extends StatefulWidget {
  const ComplianceReportsWidget({super.key});

  @override
  State<ComplianceReportsWidget> createState() =>
      _ComplianceReportsWidgetState();
}

class _ComplianceReportsWidgetState extends State<ComplianceReportsWidget> {
  final SMSComplianceService _service = SMSComplianceService.instance;

  Map<String, dynamic> _report = {};
  bool _isLoading = true;
  final DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  final DateTime _endDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _generateReport();
  }

  Future<void> _generateReport() async {
    setState(() => _isLoading = true);
    final report = await _service.generateComplianceReport(
      startDate: _startDate,
      endDate: _endDate,
    );
    if (mounted) {
      setState(() {
        _report = report;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final consentMetrics = _report['consent_metrics'] ?? {};
    final suppressionMetrics = _report['suppression_metrics'] ?? {};
    final auditMetrics = _report['audit_metrics'] ?? {};

    return SingleChildScrollView(
      padding: EdgeInsets.all(3.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDateRangeSelector(),
          SizedBox(height: 2.h),
          _buildMetricsSection('Consent Metrics', consentMetrics),
          SizedBox(height: 2.h),
          _buildMetricsSection('Suppression Metrics', suppressionMetrics),
          SizedBox(height: 2.h),
          _buildMetricsSection('Audit Metrics', auditMetrics),
          SizedBox(height: 2.h),
          _buildExportButton(),
        ],
      ),
    );
  }

  Widget _buildDateRangeSelector() {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: AppThemeColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Report Period',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          SizedBox(height: 1.h),
          Row(
            children: [
              Expanded(
                child: Text(
                  'From: ${_startDate.toString().split(' ')[0]}',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  'To: ${_endDate.toString().split(' ')[0]}',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          ElevatedButton(
            onPressed: _generateReport,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryLight,
              minimumSize: Size(double.infinity, 5.h),
            ),
            child: Text('Regenerate Report', style: TextStyle(fontSize: 12.sp)),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsSection(String title, Map<String, dynamic> metrics) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: AppThemeColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          SizedBox(height: 1.h),
          ...metrics.entries.map((entry) {
            if (entry.value is Map) return const SizedBox.shrink();
            return Padding(
              padding: EdgeInsets.only(bottom: 0.5.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatKey(entry.key),
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  Text(
                    entry.value.toString(),
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimaryLight,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildExportButton() {
    return ElevatedButton.icon(
      onPressed: _exportReport,
      icon: const Icon(Icons.download),
      label: Text('Export as CSV', style: TextStyle(fontSize: 12.sp)),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green,
        minimumSize: Size(double.infinity, 6.h),
      ),
    );
  }

  Future<void> _exportReport() async {
    final csv = await _service.exportComplianceReportCSV(
      startDate: _startDate,
      endDate: _endDate,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Report exported successfully')),
      );
    }
  }

  String _formatKey(String key) {
    return key
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }
}