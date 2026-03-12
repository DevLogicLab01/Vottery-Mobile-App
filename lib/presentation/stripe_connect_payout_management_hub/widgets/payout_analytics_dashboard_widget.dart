import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../services/payout_management_service.dart';
import '../../../theme/app_theme.dart';

class PayoutAnalyticsDashboardWidget extends StatefulWidget {
  const PayoutAnalyticsDashboardWidget({super.key});

  @override
  State<PayoutAnalyticsDashboardWidget> createState() =>
      _PayoutAnalyticsDashboardWidgetState();
}

class _PayoutAnalyticsDashboardWidgetState
    extends State<PayoutAnalyticsDashboardWidget> {
  final PayoutManagementService _payoutService =
      PayoutManagementService.instance;

  bool _isLoading = true;
  Map<String, dynamic> _analytics = {};

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() => _isLoading = true);

    try {
      final analytics = await _payoutService.getPayoutAnalytics();

      setState(() {
        _analytics = analytics;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    final successRate = _analytics['success_rate'] ?? 0.0;
    final avgProcessingTime =
        _analytics['average_processing_time_hours'] ?? 0.0;
    final totalThisMonth = _analytics['total_payouts_this_month'] ?? 0;
    final pendingCount = _analytics['pending_count'] ?? 0;
    final failedCount = _analytics['failed_count'] ?? 0;
    final failureReasons =
        _analytics['failure_reasons'] as Map<String, dynamic>? ?? {};
    final processingTimeTrend =
        _analytics['processing_time_trend'] as List<dynamic>? ?? [];

    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Volume Metrics Cards
          Text(
            'Volume Metrics',
            style: GoogleFonts.inter(
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'Total This Month',
                  totalThisMonth.toString(),
                  Icons.payments,
                  Colors.blue,
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: _buildMetricCard(
                  'Pending',
                  pendingCount.toString(),
                  Icons.pending,
                  Colors.orange,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'Failed',
                  failedCount.toString(),
                  Icons.error_outline,
                  Colors.red,
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: _buildMetricCard(
                  'Success Rate',
                  '${successRate.toStringAsFixed(1)}%',
                  Icons.check_circle,
                  Colors.green,
                ),
              ),
            ],
          ),
          SizedBox(height: 3.h),

          // Success Rate Gauge Chart
          Text(
            'Success Rate Gauge',
            style: GoogleFonts.inter(
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          SizedBox(height: 2.h),
          Container(
            height: 30.h,
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: _buildSuccessRateGauge(successRate),
          ),
          SizedBox(height: 3.h),

          // Average Processing Time Line Chart
          Text(
            'Processing Time Trend (7 Days)',
            style: GoogleFonts.inter(
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          SizedBox(height: 2.h),
          Container(
            height: 30.h,
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: _buildProcessingTimeChart(processingTimeTrend),
          ),
          SizedBox(height: 3.h),

          // Failure Reasons Pie Chart
          Text(
            'Failure Reasons Distribution',
            style: GoogleFonts.inter(
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          SizedBox(height: 2.h),
          Container(
            height: 35.h,
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: _buildFailureReasonsPieChart(failureReasons),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 8.w),
          SizedBox(height: 1.h),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 18.sp,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          SizedBox(height: 0.5.h),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 11.sp,
              color: AppTheme.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessRateGauge(double successRate) {
    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          height: 25.h,
          width: 25.h,
          child: PieChart(
            PieChartData(
              startDegreeOffset: 180,
              sectionsSpace: 0,
              centerSpaceRadius: 12.h,
              sections: [
                PieChartSectionData(
                  value: successRate,
                  color: Colors.green,
                  radius: 3.h,
                  showTitle: false,
                ),
                PieChartSectionData(
                  value: 100 - successRate,
                  color: Colors.grey[300],
                  radius: 3.h,
                  showTitle: false,
                ),
              ],
            ),
          ),
        ),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${successRate.toStringAsFixed(1)}%',
              style: GoogleFonts.inter(
                fontSize: 20.sp,
                fontWeight: FontWeight.w700,
                color: Colors.green,
              ),
            ),
            Text(
              'Success Rate',
              style: GoogleFonts.inter(
                fontSize: 11.sp,
                color: AppTheme.textSecondaryLight,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProcessingTimeChart(List<dynamic> trendData) {
    if (trendData.isEmpty) {
      return Center(
        child: Text(
          'No processing time data available',
          style: GoogleFonts.inter(
            fontSize: 12.sp,
            color: AppTheme.textSecondaryLight,
          ),
        ),
      );
    }

    final spots = trendData
        .asMap()
        .entries
        .map(
          (entry) => FlSpot(
            entry.key.toDouble(),
            (entry.value['avg_hours'] ?? 0.0).toDouble(),
          ),
        )
        .toList();

    return LineChart(
      LineChartData(
        gridData: FlGridData(show: true),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 10.w,
              getTitlesWidget: (value, meta) {
                return Text(
                  '${value.toInt()}h',
                  style: GoogleFonts.inter(fontSize: 10.sp),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                return Text(
                  'D${value.toInt() + 1}',
                  style: GoogleFonts.inter(fontSize: 10.sp),
                );
              },
            ),
          ),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: true),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: AppTheme.primaryLight,
            barWidth: 3,
            dotData: FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: AppTheme.primaryLight.withValues(alpha: 0.2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFailureReasonsPieChart(Map<String, dynamic> failureReasons) {
    if (failureReasons.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, size: 15.w, color: Colors.green),
            SizedBox(height: 2.h),
            Text(
              'No Failures',
              style: GoogleFonts.inter(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: Colors.green,
              ),
            ),
          ],
        ),
      );
    }

    final colors = [
      Colors.red,
      Colors.orange,
      Colors.purple,
      Colors.pink,
      Colors.brown,
    ];

    final sections = failureReasons.entries.toList().asMap().entries.map((
      entry,
    ) {
      final index = entry.key;
      final reason = entry.value.key;
      final count = entry.value.value as int;

      return PieChartSectionData(
        value: count.toDouble(),
        color: colors[index % colors.length],
        title: '$count',
        radius: 10.h,
        titleStyle: GoogleFonts.inter(
          fontSize: 11.sp,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      );
    }).toList();

    return Column(
      children: [
        Expanded(
          child: PieChart(
            PieChartData(
              sections: sections,
              sectionsSpace: 2,
              centerSpaceRadius: 0,
            ),
          ),
        ),
        SizedBox(height: 2.h),
        Wrap(
          spacing: 2.w,
          runSpacing: 1.h,
          children: failureReasons.entries.toList().asMap().entries.map((
            entry,
          ) {
            final index = entry.key;
            final reason = entry.value.key;
            final count = entry.value.value;

            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 3.w,
                  height: 3.w,
                  decoration: BoxDecoration(
                    color: colors[index % colors.length],
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: 1.w),
                Text(
                  '$reason ($count)',
                  style: GoogleFonts.inter(
                    fontSize: 10.sp,
                    color: AppTheme.textPrimaryLight,
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }
}
