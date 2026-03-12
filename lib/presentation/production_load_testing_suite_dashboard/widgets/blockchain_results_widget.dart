import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import 'package:fl_chart/fl_chart.dart';

class BlockchainResultsWidget extends StatelessWidget {
  final int transactionsPerSecond;
  final int blockPropagationDelayMs;
  final double transactionSuccessRate;
  final List<BarChartGroupData> propagationHistogram;

  const BlockchainResultsWidget({
    super.key,
    required this.transactionsPerSecond,
    required this.blockPropagationDelayMs,
    required this.transactionSuccessRate,
    required this.propagationHistogram,
  });

  @override
  Widget build(BuildContext context) {
    final bool passing = transactionSuccessRate >= 95.0;
    return SingleChildScrollView(
      padding: EdgeInsets.all(2.w),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _BlockchainMetricCard(
                  label: 'TPS',
                  value: transactionsPerSecond.toString(),
                  subtitle: 'Transactions/sec',
                  color: const Color(0xFF8B5CF6),
                  icon: Icons.bolt,
                ),
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: _BlockchainMetricCard(
                  label: 'Block Propagation',
                  value: '${blockPropagationDelayMs}ms',
                  subtitle: 'Avg delay',
                  color: const Color(0xFF6366F1),
                  icon: Icons.timer,
                ),
              ),
            ],
          ),
          SizedBox(height: 1.5.h),
          Container(
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: passing
                  ? const Color(0xFF10B981).withAlpha(20)
                  : const Color(0xFFEF4444).withAlpha(20),
              borderRadius: BorderRadius.circular(10.0),
              border: Border.all(
                color: passing
                    ? const Color(0xFF10B981).withAlpha(77)
                    : const Color(0xFFEF4444).withAlpha(77),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  passing ? Icons.check_circle : Icons.cancel,
                  color: passing
                      ? const Color(0xFF10B981)
                      : const Color(0xFFEF4444),
                  size: 22,
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Transaction Success Rate',
                        style: GoogleFonts.inter(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF374151),
                        ),
                      ),
                      Text(
                        '${transactionSuccessRate.toStringAsFixed(1)}% — ${passing ? 'PASS' : 'FAIL'}',
                        style: GoogleFonts.inter(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w800,
                          color: passing
                              ? const Color(0xFF10B981)
                              : const Color(0xFFEF4444),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 2.h),
          Container(
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12.0),
              boxShadow: [
                BoxShadow(color: Colors.black.withAlpha(13), blurRadius: 6),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Block Propagation Distribution',
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1A1A2E),
                  ),
                ),
                SizedBox(height: 1.5.h),
                SizedBox(
                  height: 16.h,
                  child: propagationHistogram.isEmpty
                      ? Center(
                          child: Text(
                            'Run a test to see propagation data',
                            style: GoogleFonts.inter(
                              fontSize: 11.sp,
                              color: const Color(0xFF9CA3AF),
                            ),
                          ),
                        )
                      : BarChart(
                          BarChartData(
                            barGroups: propagationHistogram,
                            gridData: FlGridData(
                              show: true,
                              drawVerticalLine: false,
                              getDrawingHorizontalLine: (_) => FlLine(
                                color: const Color(0xFFF3F4F6),
                                strokeWidth: 1,
                              ),
                            ),
                            titlesData: FlTitlesData(
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (v, _) => Text(
                                    '${(v.toInt() * 50)}ms',
                                    style: GoogleFonts.inter(
                                      fontSize: 7.sp,
                                      color: const Color(0xFF9CA3AF),
                                    ),
                                  ),
                                ),
                              ),
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 28,
                                  getTitlesWidget: (v, _) => Text(
                                    v.toInt().toString(),
                                    style: GoogleFonts.inter(
                                      fontSize: 7.sp,
                                      color: const Color(0xFF9CA3AF),
                                    ),
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
                            borderData: FlBorderData(show: false),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BlockchainMetricCard extends StatelessWidget {
  final String label;
  final String value;
  final String subtitle;
  final Color color;
  final IconData icon;

  const _BlockchainMetricCard({
    required this.label,
    required this.value,
    required this.subtitle,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(color: color.withAlpha(77)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              SizedBox(width: 1.w),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 9.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF6B7280),
                ),
              ),
            ],
          ),
          SizedBox(height: 0.5.h),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 15.sp,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          Text(
            subtitle,
            style: GoogleFonts.inter(
              fontSize: 8.sp,
              color: const Color(0xFF9CA3AF),
            ),
          ),
        ],
      ),
    );
  }
}
