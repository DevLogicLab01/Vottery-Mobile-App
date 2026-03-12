import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../services/enhanced_ai_orchestrator_service.dart';

class ServiceHealthMonitoringWidget extends StatelessWidget {
  final Map<String, ServiceHealthStatus> serviceHealth;
  final VoidCallback onRefresh;

  const ServiceHealthMonitoringWidget({
    super.key,
    required this.serviceHealth,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Service Health Monitoring',
                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: onRefresh,
                tooltip: 'Refresh Health Status',
              ),
            ],
          ),
          SizedBox(height: 2.h),
          _buildHealthTable(),
          SizedBox(height: 2.h),
          _buildHealthCheckInfo(),
        ],
      ),
    );
  }

  Widget _buildHealthTable() {
    return Table(
      border: TableBorder.all(color: Colors.grey.shade300),
      columnWidths: const {
        0: FlexColumnWidth(2),
        1: FlexColumnWidth(1),
        2: FlexColumnWidth(1),
        3: FlexColumnWidth(2),
      },
      children: [
        TableRow(
          decoration: BoxDecoration(color: Colors.grey.shade100),
          children: [
            _buildTableHeader('Provider'),
            _buildTableHeader('Status'),
            _buildTableHeader('Latency'),
            _buildTableHeader('Last Check'),
          ],
        ),
        ...serviceHealth.entries.map(
          (entry) => TableRow(
            children: [
              _buildTableCell(entry.key.toUpperCase()),
              _buildStatusCell(entry.value.status),
              _buildTableCell('${entry.value.avgResponseTimeMs}ms'),
              _buildTableCell(_formatLastChecked(entry.value.lastCheckTime)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTableHeader(String text) {
    return Padding(
      padding: EdgeInsets.all(2.w),
      child: Text(
        text,
        style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildTableCell(String text) {
    return Padding(
      padding: EdgeInsets.all(2.w),
      child: Text(text, style: TextStyle(fontSize: 11.sp)),
    );
  }

  Widget _buildStatusCell(String status) {
    final isHealthy = status == 'healthy';
    return Padding(
      padding: EdgeInsets.all(2.w),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
        decoration: BoxDecoration(
          color: isHealthy ? Colors.green.shade100 : Colors.red.shade100,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          status.toUpperCase(),
          style: TextStyle(
            fontSize: 10.sp,
            fontWeight: FontWeight.w600,
            color: isHealthy ? Colors.green.shade700 : Colors.red.shade700,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildHealthCheckInfo() {
    return Container(
      padding: EdgeInsets.all(2.w),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.blue, size: 20.sp),
          SizedBox(width: 2.w),
          Expanded(
            child: Text(
              'Automated health checks run every 30 seconds. '
              'Failure detection threshold: 2 seconds.',
              style: TextStyle(fontSize: 11.sp, color: Colors.blue.shade900),
            ),
          ),
        ],
      ),
    );
  }

  String _formatLastChecked(DateTime lastChecked) {
    final diff = DateTime.now().difference(lastChecked);
    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    return '${diff.inHours}h ago';
  }
}
