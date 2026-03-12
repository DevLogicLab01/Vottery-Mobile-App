import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../services/predictive_performance_tuning_service.dart';

class RecommendationCard extends StatefulWidget {
  final QueryRecommendation recommendation;
  final Future<bool> Function(QueryRecommendation) onApply;

  const RecommendationCard({
    super.key,
    required this.recommendation,
    required this.onApply,
  });

  @override
  State<RecommendationCard> createState() => _RecommendationCardState();
}

class _RecommendationCardState extends State<RecommendationCard> {
  bool _isApplying = false;
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final rec = widget.recommendation;
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(
                  Icons.auto_fix_high,
                  color: Colors.purple.shade600,
                  size: 18,
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: Text(
                    rec.recommendationType,
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (rec.isApplied)
                  Chip(
                    label: Text(
                      'Applied',
                      style: TextStyle(fontSize: 10.sp, color: Colors.white),
                    ),
                    backgroundColor: Colors.green.shade600,
                    padding: EdgeInsets.zero,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
              ],
            ),
            SizedBox(height: 1.h),
            Container(
              padding: EdgeInsets.all(2.w),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Current Query',
                    style: TextStyle(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.red.shade700,
                    ),
                  ),
                  SizedBox(height: 0.5.h),
                  Text(
                    rec.currentQuery,
                    style: TextStyle(
                      fontSize: 10.sp,
                      fontFamily: 'monospace',
                      color: Colors.grey.shade800,
                    ),
                    maxLines: _expanded ? null : 2,
                    overflow: _expanded
                        ? TextOverflow.visible
                        : TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            SizedBox(height: 1.h),
            Container(
              padding: EdgeInsets.all(2.w),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Optimized Query',
                    style: TextStyle(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade700,
                    ),
                  ),
                  SizedBox(height: 0.5.h),
                  Text(
                    rec.optimizedQuery,
                    style: TextStyle(
                      fontSize: 10.sp,
                      fontFamily: 'monospace',
                      color: Colors.grey.shade800,
                    ),
                    maxLines: _expanded ? null : 2,
                    overflow: _expanded
                        ? TextOverflow.visible
                        : TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            SizedBox(height: 1.h),
            Row(
              children: [
                Icon(Icons.speed, size: 14, color: Colors.blue.shade600),
                SizedBox(width: 1.w),
                Text(
                  rec.expectedImprovement,
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: Colors.blue.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => setState(() => _expanded = !_expanded),
                  child: Text(
                    _expanded ? 'Less' : 'More',
                    style: TextStyle(fontSize: 11.sp),
                  ),
                ),
                if (!rec.isApplied)
                  ElevatedButton(
                    onPressed: _isApplying
                        ? null
                        : () async {
                            setState(() => _isApplying = true);
                            await widget.onApply(rec);
                            if (mounted) {
                              setState(() => _isApplying = false);
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple.shade600,
                      padding: EdgeInsets.symmetric(
                        horizontal: 3.w,
                        vertical: 0.8.h,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    child: _isApplying
                        ? SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            'Apply',
                            style: TextStyle(
                              fontSize: 11.sp,
                              color: Colors.white,
                            ),
                          ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
