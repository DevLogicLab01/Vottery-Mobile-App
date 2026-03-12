import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

class BatchTestControlsWidget extends StatelessWidget {
  final bool isRunningAll;
  final int completedTests;
  final int totalTests;
  final VoidCallback onRunAll;
  final VoidCallback onGenerateReport;

  const BatchTestControlsWidget({
    super.key,
    required this.isRunningAll,
    required this.completedTests,
    required this.totalTests,
    required this.onRunAll,
    required this.onGenerateReport,
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
            'Batch Test Controls',
            style: GoogleFonts.inter(
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 1.5.h),
          if (isRunningAll) ...[
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Running tests... $completedTests/$totalTests',
                        style: GoogleFonts.inter(
                          fontSize: 11.sp,
                          color: const Color(0xFF89B4FA),
                        ),
                      ),
                      SizedBox(height: 0.5.h),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4.0),
                        child: LinearProgressIndicator(
                          value: totalTests > 0
                              ? completedTests / totalTests
                              : 0,
                          backgroundColor: const Color(0xFF313244),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFF89B4FA),
                          ),
                          minHeight: 6,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 1.5.h),
          ],
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: isRunningAll ? null : onRunAll,
                  icon: isRunningAll
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.play_circle_filled, size: 16),
                  label: Text(
                    isRunningAll ? 'Running...' : 'Run All Tests',
                    style: GoogleFonts.inter(fontSize: 11.sp),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF89B4FA),
                    foregroundColor: const Color(0xFF1E1E2E),
                    padding: EdgeInsets.symmetric(vertical: 1.2.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onGenerateReport,
                  icon: const Icon(Icons.summarize, size: 16),
                  label: Text(
                    'Generate Report',
                    style: GoogleFonts.inter(fontSize: 11.sp),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFA6E3A1),
                    side: const BorderSide(color: Color(0xFFA6E3A1)),
                    padding: EdgeInsets.symmetric(vertical: 1.2.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Row(
            children: [
              const Icon(Icons.info_outline, size: 12, color: Colors.white38),
              SizedBox(width: 1.w),
              Expanded(
                child: Text(
                  'CI/CD integration active • GitHub Actions configured',
                  style: GoogleFonts.inter(
                    fontSize: 9.sp,
                    color: Colors.white38,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
