import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

class TestSuiteOverviewWidget extends StatelessWidget {
  final int totalFiles;
  final int passingTests;
  final int failingTests;
  final double coveragePercentage;

  const TestSuiteOverviewWidget({
    super.key,
    required this.totalFiles,
    required this.passingTests,
    required this.failingTests,
    required this.coveragePercentage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2E),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: const Color(0xFF313244)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Test Coverage Overview',
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  label: 'Total Files',
                  value: totalFiles.toString(),
                  color: const Color(0xFF89B4FA),
                  icon: Icons.folder_open,
                ),
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: _buildMetricCard(
                  label: 'Passing',
                  value: passingTests.toString(),
                  color: const Color(0xFFA6E3A1),
                  icon: Icons.check_circle,
                ),
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: _buildMetricCard(
                  label: 'Failing',
                  value: failingTests.toString(),
                  color: const Color(0xFFF38BA8),
                  icon: Icons.cancel,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          _buildCoverageBar(coveragePercentage),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required String label,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: EdgeInsets.all(2.w),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: color.withAlpha(77)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          SizedBox(height: 0.5.h),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.inter(fontSize: 10.sp, color: Colors.white60),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildCoverageBar(double percentage) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Coverage',
              style: GoogleFonts.inter(fontSize: 11.sp, color: Colors.white60),
            ),
            Text(
              '${percentage.toStringAsFixed(1)}%',
              style: GoogleFonts.inter(
                fontSize: 11.sp,
                fontWeight: FontWeight.w600,
                color: percentage >= 80
                    ? const Color(0xFFA6E3A1)
                    : const Color(0xFFF9E2AF),
              ),
            ),
          ],
        ),
        SizedBox(height: 0.5.h),
        ClipRRect(
          borderRadius: BorderRadius.circular(4.0),
          child: LinearProgressIndicator(
            value: percentage / 100,
            backgroundColor: const Color(0xFF313244),
            valueColor: AlwaysStoppedAnimation<Color>(
              percentage >= 80
                  ? const Color(0xFFA6E3A1)
                  : const Color(0xFFF9E2AF),
            ),
            minHeight: 8,
          ),
        ),
      ],
    );
  }
}
