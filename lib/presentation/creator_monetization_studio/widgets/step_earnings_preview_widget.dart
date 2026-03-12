import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import 'package:fl_chart/fl_chart.dart';

class StepEarningsPreviewWidget extends StatelessWidget {
  final double electionsPerMonth;
  final String selectedTier;
  final double projectedEarnings;
  final ValueChanged<double> onSliderChanged;

  const StepEarningsPreviewWidget({
    super.key,
    required this.electionsPerMonth,
    required this.selectedTier,
    required this.projectedEarnings,
    required this.onSliderChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Earnings Dashboard Preview',
            style: GoogleFonts.inter(
              fontSize: 18.sp,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 0.5.h),
          Text(
            'See your potential earnings',
            style: GoogleFonts.inter(
              fontSize: 12.sp,
              color: Colors.grey.shade600,
            ),
          ),
          SizedBox(height: 2.h),
          _buildProjectedEarningsCard(),
          SizedBox(height: 2.h),
          _buildProjectionCalculator(),
          SizedBox(height: 2.h),
          _buildRevenueStreamsChart(),
        ],
      ),
    );
  }

  Widget _buildProjectedEarningsCard() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6C63FF), Color(0xFF9C27B0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Projected Monthly Earnings',
            style: GoogleFonts.inter(
              fontSize: 12.sp,
              color: Colors.white.withAlpha(204),
            ),
          ),
          SizedBox(height: 0.5.h),
          Text(
            '\$${projectedEarnings.toStringAsFixed(0)}',
            style: GoogleFonts.inter(
              fontSize: 28.sp,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          Text(
            'Based on $selectedTier tier & ${electionsPerMonth.toInt()} elections/month',
            style: GoogleFonts.inter(
              fontSize: 11.sp,
              color: Colors.white.withAlpha(204),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectionCalculator() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Projection Calculator',
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 1.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Elections per month',
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  color: Colors.grey.shade700,
                ),
              ),
              Text(
                '${electionsPerMonth.toInt()}',
                style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF6C63FF),
                ),
              ),
            ],
          ),
          Slider(
            value: electionsPerMonth,
            min: 1,
            max: 30,
            divisions: 29,
            activeColor: const Color(0xFF6C63FF),
            onChanged: onSliderChanged,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Min: \$${(electionsPerMonth * 30).toStringAsFixed(0)}',
                style: GoogleFonts.inter(
                  fontSize: 11.sp,
                  color: Colors.grey.shade600,
                ),
              ),
              Text(
                'Max: \$${(projectedEarnings * 1.5).toStringAsFixed(0)}',
                style: GoogleFonts.inter(
                  fontSize: 11.sp,
                  color: const Color(0xFF4CAF50),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueStreamsChart() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Revenue Streams',
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 2.h),
          SizedBox(
            height: 15.h,
            child: PieChart(
              PieChartData(
                sections: [
                  PieChartSectionData(
                    value: 45,
                    color: const Color(0xFF6C63FF),
                    title: 'VP\n45%',
                    radius: 50,
                    titleStyle: GoogleFonts.inter(
                      fontSize: 9.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  PieChartSectionData(
                    value: 30,
                    color: const Color(0xFF4CAF50),
                    title: 'Elections\n30%',
                    radius: 50,
                    titleStyle: GoogleFonts.inter(
                      fontSize: 9.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  PieChartSectionData(
                    value: 15,
                    color: const Color(0xFFFF9800),
                    title: 'Sponsors\n15%',
                    radius: 50,
                    titleStyle: GoogleFonts.inter(
                      fontSize: 9.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  PieChartSectionData(
                    value: 10,
                    color: const Color(0xFFE91E63),
                    title: 'Market\n10%',
                    radius: 50,
                    titleStyle: GoogleFonts.inter(
                      fontSize: 9.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
                sectionsSpace: 2,
                centerSpaceRadius: 25,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
