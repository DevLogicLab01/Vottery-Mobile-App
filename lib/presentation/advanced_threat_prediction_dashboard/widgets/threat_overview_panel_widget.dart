import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:google_fonts/google_fonts.dart';

class ThreatOverviewPanelWidget extends StatelessWidget {
  final Map<String, dynamic> metrics;
  final List<Map<String, dynamic>> upcomingThreats;
  final VoidCallback onViewZoneMap;
  final VoidCallback onRunAnalysis;
  final VoidCallback onAcknowledgeAlerts;

  const ThreatOverviewPanelWidget({
    super.key,
    required this.metrics,
    required this.upcomingThreats,
    required this.onViewZoneMap,
    required this.onRunAnalysis,
    required this.onAcknowledgeAlerts,
  });

  @override
  Widget build(BuildContext context) {
    final avgConfidence = metrics['avg_confidence'] as double? ?? 0.0;
    final confidenceColor = avgConfidence > 0.85
        ? Colors.green
        : avgConfidence > 0.70
        ? Colors.orange
        : Colors.red;

    return SingleChildScrollView(
      padding: EdgeInsets.all(3.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Key Threat Metrics',
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              fontWeight: FontWeight.w700,
              color: Colors.grey[800],
            ),
          ),
          SizedBox(height: 1.5.h),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 2.w,
            mainAxisSpacing: 1.5.h,
            childAspectRatio: 1.6,
            children: [
              _MetricCard(
                label: 'Critical Threats',
                value: '${metrics['critical_threats'] ?? 0}',
                icon: Icons.warning_amber_rounded,
                color: Colors.red,
              ),
              _MetricCard(
                label: 'High Threats',
                value: '${metrics['high_threats'] ?? 0}',
                icon: Icons.error_outline,
                color: Colors.orange,
              ),
              _MetricCard(
                label: 'Active Incidents',
                value: '${metrics['active_incidents'] ?? 0}',
                icon: Icons.security,
                color: Colors.blue,
              ),
              _MetricCard(
                label: 'Predicted (30d)',
                value: '${metrics['predicted_threats_30d'] ?? 0}',
                icon: Icons.trending_up,
                color: Colors.purple,
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Container(
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: confidenceColor.withAlpha(20),
              borderRadius: BorderRadius.circular(12.0),
              border: Border.all(color: confidenceColor.withAlpha(77)),
            ),
            child: Row(
              children: [
                Icon(Icons.analytics, color: confidenceColor, size: 20.sp),
                SizedBox(width: 2.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Avg Prediction Confidence',
                        style: GoogleFonts.inter(
                          fontSize: 11.sp,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        '${(avgConfidence * 100).toStringAsFixed(1)}%',
                        style: GoogleFonts.inter(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w700,
                          color: confidenceColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 2.w,
                    vertical: 0.5.h,
                  ),
                  decoration: BoxDecoration(
                    color: confidenceColor,
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Text(
                    avgConfidence > 0.85
                        ? 'HIGH'
                        : avgConfidence > 0.70
                        ? 'MEDIUM'
                        : 'LOW',
                    style: GoogleFonts.inter(
                      fontSize: 9.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            'Upcoming Threats Timeline',
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              fontWeight: FontWeight.w700,
              color: Colors.grey[800],
            ),
          ),
          SizedBox(height: 1.h),
          _ThreatTimelineWidget(threats: upcomingThreats),
          SizedBox(height: 2.h),
          Text(
            'Quick Actions',
            style: GoogleFonts.inter(
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 1.h),
          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  label: 'Zone Map',
                  icon: Icons.map,
                  color: Colors.blue,
                  onTap: onViewZoneMap,
                ),
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: _ActionButton(
                  label: 'Run Analysis',
                  icon: Icons.play_circle_outline,
                  color: Colors.green,
                  onTap: onRunAnalysis,
                ),
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: _ActionButton(
                  label: 'Acknowledge',
                  icon: Icons.check_circle_outline,
                  color: Colors.orange,
                  onTap: onAcknowledgeAlerts,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(2.5.w),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: color.withAlpha(51)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 18.sp),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 9.sp,
                  color: Colors.grey[600],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ThreatTimelineWidget extends StatelessWidget {
  final List<Map<String, dynamic>> threats;
  const _ThreatTimelineWidget({required this.threats});

  @override
  Widget build(BuildContext context) {
    if (threats.isEmpty) {
      return Container(
        padding: EdgeInsets.all(3.w),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Center(
          child: Text(
            'No upcoming threats detected',
            style: GoogleFonts.inter(fontSize: 11.sp, color: Colors.grey[500]),
          ),
        ),
      );
    }
    return Column(
      children: threats.take(6).map((threat) {
        final severity = threat['severity'] as String? ?? 'low';
        final severityColor = severity == 'critical'
            ? Colors.red
            : severity == 'high'
            ? Colors.orange
            : severity == 'medium'
            ? Colors.yellow[700]!
            : Colors.green;
        final daysUntil = threat['days_until'] as int? ?? 0;
        final label = daysUntil <= 7
            ? '7d'
            : daysUntil <= 14
            ? '14d'
            : '30d';
        return Container(
          margin: EdgeInsets.only(bottom: 1.h),
          padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8.0),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 1.5.w,
                  vertical: 0.3.h,
                ),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(4.0),
                ),
                child: Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 9.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue[700],
                  ),
                ),
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: Text(
                  threat['description'] as String? ?? 'Unknown threat',
                  style: GoogleFonts.inter(
                    fontSize: 11.sp,
                    color: Colors.grey[700],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 1.5.w,
                  vertical: 0.3.h,
                ),
                decoration: BoxDecoration(
                  color: severityColor.withAlpha(38),
                  borderRadius: BorderRadius.circular(4.0),
                ),
                child: Text(
                  severity.toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 8.sp,
                    fontWeight: FontWeight.w700,
                    color: severityColor,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 1.2.h),
        decoration: BoxDecoration(
          color: color.withAlpha(26),
          borderRadius: BorderRadius.circular(10.0),
          border: Border.all(color: color.withAlpha(77)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 16.sp),
            SizedBox(height: 0.3.h),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 9.sp,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
