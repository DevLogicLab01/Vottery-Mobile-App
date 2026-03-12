import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

class ThresholdStatusCardWidget extends StatelessWidget {
  final String metricName;
  final double currentValue;
  final double threshold;
  final String unit;
  final bool isBreached;
  final int consecutiveBreaches;

  const ThresholdStatusCardWidget({
    super.key,
    required this.metricName,
    required this.currentValue,
    required this.threshold,
    required this.unit,
    required this.isBreached,
    required this.consecutiveBreaches,
  });

  @override
  Widget build(BuildContext context) {
    final color = isBreached ? Colors.red : Colors.green;
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
        side: BorderSide(color: color.withAlpha(77), width: 1),
      ),
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    metricName,
                    style: GoogleFonts.inter(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: color.withAlpha(26),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Text(
                    isBreached ? 'BREACH' : 'OK',
                    style: GoogleFonts.inter(
                      fontSize: 9.sp,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 1.h),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Current',
                        style: GoogleFonts.inter(
                          fontSize: 10.sp,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        '${currentValue.toStringAsFixed(1)}$unit',
                        style: GoogleFonts.inter(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w800,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Threshold',
                        style: GoogleFonts.inter(
                          fontSize: 10.sp,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        '$threshold$unit',
                        style: GoogleFonts.inter(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Breaches',
                        style: GoogleFonts.inter(
                          fontSize: 10.sp,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        '$consecutiveBreaches',
                        style: GoogleFonts.inter(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: consecutiveBreaches > 0
                              ? Colors.orange
                              : Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 1.h),
            ClipRRect(
              borderRadius: BorderRadius.circular(4.0),
              child: LinearProgressIndicator(
                value: (currentValue / (threshold * 1.5)).clamp(0.0, 1.0),
                backgroundColor: Colors.grey[200],
                color: color,
                minHeight: 6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
