import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

class FraudAlertsPanelWidget extends StatelessWidget {
  final List<Map<String, dynamic>> fraudAlerts;
  final Function(String alertId) onInvestigate;

  const FraudAlertsPanelWidget({
    super.key,
    required this.fraudAlerts,
    required this.onInvestigate,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF1E1E2E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.security, color: Color(0xFFFF6B6B), size: 20),
                SizedBox(width: 2.w),
                Text(
                  'Fraud Detection Alerts',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: fraudAlerts.isNotEmpty
                        ? const Color(0xFFFF6B6B).withAlpha(30)
                        : const Color(0xFF4CAF50).withAlpha(30),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Text(
                    '${fraudAlerts.length} alerts',
                    style: GoogleFonts.inter(
                      color: fraudAlerts.isNotEmpty
                          ? const Color(0xFFFF6B6B)
                          : const Color(0xFF4CAF50),
                      fontSize: 10.sp,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 2.h),
            if (fraudAlerts.isEmpty)
              Container(
                padding: EdgeInsets.all(3.w),
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50).withAlpha(15),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: Color(0xFF4CAF50),
                      size: 20,
                    ),
                    SizedBox(width: 2.w),
                    Text(
                      'No suspicious patterns detected',
                      style: GoogleFonts.inter(
                        color: const Color(0xFF4CAF50),
                        fontSize: 12.sp,
                      ),
                    ),
                  ],
                ),
              )
            else
              ...fraudAlerts.map(
                (alert) => Padding(
                  padding: EdgeInsets.only(bottom: 1.5.h),
                  child: Container(
                    padding: EdgeInsets.all(2.w),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF6B6B).withAlpha(10),
                      borderRadius: BorderRadius.circular(8.0),
                      border: Border.all(
                        color: const Color(0xFFFF6B6B).withAlpha(40),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: _getSeverityColor(
                                  alert['confidence_score'],
                                ).withAlpha(30),
                                borderRadius: BorderRadius.circular(4.0),
                              ),
                              child: Text(
                                alert['pattern_type']?.toString() ?? 'Unknown',
                                style: GoogleFonts.inter(
                                  color: _getSeverityColor(
                                    alert['confidence_score'],
                                  ),
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              'Confidence: ${((alert['confidence_score'] as num?) ?? 0).toStringAsFixed(0)}%',
                              style: GoogleFonts.inter(
                                color: Colors.white54,
                                fontSize: 10.sp,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 0.5.h),
                        Text(
                          'Affected users: ${alert['affected_users'] ?? 0}',
                          style: GoogleFonts.inter(
                            color: Colors.white70,
                            fontSize: 11.sp,
                          ),
                        ),
                        SizedBox(height: 1.h),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: () =>
                                onInvestigate(alert['id']?.toString() ?? ''),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFF6C63FF)),
                              padding: EdgeInsets.symmetric(vertical: 0.8.h),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6.0),
                              ),
                            ),
                            child: Text(
                              'Investigate',
                              style: GoogleFonts.inter(
                                color: const Color(0xFF6C63FF),
                                fontSize: 11.sp,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _getSeverityColor(dynamic score) {
    final s = (score as num?)?.toDouble() ?? 0;
    if (s >= 80) return const Color(0xFFFF6B6B);
    if (s >= 60) return const Color(0xFFFFB347);
    return const Color(0xFFFFD700);
  }
}
