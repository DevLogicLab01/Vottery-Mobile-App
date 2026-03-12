import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../services/enhanced_ai_orchestrator_service.dart';

class ServiceHealthCardWidget extends StatelessWidget {
  final String provider;
  final ServiceHealthStatus? health;
  final VoidCallback onManualFailover;

  const ServiceHealthCardWidget({
    super.key,
    required this.provider,
    required this.health,
    required this.onManualFailover,
  });

  @override
  Widget build(BuildContext context) {
    final isHealthy = health?.status == 'healthy';
    final latency = health?.avgResponseTimeMs ?? 0;
    final lastChecked = health?.lastCheckTime;

    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isHealthy ? Colors.green : Colors.red,
          width: 2,
        ),
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: isHealthy ? Colors.green : Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: Text(
                  provider.toUpperCase(),
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.swap_horiz, size: 20),
                onPressed: onManualFailover,
                tooltip: 'Manual Failover',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${latency}ms',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: _getLatencyColor(latency),
                ),
              ),
              Text(
                'Latency',
                style: TextStyle(fontSize: 10.sp, color: Colors.grey),
              ),
            ],
          ),
          if (lastChecked != null)
            Text(
              _formatLastChecked(lastChecked),
              style: TextStyle(fontSize: 9.sp, color: Colors.grey),
            ),
        ],
      ),
    );
  }

  Color _getLatencyColor(int latency) {
    if (latency < 500) return Colors.green;
    if (latency < 1000) return Colors.orange;
    return Colors.red;
  }

  String _formatLastChecked(DateTime lastChecked) {
    final diff = DateTime.now().difference(lastChecked);
    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    return '${diff.inHours}h ago';
  }
}
