import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class ChurnMonitoringOverviewWidget extends StatelessWidget {
  final int atRiskCount;
  final double interventionSuccessRate;
  final bool autoTriggerActive;
  final int pendingInterventions;

  const ChurnMonitoringOverviewWidget({
    super.key,
    required this.atRiskCount,
    required this.interventionSuccessRate,
    required this.autoTriggerActive,
    required this.pendingInterventions,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.red.shade900, Colors.orange.shade800],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Churn Monitoring',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                decoration: BoxDecoration(
                  color: autoTriggerActive ? Colors.green : Colors.red,
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      autoTriggerActive ? Icons.check_circle : Icons.pause_circle,
                      color: Colors.white,
                      size: 12,
                    ),
                    SizedBox(width: 1.w),
                    Text(
                      autoTriggerActive ? 'AUTO-TRIGGER ON' : 'PAUSED',
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'At-Risk Creators',
                  atRiskCount.toString(),
                  Icons.warning_amber,
                  Colors.orange,
                ),
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: _buildMetricCard(
                  'Success Rate',
                  '${(interventionSuccessRate * 100).toStringAsFixed(1)}%',
                  Icons.trending_up,
                  Colors.green,
                ),
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: _buildMetricCard(
                  'Pending',
                  pendingInterventions.toString(),
                  Icons.schedule,
                  Colors.blue,
                ),
              ),
            ],
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
      padding: EdgeInsets.all(2.w),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          SizedBox(height: 0.5.h),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 9.sp,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
