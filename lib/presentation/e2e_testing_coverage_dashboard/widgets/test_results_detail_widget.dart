import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

class TestResultsDetailWidget extends StatelessWidget {
  final List<Map<String, dynamic>> testResults;

  const TestResultsDetailWidget({super.key, required this.testResults});

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Test Results',
                style: GoogleFonts.inter(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF313244),
                  borderRadius: BorderRadius.circular(6.0),
                ),
                child: Text(
                  '${testResults.length} results',
                  style: GoogleFonts.inter(
                    fontSize: 9.sp,
                    color: Colors.white60,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 1.5.h),
          if (testResults.isEmpty)
            Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 2.h),
                child: Text(
                  'No test results yet. Run tests to see results.',
                  style: GoogleFonts.inter(
                    fontSize: 11.sp,
                    color: Colors.white38,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          else
            ...testResults.map((result) => _buildResultItem(result)),
        ],
      ),
    );
  }

  Widget _buildResultItem(Map<String, dynamic> result) {
    final passed = result['passed'] as bool? ?? false;
    final testName = result['test_name'] as String? ?? 'Unknown Test';
    final duration = result['duration_ms'] as int? ?? 0;
    final assertions = result['assertions'] as List<dynamic>? ?? [];

    return Container(
      margin: EdgeInsets.only(bottom: 1.h),
      padding: EdgeInsets.all(2.w),
      decoration: BoxDecoration(
        color: passed
            ? const Color(0xFFA6E3A1).withAlpha(13)
            : const Color(0xFFF38BA8).withAlpha(13),
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(
          color: passed
              ? const Color(0xFFA6E3A1).withAlpha(51)
              : const Color(0xFFF38BA8).withAlpha(51),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                passed ? Icons.check_circle : Icons.cancel,
                color: passed
                    ? const Color(0xFFA6E3A1)
                    : const Color(0xFFF38BA8),
                size: 14,
              ),
              SizedBox(width: 1.w),
              Expanded(
                child: Text(
                  testName,
                  style: GoogleFonts.inter(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '${duration}ms',
                style: GoogleFonts.inter(fontSize: 9.sp, color: Colors.white38),
              ),
            ],
          ),
          if (assertions.isNotEmpty) ...[
            SizedBox(height: 0.5.h),
            ...assertions.take(2).map((assertion) {
              return Padding(
                padding: EdgeInsets.only(left: 4.w, top: 0.3.h),
                child: Row(
                  children: [
                    const Icon(
                      Icons.arrow_right,
                      size: 12,
                      color: Colors.white38,
                    ),
                    Expanded(
                      child: Text(
                        assertion.toString(),
                        style: GoogleFonts.inter(
                          fontSize: 9.sp,
                          color: Colors.white54,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}
