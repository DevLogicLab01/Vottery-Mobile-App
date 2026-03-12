import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

class ReasoningChainVisualizationWidget extends StatelessWidget {
  final List<Map<String, dynamic>> reasoningChain;
  final String title;

  const ReasoningChainVisualizationWidget({
    super.key,
    required this.reasoningChain,
    this.title = 'Reasoning Chain',
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.account_tree,
              color: const Color(0xFF6B4EFF),
              size: 16.sp,
            ),
            SizedBox(width: 2.w),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 14.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        SizedBox(height: 1.h),
        ...reasoningChain.asMap().entries.map((entry) {
          final index = entry.key;
          final step = entry.value;
          final confidence =
              (step['confidence'] as num? ?? (step['severity'] != null ? 0 : 80))
                  .toInt();
          final isLast = index == reasoningChain.length - 1;
          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: const Color(0xFF6B4EFF),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: GoogleFonts.inter(
                            fontSize: 11.sp,
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    if (!isLast)
                      Expanded(
                        child: Container(width: 2, color: Colors.grey.shade300),
                      ),
                  ],
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: isLast ? 0 : 2.h),
                    child: Container(
                      padding: EdgeInsets.all(2.w),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8.0),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  step['title']?.toString() ??
                                      'Step ${index + 1}',
                                  style: GoogleFonts.inter(
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              if (confidence > 0)
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 1.5.w,
                                    vertical: 0.2.h,
                                  ),
                                  decoration: BoxDecoration(
                                    color: confidence > 70
                                        ? Colors.green.shade100
                                        : confidence > 50
                                        ? Colors.orange.shade100
                                        : Colors.red.shade100,
                                    borderRadius: BorderRadius.circular(4.0),
                                  ),
                                  child: Text(
                                    '$confidence%',
                                    style: GoogleFonts.inter(
                                      fontSize: 10.sp,
                                      color: confidence > 70
                                          ? Colors.green.shade700
                                          : confidence > 50
                                          ? Colors.orange.shade700
                                          : Colors.red.shade700,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          SizedBox(height: 0.5.h),
                          Text(
                            step['finding']?.toString() ??
                                step['description']?.toString() ??
                                '',
                            style: GoogleFonts.inter(
                              fontSize: 11.sp,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}