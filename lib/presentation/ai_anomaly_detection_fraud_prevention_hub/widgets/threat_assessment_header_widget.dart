import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class ThreatAssessmentHeaderWidget extends StatelessWidget {
  final Map<String, dynamic> threatData;

  const ThreatAssessmentHeaderWidget({super.key, required this.threatData});

  @override
  Widget build(BuildContext context) {
    final riskLevel = threatData['current_risk_level'] ?? 'low';
    final activeInvestigations = threatData['active_investigations'] ?? 0;
    final confidence = threatData['predictive_confidence'] ?? 0.0;

    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _getRiskGradient(riskLevel),
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(26),
            blurRadius: 8.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_getRiskIcon(riskLevel), color: Colors.white, size: 24.sp),
              SizedBox(width: 2.w),
              Text(
                'Threat Assessment',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMetric(
                'Risk Level',
                riskLevel.toUpperCase(),
                Icons.warning_amber,
              ),
              _buildMetric(
                'Active Investigations',
                activeInvestigations.toString(),
                Icons.search,
              ),
              _buildMetric(
                'Confidence',
                '${(confidence * 100).toStringAsFixed(0)}%',
                Icons.analytics,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetric(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 20.sp),
        SizedBox(height: 0.5.h),
        Text(
          value,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 10.sp, color: Colors.white70),
        ),
      ],
    );
  }

  List<Color> _getRiskGradient(String riskLevel) {
    switch (riskLevel) {
      case 'critical':
        return [Colors.red.shade700, Colors.red.shade900];
      case 'high':
        return [Colors.orange.shade700, Colors.red.shade700];
      case 'medium':
        return [Colors.yellow.shade700, Colors.orange.shade700];
      default:
        return [Colors.green.shade600, Colors.green.shade800];
    }
  }

  IconData _getRiskIcon(String riskLevel) {
    switch (riskLevel) {
      case 'critical':
        return Icons.dangerous;
      case 'high':
        return Icons.warning;
      case 'medium':
        return Icons.info;
      default:
        return Icons.check_circle;
    }
  }
}
