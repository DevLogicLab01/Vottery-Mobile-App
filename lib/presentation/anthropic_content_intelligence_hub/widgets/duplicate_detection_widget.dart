import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:google_fonts/google_fonts.dart';

class DuplicateDetectionWidget extends StatelessWidget {
  final List<Map<String, dynamic>> duplicates;

  const DuplicateDetectionWidget({super.key, required this.duplicates});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
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
              Icon(Icons.content_copy, color: Colors.red[700], size: 18.sp),
              SizedBox(width: 2.w),
              Text(
                'Duplicate Content Detection',
                style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Text(
            'Elections flagged with >90% semantic similarity',
            style: GoogleFonts.inter(fontSize: 11.sp, color: Colors.grey[600]),
          ),
          SizedBox(height: 1.5.h),
          if (duplicates.isEmpty)
            Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 2.h),
                child: Column(
                  children: [
                    Icon(Icons.verified, color: Colors.green, size: 24.sp),
                    SizedBox(height: 1.h),
                    Text(
                      'No duplicate content detected',
                      style: GoogleFonts.inter(
                        fontSize: 12.sp,
                        color: Colors.green[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ...duplicates.take(5).map((duplicate) {
              final electionA =
                  duplicate['election_a'] as Map<String, dynamic>?;
              final electionB =
                  duplicate['election_b'] as Map<String, dynamic>?;
              final score =
                  (duplicate['similarity_score'] as num?)?.toDouble() ?? 0.0;

              return Container(
                margin: EdgeInsets.only(bottom: 1.5.h),
                padding: EdgeInsets.all(2.5.w),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(color: Colors.red[300]!, width: 1.5),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.warning,
                          color: Colors.red[700],
                          size: 16.sp,
                        ),
                        SizedBox(width: 2.w),
                        Expanded(
                          child: Text(
                            'Potential Spam Detected',
                            style: GoogleFonts.inter(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.red[700],
                            ),
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 2.w,
                            vertical: 0.5.h,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red[700],
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          child: Text(
                            '${(score * 100).toStringAsFixed(0)}% Match',
                            style: GoogleFonts.inter(
                              fontSize: 10.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 1.h),
                    Container(
                      padding: EdgeInsets.all(2.w),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6.0),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                '1️⃣ ',
                                style: GoogleFonts.inter(fontSize: 11.sp),
                              ),
                              Expanded(
                                child: Text(
                                  electionA?['title'] ?? 'Election A',
                                  style: GoogleFonts.inter(
                                    fontSize: 11.sp,
                                    color: Colors.grey[800],
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 0.5.h),
                          Row(
                            children: [
                              Text(
                                '2️⃣ ',
                                style: GoogleFonts.inter(fontSize: 11.sp),
                              ),
                              Expanded(
                                child: Text(
                                  electionB?['title'] ?? 'Election B',
                                  style: GoogleFonts.inter(
                                    fontSize: 11.sp,
                                    color: Colors.grey[800],
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 1.h),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {},
                            icon: Icon(Icons.visibility, size: 12.sp),
                            label: Text(
                              'Review',
                              style: GoogleFonts.inter(fontSize: 11.sp),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 1.h),
                            ),
                          ),
                        ),
                        SizedBox(width: 2.w),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {},
                            icon: Icon(Icons.delete, size: 12.sp),
                            label: Text(
                              'Remove',
                              style: GoogleFonts.inter(fontSize: 11.sp),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 1.h),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}
