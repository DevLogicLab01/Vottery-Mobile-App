import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../services/push_notification_intelligence_service.dart';

class DeliverySchedulingWidget extends StatefulWidget {
  final VoidCallback onScheduleUpdated;
  final String? userId;

  const DeliverySchedulingWidget({
    super.key,
    required this.onScheduleUpdated,
    this.userId,
  });

  @override
  State<DeliverySchedulingWidget> createState() =>
      _DeliverySchedulingWidgetState();
}

class _DeliverySchedulingWidgetState extends State<DeliverySchedulingWidget> {
  Map<String, dynamic>? _optimalTiming;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _fetchOptimalTiming();
  }

  Future<void> _fetchOptimalTiming() async {
    final userId = widget.userId;
    if (userId == null) return;
    setState(() => _loading = true);
    try {
      final result = await PushNotificationIntelligenceService.instance
          .getSmartPushOptimalTime(userId);
      if (mounted) {
        setState(() {
          _optimalTiming = result;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Delivery Scheduling',
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 2.h),
            Text(
              'Optimal timing based on user activity patterns with timezone awareness',
              style: TextStyle(fontSize: 12.sp, color: Colors.grey),
            ),
            SizedBox(height: 2.h),
            if (_loading)
              const Center(child: CircularProgressIndicator())
            else
              Row(
                children: [
                  Icon(Icons.schedule, color: Colors.blue, size: 24),
                  SizedBox(width: 2.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Smart Scheduling: Enabled',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (_optimalTiming != null) ...[
                          SizedBox(height: 0.5.h),
                          Text(
                            'Optimal hour: ${_optimalTiming!['optimalHour'] ?? '—'} · Confidence: ${_optimalTiming!['confidence'] ?? '—'}',
                            style: TextStyle(
                              fontSize: 11.sp,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 44,
                    child: IconButton(
                      onPressed: _fetchOptimalTiming,
                      icon: const Icon(Icons.refresh),
                      tooltip: 'Refresh optimal timing',
                      style: IconButton.styleFrom(
                        minimumSize: const Size(44, 44),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
