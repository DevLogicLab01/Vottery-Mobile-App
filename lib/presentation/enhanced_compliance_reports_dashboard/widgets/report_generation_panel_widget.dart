import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:timeago/timeago.dart' as timeago;

class ReportGenerationPanelWidget extends StatelessWidget {
  final Function(String jurisdiction) onGenerateReport;
  final List<Map<String, dynamic>> recentReports;

  const ReportGenerationPanelWidget({
    super.key,
    required this.onGenerateReport,
    required this.recentReports,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Generate New Report',
          style: GoogleFonts.inter(
            fontSize: 14.sp,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        SizedBox(height: 2.h),
        _buildReportTypeCard(
          context,
          'Data Export',
          'Comprehensive user data package including personal info, voting history, and transaction records',
          Icons.download,
          () => _showJurisdictionSelector(context, 'data_export'),
        ),
        SizedBox(height: 2.h),
        _buildReportTypeCard(
          context,
          'Right to Erasure',
          'Automated cascading deletion workflow across all database tables',
          Icons.delete_forever,
          () => _showJurisdictionSelector(context, 'right_to_erasure'),
        ),
        SizedBox(height: 2.h),
        _buildReportTypeCard(
          context,
          'Consent Audit',
          'Granular permission tracking with withdrawal history',
          Icons.verified_user,
          () => _showJurisdictionSelector(context, 'consent_audit'),
        ),
        SizedBox(height: 2.h),
        _buildReportTypeCard(
          context,
          'Access Log',
          'Complete audit trail of all data access events',
          Icons.history,
          () => _showJurisdictionSelector(context, 'access_log'),
        ),
        SizedBox(height: 3.h),
        Text(
          'Recent Reports',
          style: GoogleFonts.inter(
            fontSize: 14.sp,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        SizedBox(height: 2.h),
        ...recentReports
            .take(10)
            .map((report) => _buildReportListItem(context, report)),
      ],
    );
  }

  Widget _buildReportTypeCard(
    BuildContext context,
    String title,
    String description,
    IconData icon,
    VoidCallback onTap,
  ) {
    final theme = Theme.of(context);

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8.0),
        child: Padding(
          padding: EdgeInsets.all(4.w),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(3.w),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withAlpha(26),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Icon(icon, color: theme.colorScheme.primary, size: 24),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    SizedBox(height: 0.5.h),
                    Text(
                      description,
                      style: GoogleFonts.inter(
                        fontSize: 11.sp,
                        color: theme.colorScheme.onSurface.withAlpha(153),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: theme.colorScheme.onSurface.withAlpha(102),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReportListItem(
    BuildContext context,
    Map<String, dynamic> report,
  ) {
    final theme = Theme.of(context);
    final jurisdiction = report['jurisdiction'] as String? ?? 'Unknown';
    final reportType = report['report_type'] as String? ?? 'Unknown';
    final status = report['status'] as String? ?? 'pending';
    final generatedAt = report['generated_at'] as String?;

    Color statusColor;
    switch (status) {
      case 'completed':
        statusColor = Colors.green;
        break;
      case 'failed':
        statusColor = Colors.red;
        break;
      default:
        statusColor = Colors.orange;
    }

    return Card(
      margin: EdgeInsets.only(bottom: 1.h),
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$jurisdiction - ${reportType.replaceAll('_', ' ').toUpperCase()}',
                    style: GoogleFonts.inter(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  SizedBox(height: 0.5.h),
                  Text(
                    generatedAt != null
                        ? timeago.format(DateTime.parse(generatedAt))
                        : 'Unknown time',
                    style: GoogleFonts.inter(
                      fontSize: 11.sp,
                      color: theme.colorScheme.onSurface.withAlpha(153),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
              decoration: BoxDecoration(
                color: statusColor.withAlpha(26),
                borderRadius: BorderRadius.circular(4.0),
              ),
              child: Text(
                status.toUpperCase(),
                style: GoogleFonts.inter(
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w600,
                  color: statusColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showJurisdictionSelector(BuildContext context, String reportType) {
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: EdgeInsets.all(4.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Jurisdiction',
              style: GoogleFonts.inter(
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            SizedBox(height: 2.h),
            ListTile(
              title: Text('GDPR (EU)'),
              onTap: () {
                Navigator.pop(context);
                onGenerateReport('GDPR');
              },
            ),
            ListTile(
              title: Text('CCPA (California)'),
              onTap: () {
                Navigator.pop(context);
                onGenerateReport('CCPA');
              },
            ),
            ListTile(
              title: Text('CCRA (Canada)'),
              onTap: () {
                Navigator.pop(context);
                onGenerateReport('CCRA');
              },
            ),
          ],
        ),
      ),
    );
  }
}
