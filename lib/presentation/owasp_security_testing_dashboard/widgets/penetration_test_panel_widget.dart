import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import '../../../theme/app_theme.dart';

class PenetrationTestPanelWidget extends StatelessWidget {
  final List<Map<String, dynamic>> testRuns;
  final VoidCallback onScheduleTest;

  const PenetrationTestPanelWidget({
    super.key,
    List<Map<String, dynamic>>? testRuns,
    List<Map<String, dynamic>>? penTestRuns,
    required this.onScheduleTest,
  }) : testRuns = testRuns ?? penTestRuns ?? const [];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Penetration Testing',
              style: GoogleFonts.inter(
                fontSize: 14.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
            ElevatedButton.icon(
              onPressed: onScheduleTest,
              icon: Icon(Icons.schedule, size: 4.w),
              label: Text('Schedule Test', style: TextStyle(fontSize: 10.sp)),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
            ),
          ],
        ),
        SizedBox(height: 2.h),
        if (testRuns.isEmpty)
          _buildEmptyState()
        else
          ...testRuns.map((run) => _buildPenTestCard(run)),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.grey.withAlpha(20),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        children: [
          Icon(Icons.security_update_good, size: 10.w, color: Colors.grey),
          SizedBox(height: 1.h),
          Text(
            'No penetration tests run yet',
            style: GoogleFonts.inter(
              fontSize: 12.sp,
              color: AppTheme.textSecondaryLight,
            ),
          ),
          SizedBox(height: 0.5.h),
          Text(
            'Schedule your first automated pentest',
            style: GoogleFonts.inter(
              fontSize: 10.sp,
              color: AppTheme.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPenTestCard(Map<String, dynamic> run) {
    final runDate = run['run_date'] as String? ?? 'Unknown';
    final findings = run['findings'] ?? 0;
    final exploited = run['exploited_vulnerabilities'] ?? 0;
    final riskScore = (run['risk_score'] ?? 0.0).toDouble();
    final status = run['status'] as String? ?? 'completed';

    final riskColor = riskScore >= 8
        ? Colors.red
        : riskScore >= 5
        ? Colors.orange
        : Colors.green;

    return Container(
      margin: EdgeInsets.only(bottom: 1.5.h),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: riskColor.withAlpha(10),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: riskColor.withAlpha(50)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Run: $runDate',
                style: GoogleFonts.inter(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.3.h),
                decoration: BoxDecoration(
                  color: riskColor,
                  borderRadius: BorderRadius.circular(4.0),
                ),
                child: Text(
                  'Risk: ${riskScore.toStringAsFixed(1)}/10',
                  style: GoogleFonts.inter(
                    fontSize: 9.sp,
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 0.5.h),
          Row(
            children: [
              _buildStatChip('Findings', findings.toString(), Colors.orange),
              SizedBox(width: 2.w),
              _buildStatChip('Exploited', exploited.toString(), Colors.red),
              SizedBox(width: 2.w),
              _buildStatChip('Status', status, Colors.blue),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(String label, String value, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.3.h),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(4.0),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Text(
        '$label: $value',
        style: GoogleFonts.inter(
          fontSize: 9.sp,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
