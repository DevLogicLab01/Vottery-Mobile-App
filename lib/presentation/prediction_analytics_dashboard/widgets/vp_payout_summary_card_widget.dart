import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

class VpPayoutSummaryCardWidget extends StatelessWidget {
  final int totalVpDistributed;
  final int currentMonthVp;
  final int lastMonthVp;
  final List<Map<String, dynamic>> topEarners;

  const VpPayoutSummaryCardWidget({
    super.key,
    required this.totalVpDistributed,
    required this.currentMonthVp,
    required this.lastMonthVp,
    required this.topEarners,
  });

  @override
  Widget build(BuildContext context) {
    final trend = lastMonthVp > 0
        ? ((currentMonthVp - lastMonthVp) / lastMonthVp * 100)
        : 0.0;
    final isPositive = trend >= 0;

    return Card(
      color: const Color(0xFF1E1E2E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.monetization_on,
                  color: Color(0xFFFFD700),
                  size: 20,
                ),
                SizedBox(width: 2.w),
                Text(
                  'VP Payout Summary',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            SizedBox(height: 2.h),
            Container(
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6C63FF), Color(0xFF3F3D56)],
                ),
                borderRadius: BorderRadius.circular(10.0),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total VP Distributed',
                          style: GoogleFonts.inter(
                            color: Colors.white70,
                            fontSize: 11.sp,
                          ),
                        ),
                        Text(
                          _formatVP(totalVpDistributed),
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'This Month',
                        style: GoogleFonts.inter(
                          color: Colors.white70,
                          fontSize: 10.sp,
                        ),
                      ),
                      Text(
                        _formatVP(currentMonthVp),
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Row(
                        children: [
                          Icon(
                            isPositive
                                ? Icons.arrow_upward
                                : Icons.arrow_downward,
                            color: isPositive
                                ? const Color(0xFF4CAF50)
                                : const Color(0xFFFF6B6B),
                            size: 14,
                          ),
                          Text(
                            '${trend.abs().toStringAsFixed(1)}%',
                            style: GoogleFonts.inter(
                              color: isPositive
                                  ? const Color(0xFF4CAF50)
                                  : const Color(0xFFFF6B6B),
                              fontSize: 11.sp,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              'Top VP Earners',
              style: GoogleFonts.inter(
                color: Colors.white70,
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 1.h),
            if (topEarners.isEmpty)
              Text(
                'No earner data',
                style: GoogleFonts.inter(
                  color: Colors.white38,
                  fontSize: 11.sp,
                ),
              )
            else
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(
                    const Color(0xFF2A2A3E),
                  ),
                  columnSpacing: 3.w,
                  columns: [
                    DataColumn(
                      label: Text(
                        'User',
                        style: GoogleFonts.inter(
                          color: Colors.white70,
                          fontSize: 11.sp,
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Predictions',
                        style: GoogleFonts.inter(
                          color: Colors.white70,
                          fontSize: 11.sp,
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Accuracy',
                        style: GoogleFonts.inter(
                          color: Colors.white70,
                          fontSize: 11.sp,
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'VP Earned',
                        style: GoogleFonts.inter(
                          color: Colors.white70,
                          fontSize: 11.sp,
                        ),
                      ),
                    ),
                  ],
                  rows: topEarners
                      .take(10)
                      .map(
                        (earner) => DataRow(
                          cells: [
                            DataCell(
                              Text(
                                earner['user_name']?.toString() ?? 'Anonymous',
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontSize: 11.sp,
                                ),
                              ),
                            ),
                            DataCell(
                              Text(
                                '${earner['predictions_made'] ?? 0}',
                                style: GoogleFonts.inter(
                                  color: Colors.white70,
                                  fontSize: 11.sp,
                                ),
                              ),
                            ),
                            DataCell(
                              Text(
                                ((earner['accuracy_score'] as num?) ?? 0).toStringAsFixed(2),
                                style: GoogleFonts.inter(
                                  color: const Color(0xFF4CAF50),
                                  fontSize: 11.sp,
                                ),
                              ),
                            ),
                            DataCell(
                              Text(
                                _formatVP(
                                  (earner['vp_earned'] as num?)?.toInt() ?? 0,
                                ),
                                style: GoogleFonts.inter(
                                  color: const Color(0xFFFFD700),
                                  fontSize: 11.sp,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                      .toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatVP(int vp) {
    if (vp >= 1000000) return '${(vp / 1000000).toStringAsFixed(1)}M VP';
    if (vp >= 1000) return '${(vp / 1000).toStringAsFixed(1)}K VP';
    return '$vp VP';
  }
}
