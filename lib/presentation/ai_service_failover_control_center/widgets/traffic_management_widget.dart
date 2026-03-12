import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../services/enhanced_ai_orchestrator_service.dart';

class TrafficManagementWidget extends StatelessWidget {
  final Map<String, dynamic> trafficStats;
  final Map<String, ServiceHealthStatus> serviceHealth;

  const TrafficManagementWidget({
    super.key,
    required this.trafficStats,
    required this.serviceHealth,
  });

  @override
  Widget build(BuildContext context) {
    final totalRequests = trafficStats['total_requests'] as int? ?? 0;
    final requestDistribution =
        trafficStats['request_distribution'] as Map<String, dynamic>? ?? {};

    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Traffic Management',
            style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 2.h),
          _buildTrafficOverview(totalRequests),
          SizedBox(height: 2.h),
          _buildRequestDistributionChart(requestDistribution),
          SizedBox(height: 2.h),
          _buildLoadBalancingInfo(),
        ],
      ),
    );
  }

  Widget _buildTrafficOverview(int totalRequests) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade400, Colors.blue.shade600],
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildTrafficStat(
            label: 'Total Requests',
            value: _formatNumber(totalRequests),
            icon: Icons.trending_up,
          ),
          _buildTrafficStat(
            label: 'Requests/Min',
            value: _formatNumber(totalRequests ~/ 60),
            icon: Icons.speed,
          ),
          _buildTrafficStat(
            label: 'Active Routes',
            value: '${serviceHealth.length}',
            icon: Icons.route,
          ),
        ],
      ),
    );
  }

  Widget _buildTrafficStat({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24.sp),
        SizedBox(height: 0.5.h),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(color: Colors.white70, fontSize: 10.sp),
        ),
      ],
    );
  }

  Widget _buildRequestDistributionChart(
    Map<String, dynamic> requestDistribution,
  ) {
    if (requestDistribution.isEmpty) {
      return Center(
        child: Text(
          'No traffic data available',
          style: TextStyle(fontSize: 12.sp, color: Colors.grey),
        ),
      );
    }

    final sections = requestDistribution.entries.map((entry) {
      final provider = entry.key;
      final count = entry.value as int;
      final total = requestDistribution.values.fold<int>(
        0,
        (sum, val) => sum + (val as int),
      );
      final percentage = (count / total * 100).toStringAsFixed(1);

      return PieChartSectionData(
        value: count.toDouble(),
        title: '$percentage%',
        color: _getProviderColor(provider),
        radius: 50,
        titleStyle: TextStyle(
          fontSize: 12.sp,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();

    return Column(
      children: [
        Text(
          'Request Distribution',
          style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
        ),
        SizedBox(height: 2.h),
        SizedBox(
          height: 200,
          child: PieChart(
            PieChartData(
              sections: sections,
              sectionsSpace: 2,
              centerSpaceRadius: 40,
            ),
          ),
        ),
        SizedBox(height: 2.h),
        _buildLegend(requestDistribution),
      ],
    );
  }

  Widget _buildLegend(Map<String, dynamic> requestDistribution) {
    return Wrap(
      spacing: 3.w,
      runSpacing: 1.h,
      children: requestDistribution.entries.map((entry) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: _getProviderColor(entry.key),
                shape: BoxShape.circle,
              ),
            ),
            SizedBox(width: 1.w),
            Text(
              '${entry.key.toUpperCase()}: ${entry.value}',
              style: TextStyle(fontSize: 11.sp),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildLoadBalancingInfo() {
    return Container(
      padding: EdgeInsets.all(2.w),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.balance, color: Colors.green, size: 20.sp),
          SizedBox(width: 2.w),
          Expanded(
            child: Text(
              'Automatic load balancing distributes requests across healthy '
              'services based on latency and capacity.',
              style: TextStyle(fontSize: 11.sp, color: Colors.green.shade900),
            ),
          ),
        ],
      ),
    );
  }

  Color _getProviderColor(String provider) {
    switch (provider.toLowerCase()) {
      case 'openai':
        return Colors.green;
      case 'anthropic':
        return Colors.orange;
      case 'perplexity':
        return Colors.blue;
      case 'gemini':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }
}
