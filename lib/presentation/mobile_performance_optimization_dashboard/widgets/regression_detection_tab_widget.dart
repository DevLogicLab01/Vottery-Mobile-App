import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

/// Regression Detection Tab for Mobile Performance Dashboard
class RegressionDetectionTabWidget extends StatefulWidget {
  const RegressionDetectionTabWidget({super.key});

  @override
  State<RegressionDetectionTabWidget> createState() =>
      _RegressionDetectionTabWidgetState();
}

class _RegressionDetectionTabWidgetState
    extends State<RegressionDetectionTabWidget> {
  bool _isRunningCheck = false;

  final String _baselineDate = '2026-02-20';

  final List<Map<String, dynamic>> _regressionAlerts = [
    {
      'metric': 'Jolts Video Feed Load Time',
      'baseline': 1.2,
      'current': 1.8,
      'deviation': 50.0,
      'severity': 'critical',
      'trend': 'up',
    },
    {
      'metric': 'API Latency (p95)',
      'baseline': 280.0,
      'current': 340.0,
      'deviation': 21.4,
      'severity': 'warning',
      'trend': 'up',
    },
    {
      'metric': 'Memory Usage Peak',
      'baseline': 180.0,
      'current': 195.0,
      'deviation': 8.3,
      'severity': 'info',
      'trend': 'up',
    },
    {
      'metric': 'Frame Rate (avg)',
      'baseline': 59.2,
      'current': 58.8,
      'deviation': -0.7,
      'severity': 'ok',
      'trend': 'stable',
    },
  ];

  Color _getSeverityColor(String severity) {
    switch (severity) {
      case 'critical':
        return Colors.red;
      case 'warning':
        return Colors.orange;
      case 'info':
        return Colors.yellow;
      default:
        return Colors.green;
    }
  }

  IconData _getTrendIcon(String trend) {
    switch (trend) {
      case 'up':
        return Icons.trending_up;
      case 'down':
        return Icons.trending_down;
      default:
        return Icons.trending_flat;
    }
  }

  Future<void> _runRegressionCheck() async {
    setState(() => _isRunningCheck = true);
    await Future.delayed(const Duration(seconds: 3));
    if (mounted) {
      setState(() => _isRunningCheck = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Regression check complete: 2 alerts detected'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final criticalCount = _regressionAlerts
        .where((a) => a['severity'] == 'critical')
        .length;
    final warningCount = _regressionAlerts
        .where((a) => a['severity'] == 'warning')
        .length;

    return SingleChildScrollView(
      padding: EdgeInsets.all(3.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Regression Detection',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Baseline: $_baselineDate',
                    style: GoogleFonts.inter(
                      color: Colors.grey,
                      fontSize: 9.sp,
                    ),
                  ),
                ],
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  padding: EdgeInsets.symmetric(
                    horizontal: 3.w,
                    vertical: 0.8.h,
                  ),
                ),
                onPressed: _isRunningCheck ? null : _runRegressionCheck,
                icon: _isRunningCheck
                    ? const SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.refresh, color: Colors.white, size: 14),
                label: Text(
                  _isRunningCheck ? 'Checking...' : 'Run Check',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 10.sp,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              _buildSummaryCard(
                'Critical',
                criticalCount.toString(),
                Colors.red,
              ),
              SizedBox(width: 2.w),
              _buildSummaryCard(
                'Warnings',
                warningCount.toString(),
                Colors.orange,
              ),
              SizedBox(width: 2.w),
              _buildSummaryCard('Threshold', '>15%', Colors.grey),
            ],
          ),
          SizedBox(height: 2.h),
          Text(
            'Regression Alerts',
            style: GoogleFonts.inter(
              color: Colors.grey,
              fontSize: 11.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 1.h),
          ..._regressionAlerts.map((alert) {
            final color = _getSeverityColor(alert['severity']);
            final deviation = alert['deviation'] as double;
            final isRegression = deviation > 15;
            return Container(
              margin: EdgeInsets.only(bottom: 1.h),
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isRegression
                      ? color.withAlpha(128)
                      : Colors.grey.withAlpha(51),
                ),
              ),
              child: Row(
                children: [
                  Icon(_getTrendIcon(alert['trend']), color: color, size: 20),
                  SizedBox(width: 2.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          alert['metric'],
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Baseline: ${alert['baseline']} → Current: ${alert['current']}',
                          style: GoogleFonts.inter(
                            color: Colors.grey,
                            fontSize: 9.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        deviation > 0
                            ? '+${deviation.toStringAsFixed(1)}%'
                            : '${deviation.toStringAsFixed(1)}%',
                        style: GoogleFonts.inter(
                          color: color,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 1.5.w,
                          vertical: 0.2.h,
                        ),
                        decoration: BoxDecoration(
                          color: color.withAlpha(51),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          alert['severity'].toUpperCase(),
                          style: GoogleFonts.inter(
                            color: color,
                            fontSize: 8.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
          SizedBox(height: 1.h),
          Container(
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF6366F1).withAlpha(77)),
            ),
            child: Row(
              children: [
                const Icon(Icons.schedule, color: Color(0xFF6366F1), size: 16),
                SizedBox(width: 2.w),
                Expanded(
                  child: Text(
                    'Auto regression checks: Daily at 02:00 UTC • Alert threshold: >15% deviation',
                    style: GoogleFonts.inter(
                      color: Colors.grey,
                      fontSize: 9.sp,
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

  Widget _buildSummaryCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(2.w),
        decoration: BoxDecoration(
          color: color.withAlpha(26),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withAlpha(77)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: GoogleFonts.inter(
                color: color,
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.inter(color: Colors.grey, fontSize: 9.sp),
            ),
          ],
        ),
      ),
    );
  }
}
