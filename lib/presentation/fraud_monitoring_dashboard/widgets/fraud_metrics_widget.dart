import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

class FraudMetricsWidget extends StatelessWidget {
  final List<Map<String, dynamic>> fraudEvents;

  const FraudMetricsWidget({required this.fraudEvents, super.key});

  @override
  Widget build(BuildContext context) {
    final criticalCount = fraudEvents
        .where((e) => e['risk_level'] == 'critical')
        .length;
    final highCount = fraudEvents
        .where((e) => e['risk_level'] == 'high')
        .length;
    final avgFraudScore = fraudEvents.isEmpty
        ? 0.0
        : fraudEvents.fold<double>(
                0.0,
                (sum, e) =>
                    sum + ((e['fraud_score'] as num?)?.toDouble() ?? 0.0),
              ) /
              fraudEvents.length;

    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            'Active Alerts',
            fraudEvents.length.toString(),
            Icons.warning_amber,
          ),
        ),
        SizedBox(width: 3.w),
        Expanded(
          child: _buildMetricCard(
            'Critical',
            criticalCount.toString(),
            Icons.error,
          ),
        ),
        SizedBox(width: 3.w),
        Expanded(
          child: _buildMetricCard(
            'Avg Score',
            '${(avgFraudScore * 100).toStringAsFixed(0)}%',
            Icons.analytics,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 12.w, color: Colors.white),
        SizedBox(height: 0.5.h),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 18.sp,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 10.sp, color: Colors.white70),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
