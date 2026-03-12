import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:google_fonts/google_fonts.dart';

class PerformanceSummaryCardWidget extends StatelessWidget {
  final Map<String, dynamic> summary;

  const PerformanceSummaryCardWidget({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final avgApiLatency = summary['avg_api_latency'] ?? 0;
    final p95Latency = summary['p95_latency'] ?? 0;
    final errorRate = summary['error_rate'] ?? 0.0;
    final uptime = summary['uptime'] ?? 0.0;
    final activeConnections = summary['active_connections'] ?? 0;

    final overallHealth = _calculateOverallHealth(
      avgApiLatency,
      errorRate,
      uptime,
    );

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'System Health',
                style: GoogleFonts.inter(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.5.h),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(51),
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Text(
                  '${overallHealth.toStringAsFixed(0)}%',
                  style: GoogleFonts.inter(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 3.h),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'Avg Latency',
                  '${avgApiLatency}ms',
                  Icons.speed,
                  theme,
                ),
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: _buildMetricCard(
                  'P95 Latency',
                  '${p95Latency}ms',
                  Icons.trending_up,
                  theme,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'Error Rate',
                  '${errorRate.toStringAsFixed(1)}%',
                  Icons.error_outline,
                  theme,
                ),
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: _buildMetricCard(
                  'Uptime',
                  '${uptime.toStringAsFixed(1)}%',
                  Icons.check_circle,
                  theme,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Container(
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(26),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.link, color: Colors.white, size: 5.w),
                    SizedBox(width: 2.w),
                    Text(
                      'Active Connections',
                      style: GoogleFonts.inter(
                        fontSize: 12.sp,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
                Text(
                  activeConnections.toString(),
                  style: GoogleFonts.inter(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
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
    ThemeData theme,
  ) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(26),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white, size: 6.w),
          SizedBox(height: 1.h),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 0.3.h),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11.sp,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  double _calculateOverallHealth(
    int avgLatency,
    double errorRate,
    double uptime,
  ) {
    double latencyScore = avgLatency < 500 ? 100 : (1000 - avgLatency) / 5;
    double errorScore = (100 - errorRate * 10).clamp(0, 100);
    double uptimeScore = uptime;

    return ((latencyScore + errorScore + uptimeScore) / 3).clamp(0, 100);
  }
}
