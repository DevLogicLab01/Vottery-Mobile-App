import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:google_fonts/google_fonts.dart';

class ScreenErrorAnalysisWidget extends StatelessWidget {
  final List<Map<String, dynamic>> screenErrors;

  const ScreenErrorAnalysisWidget({super.key, required this.screenErrors});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 8.0,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.error_outline, color: Colors.orange[700], size: 20.sp),
              SizedBox(width: 2.w),
              Text(
                'Screen-Level Error Analysis',
                style: GoogleFonts.inter(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Text(
            'Error count per screen with drill-down capabilities',
            style: GoogleFonts.inter(fontSize: 11.sp, color: Colors.grey[600]),
          ),
          SizedBox(height: 2.h),
          ...screenErrors.map((error) => _buildErrorCard(error)),
        ],
      ),
    );
  }

  Widget _buildErrorCard(Map<String, dynamic> error) {
    final screenName = error['screen_name'] ?? 'Unknown';
    final errorCount = error['error_count'] ?? 0;
    final errorTypes = List<String>.from(error['error_types'] ?? []);
    final severity = error['severity'] ?? 'low';

    Color severityColor = Colors.green;
    if (severity == 'medium') severityColor = Colors.orange;
    if (severity == 'high') severityColor = Colors.red;

    return Container(
      margin: EdgeInsets.only(bottom: 1.5.h),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  screenName,
                  style: GoogleFonts.inter(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
              Row(
                children: [
                  Text(
                    errorCount.toString(),
                    style: GoogleFonts.inter(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: severityColor,
                    ),
                  ),
                  SizedBox(width: 1.w),
                  Text(
                    'errors',
                    style: GoogleFonts.inter(
                      fontSize: 11.sp,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (errorTypes.isNotEmpty) ...[
            SizedBox(height: 1.h),
            Wrap(
              spacing: 1.w,
              runSpacing: 0.5.h,
              children: errorTypes.map((type) {
                return Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 2.w,
                    vertical: 0.5.h,
                  ),
                  decoration: BoxDecoration(
                    color: severityColor.withAlpha(26),
                    borderRadius: BorderRadius.circular(4.0),
                    border: Border.all(color: severityColor.withAlpha(77)),
                  ),
                  child: Text(
                    type,
                    style: GoogleFonts.inter(
                      fontSize: 10.sp,
                      color: severityColor,
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
