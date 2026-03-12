import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../../theme/app_theme.dart';

class TestCoverageWidget extends StatelessWidget {
  final Map<String, dynamic> coverageData;
  final VoidCallback onRefresh;

  const TestCoverageWidget({
    super.key,
    required this.coverageData,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final unitCoverage = coverageData['unit_test_coverage'] ?? 0.0;
    final integrationCoverage =
        coverageData['integration_test_coverage'] ?? 0.0;
    final e2eCoverage = coverageData['e2e_test_coverage'] ?? 0.0;
    final totalTests = coverageData['total_tests'] ?? 0;
    final passedTests = coverageData['passed_tests'] ?? 0;
    final failedTests = coverageData['failed_tests'] ?? 0;

    return ListView(
      padding: EdgeInsets.all(4.w),
      children: [
        Text(
          'Test Coverage Analytics',
          style: GoogleFonts.inter(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 2.h),
        _buildCoverageSection(
          'Unit Test Coverage',
          unitCoverage,
          80.0,
          'Target: 80%+',
        ),
        SizedBox(height: 2.h),
        _buildCoverageSection(
          'Integration Test Coverage',
          integrationCoverage,
          70.0,
          'Target: 70%+',
        ),
        SizedBox(height: 2.h),
        _buildCoverageSection(
          'E2E Test Coverage',
          e2eCoverage,
          60.0,
          'Target: 60%+',
        ),
        SizedBox(height: 3.h),
        _buildTestResultsCard(totalTests, passedTests, failedTests),
      ],
    );
  }

  Widget _buildCoverageSection(
    String title,
    double coverage,
    double target,
    String targetLabel,
  ) {
    final isOnTarget = coverage >= target;
    final color = isOnTarget ? Colors.green : Colors.orange;

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 4.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${coverage.toStringAsFixed(1)}%',
                style: GoogleFonts.inter(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          LinearProgressIndicator(
            value: coverage / 100,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 1.h,
          ),
          SizedBox(height: 0.5.h),
          Text(
            targetLabel,
            style: GoogleFonts.inter(
              fontSize: 11.sp,
              color: AppTheme.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTestResultsCard(int total, int passed, int failed) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 4.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Test Results Summary',
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 2.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildResultStat('Total', total, Colors.blue),
              _buildResultStat('Passed', passed, Colors.green),
              _buildResultStat('Failed', failed, Colors.red),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResultStat(String label, int value, Color color) {
    return Column(
      children: [
        Text(
          value.toString(),
          style: GoogleFonts.inter(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11.sp,
            color: AppTheme.textSecondaryLight,
          ),
        ),
      ],
    );
  }
}
