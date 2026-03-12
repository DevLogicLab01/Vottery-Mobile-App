import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

class RegionHealthCardWidget extends StatelessWidget {
  final String regionName;
  final String regionCode;
  final double healthScore;
  final int latencyMs;
  final int activeConnections;
  final bool isPrimary;
  final VoidCallback? onManualFailover;

  const RegionHealthCardWidget({
    super.key,
    required this.regionName,
    required this.regionCode,
    required this.healthScore,
    required this.latencyMs,
    required this.activeConnections,
    this.isPrimary = false,
    this.onManualFailover,
  });

  Color get _healthColor {
    if (healthScore >= 80) return Colors.green;
    if (healthScore >= 60) return Colors.orange;
    return Colors.red;
  }

  String get _healthStatus {
    if (healthScore >= 80) return 'Healthy';
    if (healthScore >= 60) return 'Degraded';
    return 'Critical';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: isPrimary ? 4 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
        side: BorderSide(
          color: isPrimary
              ? Colors.blue.withAlpha(128)
              : _healthColor.withAlpha(77),
          width: isPrimary ? 2 : 1,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(2.w),
                  decoration: BoxDecoration(
                    color: _healthColor.withAlpha(26),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Icon(Icons.cloud, color: _healthColor, size: 20),
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            regionCode,
                            style: GoogleFonts.inter(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          if (isPrimary) ...[
                            SizedBox(width: 1.w),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 1.5.w,
                                vertical: 0.2.h,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue.withAlpha(26),
                                borderRadius: BorderRadius.circular(4.0),
                              ),
                              child: Text(
                                'PRIMARY',
                                style: GoogleFonts.inter(
                                  fontSize: 8.sp,
                                  color: Colors.blue,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      Text(
                        regionName,
                        style: GoogleFonts.inter(
                          fontSize: 10.sp,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 2.w,
                    vertical: 0.3.h,
                  ),
                  decoration: BoxDecoration(
                    color: _healthColor.withAlpha(26),
                    borderRadius: BorderRadius.circular(6.0),
                  ),
                  child: Text(
                    _healthStatus,
                    style: GoogleFonts.inter(
                      fontSize: 10.sp,
                      color: _healthColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 1.5.h),
            // Health Score
            Row(
              children: [
                Text(
                  'Health Score',
                  style: GoogleFonts.inter(
                    fontSize: 11.sp,
                    color: Colors.grey[600],
                  ),
                ),
                const Spacer(),
                Text(
                  '${healthScore.toStringAsFixed(0)}%',
                  style: GoogleFonts.inter(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w800,
                    color: _healthColor,
                  ),
                ),
              ],
            ),
            SizedBox(height: 0.5.h),
            LinearProgressIndicator(
              value: healthScore / 100,
              backgroundColor: _healthColor.withAlpha(51),
              valueColor: AlwaysStoppedAnimation<Color>(_healthColor),
              minHeight: 8,
              borderRadius: BorderRadius.circular(4.0),
            ),
            SizedBox(height: 1.h),
            // Metrics Row
            Row(
              children: [
                Expanded(
                  child: _buildMetric(Icons.speed, '${latencyMs}ms', 'Latency'),
                ),
                Expanded(
                  child: _buildMetric(
                    Icons.people,
                    '$activeConnections',
                    'Connections',
                  ),
                ),
              ],
            ),
            if (onManualFailover != null) ...[
              SizedBox(height: 1.h),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onManualFailover,
                  icon: const Icon(Icons.swap_horiz, size: 14),
                  label: Text(
                    'Manual Failover',
                    style: GoogleFonts.inter(fontSize: 10.sp),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.orange,
                    side: const BorderSide(color: Colors.orange),
                    padding: EdgeInsets.symmetric(vertical: 0.8.h),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMetric(IconData icon, String value, String label) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey[500]),
        SizedBox(width: 1.w),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 11.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.inter(fontSize: 9.sp, color: Colors.grey[500]),
            ),
          ],
        ),
      ],
    );
  }
}
