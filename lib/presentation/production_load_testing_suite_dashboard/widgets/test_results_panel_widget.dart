import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../services/load_testing/production_load_test_service.dart';

class TestResultsPanelWidget extends StatelessWidget {
  final LoadTestReport? report;
  final bool isRunning;
  final List<FlSpot> throughputData;
  final String tabType;

  const TestResultsPanelWidget({
    super.key,
    required this.report,
    required this.isRunning,
    required this.throughputData,
    required this.tabType,
  });

  @override
  Widget build(BuildContext context) {
    if (isRunning) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: Color(0xFF6C63FF)),
            SizedBox(height: 2.h),
            Text(
              'Running load test...',
              style: GoogleFonts.inter(
                fontSize: 14.sp,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }
    if (report == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.speed, size: 48, color: Colors.grey.shade300),
            SizedBox(height: 2.h),
            Text(
              'No test results yet',
              style: GoogleFonts.inter(
                fontSize: 14.sp,
                color: Colors.grey.shade500,
              ),
            ),
            Text(
              'Select a tier and start a load test',
              style: GoogleFonts.inter(
                fontSize: 12.sp,
                color: Colors.grey.shade400,
              ),
            ),
          ],
        ),
      );
    }
    return SingleChildScrollView(
      padding: EdgeInsets.all(3.w),
      child: tabType == 'websocket'
          ? _buildWebSocketResults()
          : _buildBlockchainResults(),
    );
  }

  Widget _buildWebSocketResults() {
    final ws = report!.websocketMetrics;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStatusBanner(report!.passed),
        SizedBox(height: 2.h),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'Success Rate',
                '${ws.connectionSuccessRate.toStringAsFixed(1)}%',
                Icons.check_circle_outline,
                ws.connectionSuccessRate >= 95
                    ? const Color(0xFF4CAF50)
                    : const Color(0xFFFF6B35),
              ),
            ),
            SizedBox(width: 2.w),
            Expanded(
              child: _buildMetricCard(
                'Avg Latency',
                '${ws.avgLatencyMs}ms',
                Icons.timer_outlined,
                ws.avgLatencyMs <= 200
                    ? const Color(0xFF4CAF50)
                    : const Color(0xFFFF6B35),
              ),
            ),
          ],
        ),
        SizedBox(height: 1.h),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'Throughput',
                '${ws.messagesPerSecond}/s',
                Icons.bolt,
                const Color(0xFF6C63FF),
              ),
            ),
            SizedBox(width: 2.w),
            Expanded(
              child: _buildMetricCard(
                'Max Latency',
                '${ws.maxLatencyMs}ms',
                Icons.warning_amber_outlined,
                ws.maxLatencyMs <= 500
                    ? const Color(0xFF4CAF50)
                    : const Color(0xFFFF6B35),
              ),
            ),
          ],
        ),
        SizedBox(height: 2.h),
        if (throughputData.isNotEmpty) _buildThroughputChart(),
        SizedBox(height: 2.h),
        _buildBreakdownCard('Connection Breakdown', [
          _BreakdownItem(
            'Total',
            ws.concurrentConnections.toString(),
            Colors.blue,
          ),
          _BreakdownItem(
            'Successful',
            ws.successfulConnections.toString(),
            const Color(0xFF4CAF50),
          ),
          _BreakdownItem(
            'Failed',
            ws.failedConnections.toString(),
            const Color(0xFFFF6B35),
          ),
        ]),
      ],
    );
  }

  Widget _buildBlockchainResults() {
    final bc = report!.blockchainMetrics;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStatusBanner(report!.passed),
        SizedBox(height: 2.h),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'TPS',
                '${bc.avgTps}',
                Icons.link,
                bc.avgTps >= 100
                    ? const Color(0xFF4CAF50)
                    : const Color(0xFFFF6B35),
              ),
            ),
            SizedBox(width: 2.w),
            Expanded(
              child: _buildMetricCard(
                'Success Rate',
                '${bc.transactionSuccessRate.toStringAsFixed(1)}%',
                Icons.verified_outlined,
                bc.transactionSuccessRate >= 95
                    ? const Color(0xFF4CAF50)
                    : const Color(0xFFFF6B35),
              ),
            ),
          ],
        ),
        SizedBox(height: 1.h),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'Block Propagation',
                '${bc.avgBlockPropagationMs}ms',
                Icons.timeline,
                bc.avgBlockPropagationMs <= 1000
                    ? const Color(0xFF4CAF50)
                    : const Color(0xFFFF6B35),
              ),
            ),
            SizedBox(width: 2.w),
            Expanded(
              child: _buildMetricCard(
                'Avg Gas Cost',
                '\$${bc.avgGasCost.toStringAsFixed(6)}',
                Icons.local_gas_station_outlined,
                const Color(0xFF6C63FF),
              ),
            ),
          ],
        ),
        SizedBox(height: 2.h),
        _buildBreakdownCard('Transaction Breakdown', [
          _BreakdownItem(
            'Submitted',
            bc.transactionsSubmitted.toString(),
            Colors.blue,
          ),
          _BreakdownItem(
            'Confirmed',
            bc.transactionsConfirmed.toString(),
            const Color(0xFF4CAF50),
          ),
          _BreakdownItem(
            'Failed',
            bc.transactionsFailed.toString(),
            const Color(0xFFFF6B35),
          ),
        ]),
      ],
    );
  }

  Widget _buildStatusBanner(bool passed) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: passed
            ? const Color(0xFF4CAF50).withAlpha(26)
            : const Color(0xFFFF6B35).withAlpha(26),
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(
          color: passed
              ? const Color(0xFF4CAF50).withAlpha(77)
              : const Color(0xFFFF6B35).withAlpha(77),
        ),
      ),
      child: Row(
        children: [
          Icon(
            passed ? Icons.check_circle : Icons.error_outline,
            color: passed ? const Color(0xFF4CAF50) : const Color(0xFFFF6B35),
          ),
          SizedBox(width: 2.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  passed ? 'Test PASSED' : 'Test FAILED',
                  style: GoogleFonts.inter(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                    color: passed
                        ? const Color(0xFF4CAF50)
                        : const Color(0xFFFF6B35),
                  ),
                ),
                Text(
                  '${ProductionLoadTestService.formatTierLabel(report!.userTier)} • ${report!.endTime.difference(report!.startTime).inSeconds}s',
                  style: GoogleFonts.inter(
                    fontSize: 11.sp,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              SizedBox(width: 1.w),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 10.sp,
                    color: Colors.grey.shade600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: 0.5.h),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThroughputChart() {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Messages/Second Over Time',
            style: GoogleFonts.inter(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 1.h),
          SizedBox(
            height: 15.h,
            child: LineChart(
              LineChartData(
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
                      reservedSize: 40,
                      getTitlesWidget: (v, meta) => Text(
                        v.toInt().toString(),
                        style: GoogleFonts.inter(fontSize: 9.sp),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: throughputData,
                    isCurved: true,
                    color: const Color(0xFF6C63FF),
                    barWidth: 2,
                    dotData: FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: const Color(0xFF6C63FF).withAlpha(26),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownCard(String title, List<_BreakdownItem> items) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 1.h),
          ...items.map(
            (item) => Padding(
              padding: EdgeInsets.symmetric(vertical: 0.5.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: item.color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: 2.w),
                      Text(
                        item.label,
                        style: GoogleFonts.inter(
                          fontSize: 11.sp,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    item.value,
                    style: GoogleFonts.inter(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BreakdownItem {
  final String label;
  final String value;
  final Color color;
  _BreakdownItem(this.label, this.value, this.color);
}
