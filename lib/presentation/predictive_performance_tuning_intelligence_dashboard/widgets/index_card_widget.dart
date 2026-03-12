import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import '../../../services/predictive_performance_tuning_service.dart';

class IndexCard extends StatefulWidget {
  final IndexRecommendation index;
  final Future<bool> Function(IndexRecommendation) onApply;

  const IndexCard({super.key, required this.index, required this.onApply});

  @override
  State<IndexCard> createState() => _IndexCardState();
}

class _IndexCardState extends State<IndexCard> {
  bool _isApplying = false;

  @override
  Widget build(BuildContext context) {
    final idx = widget.index;
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
                Icon(Icons.storage, color: Colors.teal.shade600, size: 18),
                SizedBox(width: 2.w),
                Expanded(
                  child: Text(
                    '${idx.tableName}.${idx.columnName}',
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (idx.isApplied)
                  Icon(
                    Icons.check_circle,
                    color: Colors.green.shade600,
                    size: 18,
                  ),
              ],
            ),
            SizedBox(height: 1.h),
            GestureDetector(
              onTap: () {
                Clipboard.setData(
                  ClipboardData(text: idx.createIndexStatement),
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Copied to clipboard'),
                    duration: Duration(seconds: 1),
                  ),
                );
              },
              child: Container(
                padding: EdgeInsets.all(2.w),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        idx.createIndexStatement,
                        style: TextStyle(
                          fontSize: 10.sp,
                          fontFamily: 'monospace',
                          color: Colors.teal.shade800,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Icon(Icons.copy, size: 14, color: Colors.grey.shade500),
                  ],
                ),
              ),
            ),
            SizedBox(height: 1.h),
            Row(
              children: [
                Icon(Icons.flash_on, size: 14, color: Colors.amber.shade700),
                SizedBox(width: 1.w),
                Expanded(
                  child: Text(
                    idx.expectedImpact,
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: Colors.amber.shade800,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            if (idx.affectedQueries.isNotEmpty) ...[
              SizedBox(height: 0.5.h),
              Wrap(
                spacing: 1.w,
                children: idx.affectedQueries
                    .take(3)
                    .map(
                      (q) => Chip(
                        label: Text(q, style: TextStyle(fontSize: 9.sp)),
                        backgroundColor: Colors.teal.shade50,
                        padding: EdgeInsets.zero,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    )
                    .toList(),
              ),
            ],
            SizedBox(height: 1.h),
            if (!idx.isApplied)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isApplying
                      ? null
                      : () async {
                          setState(() => _isApplying = true);
                          await widget.onApply(idx);
                          if (mounted) {
                            setState(() => _isApplying = false);
                          }
                        },
                  icon: _isApplying
                      ? SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.play_arrow, size: 16),
                  label: Text(
                    'Create Index',
                    style: TextStyle(fontSize: 11.sp),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal.shade600,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
