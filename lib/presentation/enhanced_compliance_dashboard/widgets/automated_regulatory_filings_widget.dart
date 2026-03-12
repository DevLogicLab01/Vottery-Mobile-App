import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../services/compliance_service.dart';
import '../../../widgets/custom_icon_widget.dart';

class AutomatedRegulatoryFilingsWidget extends StatefulWidget {
  const AutomatedRegulatoryFilingsWidget({super.key});

  @override
  State<AutomatedRegulatoryFilingsWidget> createState() =>
      _AutomatedRegulatoryFilingsWidgetState();
}

class _AutomatedRegulatoryFilingsWidgetState
    extends State<AutomatedRegulatoryFilingsWidget> {
  final ComplianceService _complianceService = ComplianceService.instance;
  bool _isLoading = false;
  List<Map<String, dynamic>> _filings = [];

  final List<Map<String, dynamic>> _filingTemplates = [
    {
      'type': 'GDPR',
      'name': 'GDPR Data Processing Report',
      'icon': 'description',
      'color': Colors.blue,
    },
    {
      'type': 'CCPA',
      'name': 'CCPA Consumer Rights Report',
      'icon': 'privacy_tip',
      'color': Colors.purple,
    },
    {
      'type': 'GDPR',
      'name': 'GDPR Breach Notification',
      'icon': 'warning',
      'color': Colors.red,
    },
    {
      'type': 'CCPA',
      'name': 'CCPA Opt-Out Request Log',
      'icon': 'block',
      'color': Colors.orange,
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadFilings();
  }

  Future<void> _loadFilings() async {
    setState(() => _isLoading = true);
    try {
      final logs = await _complianceService.getComplianceAuditLogs(
        complianceType: 'GDPR',
        limit: 20,
      );
      setState(() => _filings = logs);
    } catch (e) {
      debugPrint('Load filings error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return _isLoading
        ? Center(
            child: CircularProgressIndicator(color: theme.colorScheme.primary),
          )
        : SingleChildScrollView(
            padding: EdgeInsets.all(4.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Document Templates',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                SizedBox(height: 2.h),
                ..._filingTemplates.map((template) {
                  return _buildTemplateCard(context, template);
                }),
                SizedBox(height: 3.h),
                Text(
                  'Recent Filings',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                SizedBox(height: 2.h),
                if (_filings.isEmpty)
                  Center(
                    child: Padding(
                      padding: EdgeInsets.all(4.w),
                      child: Text(
                        'No recent filings',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontSize: 12.sp,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  )
                else
                  ..._filings.map((filing) {
                    return _buildFilingCard(context, filing);
                  }),
              ],
            ),
          );
  }

  Widget _buildTemplateCard(
    BuildContext context,
    Map<String, dynamic> template,
  ) {
    final theme = Theme.of(context);
    final color = template['color'] as Color;

    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: color.withAlpha(51)),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: color.withAlpha(26),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: CustomIconWidget(
              iconName: template['icon'],
              color: color,
              size: 24,
            ),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  template['name'],
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                Text(
                  template['type'],
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 11.sp,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => _generateFiling(template['type']),
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
            ),
            child: Text(
              'Generate',
              style: theme.textTheme.labelLarge?.copyWith(
                fontSize: 11.sp,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilingCard(BuildContext context, Map<String, dynamic> filing) {
    final theme = Theme.of(context);
    final status = filing['action_type'] ?? 'pending';
    final statusColor = _getStatusColor(status);

    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12.0),
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
              Expanded(
                child: Text(
                  filing['compliance_type'] ?? 'Filing',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.5.h),
                decoration: BoxDecoration(
                  color: statusColor.withAlpha(26),
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Text(
                  status,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Text(
            'Created: ${_formatDate(filing['created_at'])}',
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 11.sp,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _generateFiling(String type) async {
    final success = await _complianceService.generateGDPRReport(
      requestType: type,
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? '$type filing generated successfully'
                : 'Failed to generate filing',
          ),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
      if (success) {
        _loadFilings();
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'failed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'N/A';
    try {
      final dateTime = DateTime.parse(date.toString());
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } catch (e) {
      return 'N/A';
    }
  }
}
