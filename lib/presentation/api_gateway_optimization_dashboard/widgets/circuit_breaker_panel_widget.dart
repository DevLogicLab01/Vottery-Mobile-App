import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../services/api_gateway_service.dart';
import '../../../theme/app_theme.dart';

class CircuitBreakerPanelWidget extends StatefulWidget {
  final List<Map<String, dynamic>> circuitBreakers;
  final VoidCallback onUpdate;

  const CircuitBreakerPanelWidget({
    super.key,
    required this.circuitBreakers,
    required this.onUpdate,
  });

  @override
  State<CircuitBreakerPanelWidget> createState() =>
      _CircuitBreakerPanelWidgetState();
}

class _CircuitBreakerPanelWidgetState extends State<CircuitBreakerPanelWidget> {
  final APIGatewayService _gatewayService = APIGatewayService();
  String? _updatingService;

  Future<void> _updateCircuitState(String serviceName, String newState) async {
    setState(() => _updatingService = serviceName);
    try {
      await _gatewayService.updateCircuitBreakerState(serviceName, newState);
      widget.onUpdate();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Circuit breaker updated to $newState state')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update circuit breaker: $e')),
        );
      }
    } finally {
      setState(() => _updatingService = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.all(4.w),
      children: [
        Text(
          'Circuit Breaker Status',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimaryLight,
          ),
        ),
        SizedBox(height: 2.h),
        if (widget.circuitBreakers.isEmpty)
          Center(
            child: Padding(
              padding: EdgeInsets.all(4.h),
              child: Text(
                'No circuit breakers configured',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: AppTheme.textSecondaryLight,
                ),
              ),
            ),
          )
        else
          ...widget.circuitBreakers.map((breaker) {
            final serviceName = breaker['service_name'] ?? 'Unknown Service';
            final state = breaker['state'] ?? 'unknown';
            final failureCount = breaker['failure_count'] ?? 0;
            final lastFailure = breaker['last_failure_at'];
            final failureThreshold = breaker['failure_threshold'] ?? 50;
            final timeoutSeconds = breaker['timeout_period_seconds'] ?? 60;

            return Padding(
              padding: EdgeInsets.only(bottom: 2.h),
              child: _buildCircuitBreakerCard(
                serviceName,
                state,
                failureCount,
                lastFailure,
                failureThreshold,
                timeoutSeconds,
              ),
            );
          }),
      ],
    );
  }

  Widget _buildCircuitBreakerCard(
    String serviceName,
    String state,
    int failureCount,
    String? lastFailure,
    int failureThreshold,
    int timeoutSeconds,
  ) {
    final isUpdating = _updatingService == serviceName;
    final stateColor = state == 'closed'
        ? Colors.green
        : state == 'open'
        ? Colors.red
        : Colors.orange;

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: stateColor.withAlpha(77), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 10.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  serviceName,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryLight,
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.5.h),
                decoration: BoxDecoration(
                  color: stateColor.withAlpha(51),
                  borderRadius: BorderRadius.circular(20.0),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      state == 'closed'
                          ? Icons.check_circle
                          : state == 'open'
                          ? Icons.cancel
                          : Icons.warning,
                      size: 14.sp,
                      color: stateColor,
                    ),
                    SizedBox(width: 1.w),
                    Text(
                      state.toUpperCase(),
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.bold,
                        color: stateColor,
                      ),
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
                child: _buildInfoItem(
                  'Failures',
                  '$failureCount / $failureThreshold',
                  Icons.error_outline,
                ),
              ),
              Expanded(
                child: _buildInfoItem(
                  'Timeout',
                  '${timeoutSeconds}s',
                  Icons.timer,
                ),
              ),
            ],
          ),
          if (lastFailure != null) ...[
            SizedBox(height: 1.h),
            Text(
              'Last failure: ${_formatTimestamp(lastFailure)}',
              style: TextStyle(
                fontSize: 11.sp,
                color: AppTheme.textSecondaryLight,
              ),
            ),
          ],
          SizedBox(height: 2.h),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: isUpdating || state == 'open'
                      ? null
                      : () => _updateCircuitState(serviceName, 'open'),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                  ),
                  child: Text(
                    'Open',
                    style: TextStyle(fontSize: 12.sp, color: Colors.red),
                  ),
                ),
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: OutlinedButton(
                  onPressed: isUpdating || state == 'closed'
                      ? null
                      : () => _updateCircuitState(serviceName, 'closed'),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.green),
                  ),
                  child: Text(
                    'Close',
                    style: TextStyle(fontSize: 12.sp, color: Colors.green),
                  ),
                ),
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: ElevatedButton(
                  onPressed: isUpdating
                      ? null
                      : () => _resetCircuit(serviceName),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryLight,
                  ),
                  child: isUpdating
                      ? SizedBox(
                          height: 2.h,
                          width: 2.h,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : Text(
                          'Reset',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 14.sp, color: AppTheme.textSecondaryLight),
        SizedBox(width: 1.w),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11.sp,
                color: AppTheme.textSecondaryLight,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimaryLight,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _resetCircuit(String serviceName) async {
    setState(() => _updatingService = serviceName);
    try {
      await _gatewayService.resetCircuitBreaker(serviceName);
      widget.onUpdate();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Circuit breaker reset successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to reset circuit breaker: $e')),
        );
      }
    } finally {
      setState(() => _updatingService = null);
    }
  }

  String _formatTimestamp(String timestamp) {
    try {
      final dt = DateTime.parse(timestamp);
      final now = DateTime.now();
      final diff = now.difference(dt);

      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      return '${diff.inDays}d ago';
    } catch (e) {
      return timestamp;
    }
  }
}
