import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import '../../../theme/app_theme.dart';

class ClaudeMetricsPanelWidget extends StatelessWidget {
  final double avgLatency;
  final double p95Latency;
  final double p99Latency;
  final double dailyCost;
  final double monthlyCost;
  final double projectedAnnualCost;
  final int totalApiCalls;
  final double successRate;
  final double errorRate;
  final List<Map<String, dynamic>> costTrend;

  const ClaudeMetricsPanelWidget({
    super.key,
    required this.avgLatency,
    required this.p95Latency,
    required this.p99Latency,
    required this.dailyCost,
    required this.monthlyCost,
    required this.projectedAnnualCost,
    required this.totalApiCalls,
    required this.successRate,
    required this.errorRate,
    required this.costTrend,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Latency Metrics',
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              Expanded(
                child: _buildLatencyGauge('Avg', avgLatency, 500, Colors.green),
              ),
              Expanded(
                child: _buildLatencyGauge(
                  'P95',
                  p95Latency,
                  1000,
                  Colors.orange,
                ),
              ),
              Expanded(
                child: _buildLatencyGauge('P99', p99Latency, 2000, Colors.red),
              ),
            ],
          ),
          SizedBox(height: 3.h),
          Text(
            'Cost Tracking',
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 1.h),
          Row(
            children: [
              Expanded(
                child: _buildCostCard(
                  'Daily',
                  '\$${dailyCost.toStringAsFixed(2)}',
                  Colors.blue,
                ),
              ),
              Expanded(
                child: _buildCostCard(
                  'Monthly',
                  '\$${monthlyCost.toStringAsFixed(2)}',
                  Colors.purple,
                ),
              ),
              Expanded(
                child: _buildCostCard(
                  'Annual Est.',
                  '\$${projectedAnnualCost.toStringAsFixed(0)}',
                  Colors.teal,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          if (costTrend.isNotEmpty) _buildCostTrendChart(),
          SizedBox(height: 2.h),
          Text(
            'API Call Volume',
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 1.h),
          Row(
            children: [
              Expanded(
                child: _buildVolumeCard(
                  'Total Calls',
                  totalApiCalls.toString(),
                  Icons.api,
                  Colors.blue,
                ),
              ),
              Expanded(
                child: _buildVolumeCard(
                  'Success Rate',
                  '${successRate.toStringAsFixed(1)}%',
                  Icons.check_circle,
                  Colors.green,
                ),
              ),
              Expanded(
                child: _buildVolumeCard(
                  'Error Rate',
                  '${errorRate.toStringAsFixed(1)}%',
                  Icons.error_outline,
                  errorRate < 5 ? Colors.orange : Colors.red,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLatencyGauge(
    String label,
    double value,
    double max,
    Color color,
  ) {
    final pct = (value / max).clamp(0.0, 1.0);
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 1.w),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: color.withAlpha(15),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 1.h),
          SizedBox(
            width: 15.w,
            height: 15.w,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: pct,
                  backgroundColor: Colors.grey.withAlpha(50),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  strokeWidth: 6,
                ),
                Text(
                  '${value.toStringAsFixed(0)}ms',
                  style: GoogleFonts.inter(
                    fontSize: 9.sp,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCostCard(String label, String value, Color color) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 1.w),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: color.withAlpha(15),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 9.sp,
              color: AppTheme.textSecondaryLight,
            ),
          ),
          SizedBox(height: 0.5.h),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 12.sp,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVolumeCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 1.w),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: color.withAlpha(15),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 5.w),
          SizedBox(height: 0.5.h),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 12.sp,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 9.sp,
              color: AppTheme.textSecondaryLight,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCostTrendChart() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Cost Trend (7 days)',
          style: GoogleFonts.inter(
            fontSize: 12.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 1.h),
        SizedBox(
          height: 15.h,
          child: LineChart(
            LineChartData(
              lineBarsData: [
                LineChartBarData(
                  spots: costTrend.asMap().entries.map((e) {
                    final cost = (e.value['cost'] ?? 0.0).toDouble();
                    return FlSpot(e.key.toDouble(), cost);
                  }).toList(),
                  isCurved: true,
                  color: Colors.blue,
                  barWidth: 2,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    color: Colors.blue.withAlpha(30),
                  ),
                ),
              ],
              titlesData: FlTitlesData(
                bottomTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 35,
                    getTitlesWidget: (value, meta) => Text(
                      '\$${value.toStringAsFixed(2)}',
                      style: TextStyle(fontSize: 7.sp),
                    ),
                  ),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
            ),
          ),
        ),
      ],
    );
  }
}
