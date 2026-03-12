import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

class TestFileCardWidget extends StatelessWidget {
  final String fileName;
  final String description;
  final String status;
  final List<String> assertions;
  final bool isRunning;
  final VoidCallback onRunTest;
  final Color statusColor;

  const TestFileCardWidget({
    super.key,
    required this.fileName,
    required this.description,
    required this.status,
    required this.assertions,
    required this.isRunning,
    required this.onRunTest,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 1.5.h),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2E),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: statusColor.withAlpha(102)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withAlpha(38),
                  borderRadius: BorderRadius.circular(6.0),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isRunning)
                      SizedBox(
                        width: 10,
                        height: 10,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            statusColor,
                          ),
                        ),
                      )
                    else
                      Icon(
                        status == 'passing'
                            ? Icons.check_circle
                            : status == 'failing'
                            ? Icons.cancel
                            : Icons.hourglass_empty,
                        color: statusColor,
                        size: 12,
                      ),
                    const SizedBox(width: 4),
                    Text(
                      isRunning ? 'RUNNING' : status.toUpperCase(),
                      style: GoogleFonts.inter(
                        fontSize: 9.sp,
                        fontWeight: FontWeight.w700,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: isRunning ? null : onRunTest,
                icon: Icon(
                  Icons.play_arrow,
                  size: 14,
                  color: isRunning ? Colors.white38 : const Color(0xFF89B4FA),
                ),
                label: Text(
                  'Run',
                  style: GoogleFonts.inter(
                    fontSize: 10.sp,
                    color: isRunning ? Colors.white38 : const Color(0xFF89B4FA),
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  minimumSize: Size.zero,
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Text(
            fileName,
            style: GoogleFonts.inter(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 0.5.h),
          Text(
            description,
            style: GoogleFonts.inter(fontSize: 10.sp, color: Colors.white60),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (assertions.isNotEmpty) ...[
            SizedBox(height: 1.h),
            Wrap(
              spacing: 1.w,
              runSpacing: 0.5.h,
              children: assertions.take(3).map((assertion) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF313244),
                    borderRadius: BorderRadius.circular(4.0),
                  ),
                  child: Text(
                    assertion,
                    style: GoogleFonts.inter(
                      fontSize: 9.sp,
                      color: Colors.white54,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}
