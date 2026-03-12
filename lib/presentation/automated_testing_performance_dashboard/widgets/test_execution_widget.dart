import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../../theme/app_theme.dart';

class TestExecutionWidget extends StatelessWidget {
  final Function(String) onRunTests;
  final bool isRunning;

  const TestExecutionWidget({
    super.key,
    required this.onRunTests,
    required this.isRunning,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.all(4.w),
      children: [
        Text(
          'Test Execution Controls',
          style: GoogleFonts.inter(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 2.h),
        _buildTestSuiteCard(
          'Unit Tests',
          'Run all unit tests (80%+ coverage target)',
          'unit',
          Icons.science,
          Colors.blue,
        ),
        SizedBox(height: 2.h),
        _buildTestSuiteCard(
          'Integration Tests',
          'Run integration tests across services',
          'integration',
          Icons.integration_instructions,
          Colors.purple,
        ),
        SizedBox(height: 2.h),
        _buildTestSuiteCard(
          'E2E Tests',
          'Run end-to-end user flow tests',
          'e2e',
          Icons.route,
          Colors.orange,
        ),
        SizedBox(height: 2.h),
        _buildTestSuiteCard(
          'All Tests',
          'Run complete test suite',
          'all',
          Icons.play_circle_filled,
          Colors.green,
        ),
      ],
    );
  }

  Widget _buildTestSuiteCard(
    String title,
    String description,
    String suiteType,
    IconData icon,
    Color color,
  ) {
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
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: color.withAlpha(26),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Icon(icon, color: color, size: 8.w),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 0.5.h),
                Text(
                  description,
                  style: GoogleFonts.inter(
                    fontSize: 11.sp,
                    color: AppTheme.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 2.w),
          ElevatedButton(
            onPressed: isRunning ? null : () => onRunTests(suiteType),
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
            ),
            child: isRunning
                ? SizedBox(
                    width: 16.0,
                    height: 16.0,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.0,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    'Run',
                    style: GoogleFonts.inter(
                      fontSize: 12.sp,
                      color: Colors.white,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
