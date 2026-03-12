import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class LaunchRecommendationCardWidget extends StatelessWidget {
  final int score;
  final List<String> issues;
  final VoidCallback onExportReport;
  final VoidCallback onRunFullTest;
  const LaunchRecommendationCardWidget({
    super.key,
    required this.score,
    required this.issues,
    required this.onExportReport,
    required this.onRunFullTest,
  });

  Color get _bgColor {
    if (score >= 90) return const Color(0xFF10B981).withAlpha(26);
    if (score >= 75) return const Color(0xFFF59E0B).withAlpha(26);
    return const Color(0xFFEF4444).withAlpha(26);
  }

  Color get _borderColor {
    if (score >= 90) return const Color(0xFF10B981);
    if (score >= 75) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  String get _recommendation {
    if (score >= 90) return 'Ready for Production Launch';
    if (score >= 75) return 'Ready with Minor Issues';
    return 'Not Ready - Critical Issues';
  }

  IconData get _icon {
    if (score >= 90) return Icons.rocket_launch;
    if (score >= 75) return Icons.warning_amber;
    return Icons.block;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: _bgColor,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: _borderColor, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_icon, color: _borderColor, size: 24),
              SizedBox(width: 2.w),
              Expanded(
                child: Text(
                  _recommendation,
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                    color: _borderColor,
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                decoration: BoxDecoration(
                  color: _borderColor,
                  borderRadius: BorderRadius.circular(20.0),
                ),
                child: Text(
                  '$score/100',
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          if (issues.isNotEmpty) ...[
            SizedBox(height: 1.5.h),
            Text(
              score >= 90 ? 'Minor Notes:' : 'Issues to Resolve:',
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            SizedBox(height: 0.5.h),
            ...issues
                .take(5)
                .map(
                  (issue) => Padding(
                    padding: EdgeInsets.symmetric(vertical: 0.3.h),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.arrow_right, size: 16, color: _borderColor),
                        Expanded(
                          child: Text(
                            issue,
                            style: TextStyle(
                              fontSize: 10.sp,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
          ],
          SizedBox(height: 2.h),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onExportReport,
                  icon: const Icon(Icons.download, size: 16),
                  label: Text(
                    'Export Report',
                    style: TextStyle(fontSize: 11.sp),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _borderColor,
                    side: BorderSide(color: _borderColor),
                    padding: EdgeInsets.symmetric(vertical: 1.h),
                  ),
                ),
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onRunFullTest,
                  icon: const Icon(Icons.play_circle, size: 16),
                  label: Text(
                    'Full Test Suite',
                    style: TextStyle(fontSize: 11.sp),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _borderColor,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 1.h),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
