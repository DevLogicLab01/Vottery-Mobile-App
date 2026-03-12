import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import 'package:timeago/timeago.dart' as timeago;

class SplitChangeHistoryWidget extends StatelessWidget {
  final List<Map<String, dynamic>> history;

  const SplitChangeHistoryWidget({super.key, required this.history});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.history, color: Colors.grey.shade700, size: 20.sp),
              SizedBox(width: 2.w),
              Text(
                'Split Change History',
                style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade900,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          if (history.isEmpty)
            Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 3.h),
                child: Text(
                  'No split changes yet',
                  style: GoogleFonts.inter(
                    fontSize: 11.sp,
                    color: Colors.grey.shade500,
                  ),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: history.length > 5 ? 5 : history.length,
              separatorBuilder: (context, index) =>
                  Divider(height: 2.h, color: Colors.grey.shade200),
              itemBuilder: (context, index) {
                final change = history[index];
                return _buildHistoryItem(change);
              },
            ),
          if (history.length > 5) ...[
            SizedBox(height: 1.h),
            Center(
              child: TextButton(
                onPressed: () {
                  // TODO: Show full history
                },
                child: Text(
                  'View All History',
                  style: GoogleFonts.inter(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue.shade700,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHistoryItem(Map<String, dynamic> change) {
    final previousCreator = change['previous_creator_percentage'] ?? 0.0;
    final newCreator = change['new_creator_percentage'] ?? 0.0;
    final changedAt = change['changed_at'] != null
        ? DateTime.parse(change['changed_at'])
        : DateTime.now();
    final effectiveDate = change['effective_date'] != null
        ? DateTime.parse(change['effective_date'])
        : DateTime.now();

    final isIncrease = newCreator > previousCreator;
    final changeIcon = isIncrease ? Icons.trending_up : Icons.trending_down;
    final changeColor = isIncrease ? Colors.green : Colors.red;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 1.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(1.5.w),
            decoration: BoxDecoration(
              color: changeColor.withAlpha(26),
              shape: BoxShape.circle,
            ),
            child: Icon(changeIcon, color: changeColor, size: 16.sp),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '${previousCreator.toStringAsFixed(0)}%',
                      style: GoogleFonts.inter(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                    SizedBox(width: 2.w),
                    Icon(
                      Icons.arrow_forward,
                      size: 12.sp,
                      color: Colors.grey.shade500,
                    ),
                    SizedBox(width: 2.w),
                    Text(
                      '${newCreator.toStringAsFixed(0)}%',
                      style: GoogleFonts.inter(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w700,
                        color: changeColor,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 0.5.h),
                if (change['change_reason'] != null)
                  Text(
                    change['change_reason'],
                    style: GoogleFonts.inter(
                      fontSize: 10.sp,
                      color: Colors.grey.shade600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                SizedBox(height: 0.5.h),
                Row(
                  children: [
                    Text(
                      'Changed ${timeago.format(changedAt)}',
                      style: GoogleFonts.inter(
                        fontSize: 9.sp,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    if (effectiveDate.isAfter(DateTime.now())) ...[
                      SizedBox(width: 2.w),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 1.5.w,
                          vertical: 0.3.h,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Effective ${_formatDate(effectiveDate)}',
                          style: GoogleFonts.inter(
                            fontSize: 8.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.orange.shade900,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }
}
