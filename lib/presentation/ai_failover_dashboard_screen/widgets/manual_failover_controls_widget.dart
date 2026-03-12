import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../services/ai_health_monitor_service.dart';

class ManualFailoverControlsWidget extends StatelessWidget {
  final Map<String, ServiceHealthStatus> serviceHealth;
  final Function({required String fromService, required String toService})
  onTriggerFailover;

  const ManualFailoverControlsWidget({
    super.key,
    required this.serviceHealth,
    required this.onTriggerFailover,
  });

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
              'Manual Failover Controls',
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 1.h),
            Text(
              'Instant zero-downtime traffic switching',
              style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
            ),
            SizedBox(height: 2.h),
            Wrap(
              spacing: 2.w,
              runSpacing: 1.h,
              children: [
                _buildFailoverButton(
                  context,
                  'OpenAI → Gemini',
                  'openai',
                  'gemini',
                  Colors.green,
                ),
                _buildFailoverButton(
                  context,
                  'Anthropic → Gemini',
                  'anthropic',
                  'gemini',
                  Colors.orange,
                ),
                _buildFailoverButton(
                  context,
                  'Perplexity → Gemini',
                  'perplexity',
                  'gemini',
                  Colors.blue,
                ),
                _buildFailoverButton(
                  context,
                  'All → Gemini',
                  'all',
                  'gemini',
                  Colors.red,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFailoverButton(
    BuildContext context,
    String label,
    String from,
    String to,
    Color color,
  ) {
    return ElevatedButton(
      onPressed: () => _confirmFailover(context, from, to),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
      ),
      child: Text(label, style: TextStyle(fontSize: 12.sp)),
    );
  }

  Future<void> _confirmFailover(
    BuildContext context,
    String from,
    String to,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Manual Failover'),
        content: Text(
          'Switch traffic from $from to $to?\n\n'
          'This will immediately redirect all AI requests with zero downtime.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      onTriggerFailover(fromService: from, toService: to);
    }
  }
}
