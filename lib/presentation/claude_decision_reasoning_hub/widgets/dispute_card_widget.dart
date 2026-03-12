import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

class DisputeCardWidget extends StatelessWidget {
  final Map<String, dynamic> dispute;
  final bool isAnalyzing;
  final VoidCallback onAnalyze;

  const DisputeCardWidget({
    super.key,
    required this.dispute,
    required this.isAnalyzing,
    required this.onAnalyze,
  });

  Color _getTypeColor(String type) {
    switch (type) {
      case 'chargeback':
        return Colors.red.shade600;
      case 'refund_request':
        return Colors.orange.shade600;
      case 'policy_violation':
        return Colors.purple.shade600;
      default:
        return Colors.grey.shade600;
    }
  }

  @override
  Widget build(BuildContext context) {
    final disputeType = dispute['dispute_type']?.toString() ?? 'unknown';
    return Card(
      margin: EdgeInsets.symmetric(vertical: 1.h, horizontal: 0.5.w),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'ID: ${dispute['id']?.toString() ?? 'N/A'}',
                    style: GoogleFonts.inter(
                      fontSize: 11.sp,
                      color: Colors.grey.shade600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 2.w,
                    vertical: 0.5.h,
                  ),
                  decoration: BoxDecoration(
                    color: _getTypeColor(disputeType).withAlpha(26),
                    borderRadius: BorderRadius.circular(8.0),
                    border: Border.all(color: _getTypeColor(disputeType)),
                  ),
                  child: Text(
                    disputeType.replaceAll('_', ' ').toUpperCase(),
                    style: GoogleFonts.inter(
                      fontSize: 9.sp,
                      color: _getTypeColor(disputeType),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 1.h),
            Row(
              children: [
                Icon(Icons.person, size: 14.sp, color: Colors.grey.shade600),
                SizedBox(width: 1.w),
                Text(
                  dispute['user_name']?.toString() ?? 'Unknown User',
                  style: GoogleFonts.inter(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            SizedBox(height: 0.5.h),
            Text(
              dispute['evidence_summary']?.toString() ?? 'No evidence summary',
              style: GoogleFonts.inter(
                fontSize: 11.sp,
                color: Colors.grey.shade700,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 1.5.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: isAnalyzing ? null : onAnalyze,
                icon: isAnalyzing
                    ? SizedBox(
                        width: 14.sp,
                        height: 14.sp,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Icon(Icons.psychology, size: 14.sp),
                label: Text(
                  isAnalyzing ? 'Analyzing...' : 'Analyze with Claude',
                  style: GoogleFonts.inter(fontSize: 11.sp),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6B4EFF),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 1.h),
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
