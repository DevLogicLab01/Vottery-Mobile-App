import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:google_fonts/google_fonts.dart';

class JurisdictionComplianceCardWidget extends StatelessWidget {
  final Map<String, String> jurisdiction;
  final Map<String, dynamic> status;
  final VoidCallback onGenerateReport;

  const JurisdictionComplianceCardWidget({
    super.key,
    required this.jurisdiction,
    required this.status,
    required this.onGenerateReport,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final complianceScore = (status['compliance_score'] ?? 0.0) as double;
    final totalReports = (status['total_reports'] ?? 0) as int;
    final pendingReports = (status['pending_reports'] ?? 0) as int;
    final completedReports = (status['completed_reports'] ?? 0) as int;

    final scoreColor = complianceScore >= 90
        ? Colors.green
        : complianceScore >= 70
        ? Colors.orange
        : Colors.red;

    return Card(
      margin: EdgeInsets.only(bottom: 2.h),
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        jurisdiction['code']!,
                        style: GoogleFonts.inter(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      SizedBox(height: 0.5.h),
                      Text(
                        jurisdiction['name']!,
                        style: GoogleFonts.inter(
                          fontSize: 11.sp,
                          color: theme.colorScheme.onSurface.withAlpha(179),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                  decoration: BoxDecoration(
                    color: scoreColor.withAlpha(26),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Text(
                    '${complianceScore.toStringAsFixed(0)}%',
                    style: GoogleFonts.inter(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: scoreColor,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 2.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatColumn('Total', totalReports.toString(), theme),
                _buildStatColumn('Pending', pendingReports.toString(), theme),
                _buildStatColumn(
                  'Completed',
                  completedReports.toString(),
                  theme,
                ),
              ],
            ),
            SizedBox(height: 2.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onGenerateReport,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  padding: EdgeInsets.symmetric(vertical: 1.5.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                child: Text(
                  'Generate Report',
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, ThemeData theme) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        SizedBox(height: 0.5.h),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11.sp,
            color: theme.colorScheme.onSurface.withAlpha(153),
          ),
        ),
      ],
    );
  }
}
