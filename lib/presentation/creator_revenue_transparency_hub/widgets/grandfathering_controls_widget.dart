import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

class GrandfatheringControlsWidget extends StatelessWidget {
  final Map<String, dynamic> currentSplit;
  final List<Map<String, dynamic>> upcomingChanges;
  final Map<String, dynamic>? preferences;
  final Function(double) onOptIn;

  const GrandfatheringControlsWidget({
    super.key,
    required this.currentSplit,
    required this.upcomingChanges,
    this.preferences,
    required this.onOptIn,
  });

  @override
  Widget build(BuildContext context) {
    final currentPercentage = currentSplit['creator_percentage'] ?? 70.0;
    final nextChange = upcomingChanges.isNotEmpty
        ? upcomingChanges.first
        : null;
    final newPercentage =
        nextChange?['new_creator_percentage'] ?? currentPercentage;
    final effectiveDate = nextChange != null
        ? DateTime.parse(nextChange['effective_date'])
        : DateTime.now();

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Grandfathering Protection',
                  style: GoogleFonts.inter(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade900,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            SizedBox(height: 2.h),
            // Explanation
            Container(
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.blue.shade700,
                    size: 20.sp,
                  ),
                  SizedBox(width: 2.w),
                  Expanded(
                    child: Text(
                      'Grandfathering allows you to keep your current revenue split for 90 days after the change takes effect.',
                      style: GoogleFonts.inter(
                        fontSize: 11.sp,
                        color: Colors.blue.shade900,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 2.h),
            // Split Comparison
            Container(
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Current Split',
                            style: GoogleFonts.inter(
                              fontSize: 10.sp,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          SizedBox(height: 0.5.h),
                          Text(
                            '${currentPercentage.toStringAsFixed(0)}%',
                            style: GoogleFonts.inter(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.w700,
                              color: Colors.green.shade700,
                            ),
                          ),
                        ],
                      ),
                      Icon(
                        Icons.arrow_forward,
                        color: Colors.grey.shade400,
                        size: 24.sp,
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'New Split',
                            style: GoogleFonts.inter(
                              fontSize: 10.sp,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          SizedBox(height: 0.5.h),
                          Text(
                            '${newPercentage.toStringAsFixed(0)}%',
                            style: GoogleFonts.inter(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.w700,
                              color: newPercentage < currentPercentage
                                  ? Colors.red.shade700
                                  : Colors.green.shade700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 1.h),
                  Divider(color: Colors.grey.shade300),
                  SizedBox(height: 1.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Effective Date:',
                        style: GoogleFonts.inter(
                          fontSize: 10.sp,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      Text(
                        _formatDate(effectiveDate),
                        style: GoogleFonts.inter(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade900,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 2.h),
            // Protection Timeline
            Container(
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Protection Timeline',
                    style: GoogleFonts.inter(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.orange.shade900,
                    ),
                  ),
                  SizedBox(height: 1.h),
                  _buildTimelineItem(
                    'Today',
                    'Opt into grandfathering',
                    Icons.check_circle,
                    Colors.green,
                  ),
                  _buildTimelineItem(
                    _formatDate(effectiveDate),
                    'New split takes effect (you keep ${currentPercentage.toStringAsFixed(0)}%)',
                    Icons.shield,
                    Colors.orange,
                  ),
                  _buildTimelineItem(
                    _formatDate(effectiveDate.add(const Duration(days: 90))),
                    'Protection expires (switch to ${newPercentage.toStringAsFixed(0)}%)',
                    Icons.update,
                    Colors.blue,
                  ),
                ],
              ),
            ),
            SizedBox(height: 2.h),
            // Opt-In Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => onOptIn(currentPercentage),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.shade700,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 1.8.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Opt Into 90-Day Protection',
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              'You can opt out at any time to switch to the new split immediately.',
              style: GoogleFonts.inter(
                fontSize: 9.sp,
                color: Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineItem(
    String date,
    String description,
    IconData icon,
    Color color,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 1.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(1.5.w),
            decoration: BoxDecoration(
              color: color.withAlpha(26),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 16.sp),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  date,
                  style: GoogleFonts.inter(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade900,
                  ),
                ),
                SizedBox(height: 0.3.h),
                Text(
                  description,
                  style: GoogleFonts.inter(
                    fontSize: 10.sp,
                    color: Colors.grey.shade600,
                  ),
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
