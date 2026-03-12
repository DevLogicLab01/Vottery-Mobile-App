import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class ThreatCorrelationWidget extends StatelessWidget {
  final Map<String, Map<String, dynamic>> zoneThreats;
  final Map<String, Map<String, dynamic>> zones;

  const ThreatCorrelationWidget({
    super.key,
    required this.zoneThreats,
    required this.zones,
  });

  @override
  Widget build(BuildContext context) {
    final correlations = _calculateCorrelations();

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.cardLight,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.analytics, color: AppTheme.primaryLight, size: 6.w),
              SizedBox(width: 2.w),
              Text(
                'Cross-Zone Threat Correlation',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimaryLight,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          if (correlations.isEmpty)
            Center(
              child: Padding(
                padding: EdgeInsets.all(4.w),
                child: Text(
                  'No significant cross-zone patterns detected',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: AppTheme.textSecondaryLight,
                  ),
                ),
              ),
            )
          else
            ...correlations.map(
              (correlation) => _buildCorrelationCard(
                correlation['zones'],
                correlation['pattern'],
                correlation['severity'],
              ),
            ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _calculateCorrelations() {
    List<Map<String, dynamic>> correlations = [];

    // Identify zones with similar threat patterns
    final highThreatZones = zoneThreats.entries
        .where((entry) => (entry.value['score'] as double) >= 60)
        .map((entry) => zones[entry.key]!['name'])
        .toList();

    if (highThreatZones.length >= 2) {
      correlations.add({
        'zones': highThreatZones.take(3).join(', '),
        'pattern': 'Coordinated attack pattern detected',
        'severity': 'high',
      });
    }

    // Check for increasing trends
    final increasingZones = zoneThreats.entries
        .where((entry) => entry.value['trend'] == 'increasing')
        .map((entry) => zones[entry.key]!['name'])
        .toList();

    if (increasingZones.length >= 2) {
      correlations.add({
        'zones': increasingZones.take(3).join(', '),
        'pattern': 'Simultaneous threat escalation',
        'severity': 'medium',
      });
    }

    return correlations;
  }

  Widget _buildCorrelationCard(String zones, String pattern, String severity) {
    final color = severity == 'high' ? Colors.red : Colors.orange;

    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(77), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: color, size: 5.w),
              SizedBox(width: 2.w),
              Expanded(
                child: Text(
                  pattern,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Text(
            'Affected zones: $zones',
            style: TextStyle(
              fontSize: 11.sp,
              color: AppTheme.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }
}
