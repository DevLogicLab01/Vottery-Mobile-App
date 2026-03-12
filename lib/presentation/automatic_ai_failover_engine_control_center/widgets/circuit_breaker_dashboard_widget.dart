import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class CircuitBreakerDashboardWidget extends StatelessWidget {
  final Map<String, dynamic> circuitStates;
  final Function(String provider) onResetCircuit;

  const CircuitBreakerDashboardWidget({
    super.key,
    required this.circuitStates,
    required this.onResetCircuit,
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
              'Circuit Breaker Dashboard',
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 1.h),
            Text(
              '2-second failure detection threshold',
              style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
            ),
            SizedBox(height: 2.h),
            ...['openai', 'anthropic', 'perplexity', 'gemini'].map((provider) {
              final state =
                  circuitStates[provider] ?? {'state': 'closed', 'failures': 0};
              return _buildCircuitCard(context, provider, state);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildCircuitCard(
    BuildContext context,
    String provider,
    Map<String, dynamic> state,
  ) {
    final circuitState = state['state'] ?? 'closed';
    final failures = state['failures'] ?? 0;
    final color = circuitState == 'open'
        ? Colors.red
        : circuitState == 'half-open'
        ? Colors.orange
        : Colors.green;

    return Card(
      margin: EdgeInsets.only(bottom: 1.h),
      child: Padding(
        padding: EdgeInsets.all(2.w),
        child: Row(
          children: [
            Icon(
              circuitState == 'open'
                  ? Icons.cancel
                  : circuitState == 'half-open'
                  ? Icons.warning
                  : Icons.check_circle,
              color: color,
              size: 24.sp,
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    provider.toUpperCase(),
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'State: $circuitState | Failures: $failures',
                    style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            if (circuitState == 'open')
              ElevatedButton(
                onPressed: () => onResetCircuit(provider),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                ),
                child: const Text('Reset'),
              ),
          ],
        ),
      ),
    );
  }
}
