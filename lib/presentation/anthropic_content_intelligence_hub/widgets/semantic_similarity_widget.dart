import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:google_fonts/google_fonts.dart';

class SemanticSimilarityWidget extends StatelessWidget {
  final List<Map<String, dynamic>> similarities;

  const SemanticSimilarityWidget({super.key, required this.similarities});

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
              Icon(Icons.compare_arrows, color: Colors.teal[700], size: 18.sp),
              SizedBox(width: 2.w),
              Text(
                'Semantic Similarity Recommendations',
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
            'Elections with >0.8 cosine similarity',
            style: GoogleFonts.inter(fontSize: 11.sp, color: Colors.grey[600]),
          ),
          SizedBox(height: 1.5.h),
          if (similarities.isEmpty)
            Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 2.h),
                child: Text(
                  'No similar elections found',
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    color: Colors.grey[500],
                  ),
                ),
              ),
            )
          else
            ...similarities.take(6).map((similarity) {
              final electionA =
                  similarity['election_a'] as Map<String, dynamic>?;
              final electionB =
                  similarity['election_b'] as Map<String, dynamic>?;
              final score =
                  (similarity['similarity_score'] as num?)?.toDouble() ?? 0.0;

              return Container(
                margin: EdgeInsets.only(bottom: 1.5.h),
                padding: EdgeInsets.all(2.5.w),
                decoration: BoxDecoration(
                  color: Colors.teal[50],
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(color: Colors.teal[200]!),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: EdgeInsets.all(2.w),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(6.0),
                            ),
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
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 2.w),
                          child: Column(
                            children: [
                              Icon(
                                Icons.compare_arrows,
                                color: Colors.teal[700],
                                size: 16.sp,
                              ),
                              Text(
                                '${(score * 100).toStringAsFixed(0)}%',
                                style: GoogleFonts.inter(
                                  fontSize: 11.sp,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.teal[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Container(
                            padding: EdgeInsets.all(2.w),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(6.0),
                            ),
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
