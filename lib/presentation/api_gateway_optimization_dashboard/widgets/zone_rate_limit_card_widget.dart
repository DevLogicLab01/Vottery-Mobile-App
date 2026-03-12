import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../services/api_gateway_service.dart';
import '../../../theme/app_theme.dart';

class ZoneRateLimitCardWidget extends StatefulWidget {
  final Map<String, dynamic> zone;
  final VoidCallback onUpdate;

  const ZoneRateLimitCardWidget({
    super.key,
    required this.zone,
    required this.onUpdate,
  });

  @override
  State<ZoneRateLimitCardWidget> createState() =>
      _ZoneRateLimitCardWidgetState();
}

class _ZoneRateLimitCardWidgetState extends State<ZoneRateLimitCardWidget> {
  final APIGatewayService _gatewayService = APIGatewayService();
  bool _isExpanded = false;
  bool _isUpdating = false;

  Future<void> _updateRateLimit(int newLimit) async {
    setState(() => _isUpdating = true);
    try {
      await _gatewayService.updateZoneRateLimit(
        widget.zone['zone_name'],
        newLimit,
      );
      widget.onUpdate();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Rate limit updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update rate limit: $e')),
        );
      }
    } finally {
      setState(() => _isUpdating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final zoneName = widget.zone['zone_name'] ?? 'Unknown Zone';
    final currentLimit = widget.zone['rate_limit'] ?? 0;
    final requestsUsed = widget.zone['requests_used'] ?? 0;
    final throttledCount = widget.zone['throttled_requests'] ?? 0;
    final topEndpoints = (widget.zone['top_endpoints'] as List<dynamic>?) ?? [];

    final usagePercent = currentLimit > 0 ? (requestsUsed / currentLimit) : 0.0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 10.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            child: Padding(
              padding: EdgeInsets.all(4.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          zoneName,
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimaryLight,
                          ),
                        ),
                      ),
                      Icon(
                        _isExpanded ? Icons.expand_less : Icons.expand_more,
                        color: AppTheme.textSecondaryLight,
                      ),
                    ],
                  ),
                  SizedBox(height: 1.h),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Limit: $currentLimit req/min',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: AppTheme.textSecondaryLight,
                          ),
                        ),
                      ),
                      Text(
                        '$requestsUsed / $currentLimit',
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                          color: usagePercent > 0.8
                              ? Colors.red
                              : AppTheme.primaryLight,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 1.h),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4.0),
                    child: LinearProgressIndicator(
                      value: usagePercent,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        usagePercent > 0.8
                            ? Colors.red
                            : usagePercent > 0.6
                            ? Colors.orange
                            : Colors.green,
                      ),
                      minHeight: 8.0,
                    ),
                  ),
                  if (throttledCount > 0) SizedBox(height: 1.h),
                  if (throttledCount > 0)
                    Row(
                      children: [
                        Icon(Icons.block, size: 14.sp, color: Colors.red),
                        SizedBox(width: 1.w),
                        Text(
                          '$throttledCount throttled requests',
                          style: TextStyle(fontSize: 12.sp, color: Colors.red),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
          if (_isExpanded) Divider(height: 1, color: Colors.grey[300]),
          if (_isExpanded)
            Padding(
              padding: EdgeInsets.all(4.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Top Endpoints',
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimaryLight,
                    ),
                  ),
                  SizedBox(height: 1.h),
                  ...topEndpoints.take(5).map((endpoint) {
                    final path = endpoint['endpoint'] ?? 'Unknown';
                    final count = endpoint['request_count'] ?? 0;
                    return Padding(
                      padding: EdgeInsets.only(bottom: 0.5.h),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              path,
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: AppTheme.textSecondaryLight,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            count.toString(),
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimaryLight,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  SizedBox(height: 2.h),
                  ElevatedButton(
                    onPressed: _isUpdating
                        ? null
                        : () => _showRateLimitDialog(currentLimit),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryLight,
                      minimumSize: Size(double.infinity, 5.h),
                    ),
                    child: _isUpdating
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
                            'Adjust Rate Limit',
                            style: TextStyle(
                              fontSize: 13.sp,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _showRateLimitDialog(int currentLimit) {
    double newLimit = currentLimit.toDouble();
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Adjust Rate Limit', style: TextStyle(fontSize: 16.sp)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'New limit: ${newLimit.toInt()} req/min',
                style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 2.h),
              Slider(
                value: newLimit,
                min: 100,
                max: 5000,
                divisions: 49,
                label: newLimit.toInt().toString(),
                onChanged: (value) {
                  setDialogState(() => newLimit = value);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _updateRateLimit(newLimit.toInt());
              },
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }
}
