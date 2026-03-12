import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

class FraudCaseCardWidget extends StatelessWidget {
  final Map<String, dynamic> fraudCase;
  final bool isInvestigating;
  final VoidCallback onInvestigate;

  const FraudCaseCardWidget({
    super.key,
    required this.fraudCase,
    required this.isInvestigating,
    required this.onInvestigate,
  });

  @override
  Widget build(BuildContext context) {
    final indicators = List<String>.from(
      fraudCase['fraud_indicators'] as List? ?? [],
    );
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
                    'Case: ${fraudCase['id']?.toString() ?? 'N/A'}',
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
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8.0),
                    border: Border.all(color: Colors.red.shade300),
                  ),
                  child: Text(
                    'SUSPICIOUS',
                    style: GoogleFonts.inter(
                      fontSize: 9.sp,
                      color: Colors.red.shade700,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 1.h),
            Row(
              children: [
                Icon(
                  Icons.person_outline,
                  size: 14.sp,
                  color: Colors.grey.shade600,
                ),
                SizedBox(width: 1.w),
                Text(
                  'User: ${fraudCase['user_id']?.toString() ?? 'Unknown'}',
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            SizedBox(height: 1.h),
            Wrap(
              spacing: 1.w,
              runSpacing: 0.5.h,
              children: indicators
                  .map(
                    (indicator) => Chip(
                      label: Text(
                        indicator.replaceAll('_', ' '),
                        style: GoogleFonts.inter(fontSize: 9.sp),
                      ),
                      backgroundColor: Colors.orange.shade100,
                      side: BorderSide(color: Colors.orange.shade300),
                      padding: EdgeInsets.zero,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  )
                  .toList(),
            ),
            SizedBox(height: 0.5.h),
            Row(
              children: [
                _buildIndicatorBadge(
                  'Velocity',
                  fraudCase['velocity_anomaly'] == true,
                ),
                SizedBox(width: 2.w),
                _buildIndicatorBadge(
                  'Dup IP',
                  fraudCase['duplicate_ip'] == true,
                ),
                SizedBox(width: 2.w),
                _buildIndicatorBadge(
                  'Suspicious Pay',
                  fraudCase['suspicious_payment'] == true,
                ),
              ],
            ),
            SizedBox(height: 1.5.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: isInvestigating ? null : onInvestigate,
                icon: isInvestigating
                    ? SizedBox(
                        width: 14.sp,
                        height: 14.sp,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Icon(Icons.search, size: 14.sp),
                label: Text(
                  isInvestigating
                      ? 'Investigating...'
                      : 'Investigate with Claude',
                  style: GoogleFonts.inter(fontSize: 11.sp),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade700,
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

  Widget _buildIndicatorBadge(String label, bool active) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 1.5.w, vertical: 0.3.h),
      decoration: BoxDecoration(
        color: active ? Colors.red.shade100 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(4.0),
        border: Border.all(
          color: active ? Colors.red.shade400 : Colors.grey.shade300,
        ),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 9.sp,
          color: active ? Colors.red.shade700 : Colors.grey.shade500,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
