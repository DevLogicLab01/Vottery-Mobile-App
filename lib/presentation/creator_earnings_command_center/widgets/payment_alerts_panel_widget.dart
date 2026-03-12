import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../framework/shared_constants.dart';
import '../../../services/platform_analytics_service.dart';
import '../../../services/supabase_service.dart';

/// Payment & settlement alerts panel (sync with Web PaymentAlertsPanel).
/// Shows settlement_processing, payout_delayed, payment_method_failed, payout_completed from activity_feed.
class PaymentAlertsPanelWidget extends StatefulWidget {
  const PaymentAlertsPanelWidget({super.key});

  @override
  State<PaymentAlertsPanelWidget> createState() =>
      _PaymentAlertsPanelWidgetState();
}

class _PaymentAlertsPanelWidgetState extends State<PaymentAlertsPanelWidget> {
  final PlatformAnalyticsService _analytics =
      PlatformAnalyticsService.instance;
  List<Map<String, dynamic>> _notifications = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final userId = SupabaseService.instance.client.auth.currentUser?.id;
    if (userId == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    setState(() => _loading = true);
    try {
      final list = await _analytics.getPaymentNotifications(
        userId: userId,
        limit: 20,
      );
      if (mounted) setState(() {
        _notifications = list;
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  static String _label(String? activityType) {
    switch (activityType) {
      case 'settlement_processing':
        return 'Settlement processing';
      case 'payout_delayed':
        return 'Payout delayed';
      case 'payment_method_failed':
        return 'Payment method failed';
      case 'payout_completed':
        return 'Payout completed';
      default:
        return activityType ?? 'Payment update';
    }
  }

  static IconData _icon(String? activityType) {
    switch (activityType) {
      case 'settlement_processing':
        return Icons.schedule;
      case 'payout_delayed':
        return Icons.warning_amber_rounded;
      case 'payment_method_failed':
        return Icons.error_outline;
      case 'payout_completed':
        return Icons.check_circle_outline;
      default:
        return Icons.notifications_outlined;
    }
  }

  static Color _color(BuildContext context, String? activityType) {
    switch (activityType) {
      case 'settlement_processing':
        return Colors.blue;
      case 'payout_delayed':
        return Colors.amber;
      case 'payment_method_failed':
        return Colors.red;
      case 'payout_completed':
        return Colors.green;
      default:
        return Theme.of(context).colorScheme.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(4.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.notifications_outlined, size: 32.sp, color: Colors.grey),
              SizedBox(height: 2.h),
              Text(
                'Loading payment alerts…',
                style: TextStyle(fontSize: 12.sp, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: EdgeInsets.all(3.w),
        children: [
          Row(
            children: [
              Icon(Icons.credit_card, size: 20.sp, color: Colors.grey[700]),
              SizedBox(width: 2.w),
              Text(
                'Payment & settlement alerts',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Text(
            'Notifications for settlement processing, payout delays, and payment method failures. These also appear in the Notification Center.',
            style: TextStyle(fontSize: 11.sp, color: Colors.grey[600]),
          ),
          SizedBox(height: 2.h),
          if (_notifications.isEmpty)
            Container(
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(12),
                color: Colors.grey[50],
              ),
              child: Column(
                children: [
                  Icon(Icons.notifications_none, size: 36.sp, color: Colors.grey),
                  SizedBox(height: 1.h),
                  Text(
                    'No payment alerts yet.',
                    style: TextStyle(fontSize: 13.sp, color: Colors.grey[700]),
                  ),
                  SizedBox(height: 0.5.h),
                  Text(
                    'You’ll see updates here when payouts are processing, delayed, or if a payment method fails.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11.sp, color: Colors.grey[600]),
                  ),
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _notifications.length,
              separatorBuilder: (_, __) => SizedBox(height: 1.h),
              itemBuilder: (context, index) {
                final n = _notifications[index];
                final activityType =
                    n['activity_type'] as String?;
                final title = n['title'] as String? ?? _label(activityType);
                final description = n['description'] as String?;
                final isRead = n['is_read'] as bool? ?? false;
                final createdAt = n['created_at'] as String?;
                final color = _color(context, activityType);
                return Container(
                  padding: EdgeInsets.all(3.w),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: EdgeInsets.all(2.w),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(_icon(activityType), color: color, size: 22.sp),
                      ),
                      SizedBox(width: 3.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    title,
                                    style: TextStyle(
                                      fontSize: 13.sp,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  if (!isRead)
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 2.w,
                                        vertical: 0.3.h,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.amber.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        'New',
                                        style: TextStyle(
                                          fontSize: 10.sp,
                                          color: Colors.amber[800],
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            if (description != null && description.isNotEmpty) ...[
                              SizedBox(height: 0.5.h),
                              Text(
                                description,
                                style: TextStyle(
                                  fontSize: 11.sp,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ],
                            if (createdAt != null) ...[
                              SizedBox(height: 0.5.h),
                              Text(
                                _formatDate(createdAt),
                                style: TextStyle(
                                  fontSize: 10.sp,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  String _formatDate(String iso) {
    try {
      final d = DateTime.parse(iso);
      return '${d.day}/${d.month}/${d.year} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return iso;
    }
  }
}
