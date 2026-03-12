import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import 'package:fl_chart/fl_chart.dart';

class DemographicAnalysisPanelWidget extends StatelessWidget {
  final List<BarChartGroupData> ageDistribution;
  final List<PieChartSectionData> genderDistribution;

  const DemographicAnalysisPanelWidget({
    super.key,
    required this.ageDistribution,
    required this.genderDistribution,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(3.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Age Distribution'),
          SizedBox(height: 1.h),
          _buildAgeChart(),
          SizedBox(height: 2.h),
          _buildSectionTitle('Gender Distribution'),
          SizedBox(height: 1.h),
          _buildGenderChart(),
          SizedBox(height: 2.h),
          _buildSectionTitle('Engagement Metrics'),
          SizedBox(height: 1.h),
          _buildEngagementMetrics(),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.inter(
        fontSize: 14.sp,
        fontWeight: FontWeight.w700,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildAgeChart() {
    final ageLabels = ['18-24', '25-34', '35-44', '45-54', '55-64', '65+'];
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: SizedBox(
        height: 20.h,
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              getDrawingHorizontalLine: (v) =>
                  FlLine(color: Colors.grey.shade200, strokeWidth: 1),
            ),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 30,
                  getTitlesWidget: (v, meta) => Text(
                    v.toInt().toString(),
                    style: GoogleFonts.inter(fontSize: 9.sp),
                  ),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (v, meta) => Text(
                    ageLabels[v.toInt().clamp(0, ageLabels.length - 1)],
                    style: GoogleFonts.inter(fontSize: 9.sp),
                  ),
                ),
              ),
              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
            ),
            borderData: FlBorderData(show: false),
            barGroups: ageDistribution,
          ),
        ),
      ),
    );
  }

  Widget _buildGenderChart() {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          SizedBox(
            height: 15.h,
            width: 35.w,
            child: PieChart(
              PieChartData(
                sections: genderDistribution,
                sectionsSpace: 2,
                centerSpaceRadius: 30,
              ),
            ),
          ),
          SizedBox(width: 4.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLegendItem('Male', const Color(0xFF6C63FF), '48%'),
              SizedBox(height: 1.h),
              _buildLegendItem('Female', const Color(0xFF4CAF50), '45%'),
              SizedBox(height: 1.h),
              _buildLegendItem('Other', const Color(0xFFFF9800), '7%'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color, String pct) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3.0),
          ),
        ),
        SizedBox(width: 2.w),
        Text(
          '$label ($pct)',
          style: GoogleFonts.inter(fontSize: 12.sp, color: Colors.black87),
        ),
      ],
    );
  }

  Widget _buildEngagementMetrics() {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          _buildMetricRow('Repeat Voters', '3,420', const Color(0xFF6C63FF)),
          _buildMetricRow(
            'First-Time Voters',
            '11,280',
            const Color(0xFF4CAF50),
          ),
          _buildMetricRow('Avg Votes/User', '1.8', const Color(0xFFFF9800)),
        ],
      ),
    );
  }

  Widget _buildMetricRow(String label, String value, Color color) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 0.8.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12.sp,
              color: Colors.grey.shade700,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 13.sp,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
