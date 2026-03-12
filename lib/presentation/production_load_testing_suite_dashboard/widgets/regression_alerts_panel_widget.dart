import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import '../../../services/load_testing/production_load_test_service.dart';

class RegressionAlertsPanelWidget extends StatelessWidget {
  final List<RegressionAlert> regressions;
  final bool isRunning;

  const RegressionAlertsPanelWidget({
    super.key,
    required this.regressions,
    required this.isRunning,
  });

  @override
  Widget build(BuildContext context) {
    if (isRunning) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF6C63FF)),
      );
    }
    if (regressions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.check_circle_outline,
              size: 48,
              color: Color(0xFF4CAF50),
            ),
            SizedBox(height: 2.h),
            Text(
              'No Regressions Detected',
              style: GoogleFonts.inter(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF4CAF50),
              ),
            ),
            Text(
              'All metrics within acceptable thresholds',
              style: GoogleFonts.inter(
                fontSize: 12.sp,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: EdgeInsets.all(3.w),
      itemCount: regressions.length,
      itemBuilder: (context, index) =>
          _RegressionAlertCard(alert: regressions[index]),
    );
  }
}

class _RegressionAlertCard extends StatelessWidget {
  final RegressionAlert alert;
  const _RegressionAlertCard({required this.alert});

  @override
  Widget build(BuildContext context) {
    final isCritical = alert.severity == 'critical';
    final color = isCritical
        ? const Color(0xFFE53935)
        : const Color(0xFFFF9800);
    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: color.withAlpha(77)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.3.h),
                decoration: BoxDecoration(
                  color: color.withAlpha(26),
                  borderRadius: BorderRadius.circular(4.0),
                ),
                child: Text(
                  alert.severity.toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: Text(
                  alert.metricName,
                  style: GoogleFonts.inter(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Row(
            children: [
              Expanded(
                child: _valueBox(
                  'Baseline',
                  alert.baselineValue.toStringAsFixed(1),
                  Colors.grey.shade600,
                ),
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: _valueBox(
                  'Current',
                  alert.currentValue.toStringAsFixed(1),
                  color,
                ),
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: _valueBox(
                  'Regression',
                  '+${alert.regressionPercentage.toStringAsFixed(1)}%',
                  color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _valueBox(String label, String value, Color color) {
    return Container(
      padding: EdgeInsets.all(2.w),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(6.0),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 9.sp,
              color: Colors.grey.shade500,
            ),
          ),
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
}
