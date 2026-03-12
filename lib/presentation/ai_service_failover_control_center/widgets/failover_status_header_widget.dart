import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../services/enhanced_ai_orchestrator_service.dart';

class FailoverStatusHeaderWidget extends StatelessWidget {
  final Map<String, ServiceHealthStatus> serviceHealth;
  final Map<String, dynamic> trafficStats;

  const FailoverStatusHeaderWidget({
    super.key,
    required this.serviceHealth,
    required this.trafficStats,
  });

  @override
  Widget build(BuildContext context) {
    final healthyCount = serviceHealth.values
        .where((h) => h.status == 'healthy')
        .length;
    final totalServices = serviceHealth.length;
    final avgLatency = _calculateAverageLatency();
    final activeFailovers = trafficStats['active_failovers'] as int? ?? 0;

    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            healthyCount == totalServices ? Colors.green : Colors.orange,
            healthyCount == totalServices
                ? Colors.green.shade700
                : Colors.orange.shade700,
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                healthyCount == totalServices
                    ? Icons.check_circle
                    : Icons.warning,
                color: Colors.white,
                size: 24.sp,
              ),
              SizedBox(width: 2.w),
              Text(
                healthyCount == totalServices
                    ? 'All Systems Operational'
                    : 'Degraded Performance',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatCard(
                label: 'Healthy Services',
                value: '$healthyCount/$totalServices',
                icon: Icons.health_and_safety,
              ),
              _buildStatCard(
                label: 'Avg Latency',
                value: '${avgLatency}ms',
                icon: Icons.speed,
              ),
              _buildStatCard(
                label: 'Active Failovers',
                value: '$activeFailovers',
                icon: Icons.swap_horiz,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(2.w),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(51),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 20.sp),
            SizedBox(height: 0.5.h),
            Text(
              value,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: TextStyle(color: Colors.white70, fontSize: 10.sp),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  int _calculateAverageLatency() {
    if (serviceHealth.isEmpty) return 0;

    final totalLatency = serviceHealth.values.fold<int>(
      0,
      (sum, h) => sum + h.avgResponseTimeMs,
    );
    return (totalLatency / serviceHealth.length).round();
  }
}
