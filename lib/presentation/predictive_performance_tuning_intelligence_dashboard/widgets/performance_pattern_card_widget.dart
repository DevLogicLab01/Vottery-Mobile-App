import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../services/predictive_performance_tuning_service.dart';

class PerformancePatternCard extends StatelessWidget {
  final PerformancePattern pattern;

  const PerformancePatternCard({super.key, required this.pattern});

  @override
  Widget build(BuildContext context) {
    final severityColor = _severityColor(pattern.severity);
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
        side: BorderSide(color: severityColor.withAlpha(77), width: 1),
      ),
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 2.w,
                    vertical: 0.5.h,
                  ),
                  decoration: BoxDecoration(
                    color: severityColor.withAlpha(38),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Text(
                    pattern.severity.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.bold,
                      color: severityColor,
                    ),
                  ),
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: Text(
                    'Performance Pattern',
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(Icons.trending_up, color: severityColor, size: 18),
              ],
            ),
            SizedBox(height: 1.h),
            Text(
              pattern.description,
              style: TextStyle(fontSize: 12.sp, color: Colors.grey.shade800),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 1.h),
            Row(
              children: [
                Icon(Icons.search, size: 14, color: Colors.blue.shade600),
                SizedBox(width: 1.w),
                Expanded(
                  child: Text(
                    'Root Cause: ${pattern.rootCause}',
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: Colors.blue.shade700,
                      fontStyle: FontStyle.italic,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            if (pattern.metrics.isNotEmpty) ...[
              SizedBox(height: 1.h),
              Wrap(
                spacing: 2.w,
                runSpacing: 0.5.h,
                children: pattern.metrics.entries
                    .take(3)
                    .map(
                      (e) => Chip(
                        label: Text(
                          '${e.key}: ${e.value}',
                          style: TextStyle(fontSize: 10.sp),
                        ),
                        backgroundColor: Colors.grey.shade100,
                        padding: EdgeInsets.zero,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    )
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _severityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'high':
        return Colors.red.shade600;
      case 'medium':
        return Colors.orange.shade600;
      default:
        return Colors.green.shade600;
    }
  }
}
