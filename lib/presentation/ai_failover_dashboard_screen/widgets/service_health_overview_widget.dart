import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../services/ai_health_monitor_service.dart';

class ServiceHealthOverviewWidget extends StatelessWidget {
  final Map<String, ServiceHealthStatus> serviceHealth;

  const ServiceHealthOverviewWidget({super.key, required this.serviceHealth});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Service Health Overview',
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 2.h),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 2.w,
              mainAxisSpacing: 2.h,
              childAspectRatio: 1.5,
              children: [
                _buildServiceCard(
                  'OpenAI',
                  serviceHealth['openai'],
                  Colors.green,
                ),
                _buildServiceCard(
                  'Anthropic',
                  serviceHealth['anthropic'],
                  Colors.orange,
                ),
                _buildServiceCard(
                  'Perplexity',
                  serviceHealth['perplexity'],
                  Colors.blue,
                ),
                _buildServiceCard(
                  'Gemini',
                  serviceHealth['gemini'],
                  Colors.purple,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceCard(
    String name,
    ServiceHealthStatus? health,
    Color color,
  ) {
    final isHealthy = health?.status == 'healthy';
    final latency = health?.responseTimeMs ?? 0;

    return Container(
      padding: EdgeInsets.all(2.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: isHealthy ? Colors.green : Colors.red,
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 5,
                backgroundColor: isHealthy ? Colors.green : Colors.red,
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: Text(
                  name,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          Text(
            '${latency}ms',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: _getLatencyColor(latency),
            ),
          ),
          Text(
            health?.status.toUpperCase() ?? 'UNKNOWN',
            style: TextStyle(fontSize: 10.sp, color: Colors.grey),
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
}
