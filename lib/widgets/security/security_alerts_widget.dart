import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:awesome_notifications/awesome_notifications.dart';

import '../../models/security_alert.dart';
import './security_alert_tile.dart';

class SecurityAlertsWidget extends StatefulWidget {
  const SecurityAlertsWidget({super.key});

  @override
  State<SecurityAlertsWidget> createState() => _SecurityAlertsWidgetState();
}

class _SecurityAlertsWidgetState extends State<SecurityAlertsWidget> {
  StreamSubscription<List<Map<String, dynamic>>>? _alertsSubscription;
  List<SecurityAlert> alerts = [];
  bool _isLoading = true;
  final SupabaseClient supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _setupNotificationChannel();
    _setupRealTimeAlerts();
  }

  @override
  void dispose() {
    _alertsSubscription?.cancel();
    super.dispose();
  }

  Future<void> _setupNotificationChannel() async {
    await AwesomeNotifications().initialize(null, [
      NotificationChannel(
        channelKey: 'security_alerts',
        channelName: 'Security Alerts',
        channelDescription: 'Critical security notifications',
        defaultColor: Colors.red,
        ledColor: Colors.red,
        importance: NotificationImportance.Max,
        channelShowBadge: true,
        playSound: true,
        enableVibration: true,
      ),
    ]);

    await AwesomeNotifications().isNotificationAllowed().then((isAllowed) {
      if (!isAllowed) {
        AwesomeNotifications().requestPermissionToSendNotifications();
      }
    });
  }

  void _setupRealTimeAlerts() {
    try {
      _alertsSubscription = supabase
          .from('security_incidents')
          .stream(primaryKey: ['id'])
          .order('timestamp', ascending: false)
          .limit(50)
          .listen(
            (data) {
              final newAlerts = data
                  .map((e) => SecurityAlert.fromJson(e))
                  .toList();
              setState(() {
                alerts = newAlerts;
                _isLoading = false;
              });

              // Trigger push notification for critical alerts
              final criticalAlerts = newAlerts.where(
                (a) => a.severity == 'critical',
              );
              for (final alert in criticalAlerts) {
                if (!alert.acknowledged) {
                  _showCriticalAlertNotification(alert);
                }
              }
            },
            onError: (error) {
              setState(() {
                _isLoading = false;
              });
            },
          );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _showCriticalAlertNotification(SecurityAlert alert) async {
    try {
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: alert.id.hashCode,
          channelKey: 'security_alerts',
          title: 'Critical Security Alert',
          body: alert.description,
          category: NotificationCategory.Alarm,
          wakeUpScreen: true,
          criticalAlert: true,
          notificationLayout: NotificationLayout.Default,
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      // Silent fail for notification errors
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return Card(
        child: Padding(
          padding: EdgeInsets.all(4.w),
          child: const Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return Card(
      child: Column(
        children: [
          ListTile(
            leading: Icon(Icons.security, color: Colors.red),
            title: Text(
              'Security Alerts',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.sp),
            ),
            subtitle: Text(
              '${alerts.length} active alerts',
              style: TextStyle(fontSize: 11.sp),
            ),
            trailing: _buildAlertSummary(),
          ),
          const Divider(height: 1),
          if (alerts.isEmpty)
            Padding(
              padding: EdgeInsets.all(4.w),
              child: Column(
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 48,
                    color: Colors.green,
                  ),
                  SizedBox(height: 1.h),
                  Text(
                    'No active security alerts',
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            )
          else
            ...alerts.map(
              (alert) => SecurityAlertTile(
                alert: alert,
                onTap: () => _handleAlertTap(alert),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAlertSummary() {
    final criticalCount = alerts.where((a) => a.severity == 'critical').length;
    final highCount = alerts.where((a) => a.severity == 'high').length;

    if (criticalCount > 0) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(color: Colors.red),
        ),
        child: Text(
          '$criticalCount Critical',
          style: TextStyle(
            fontSize: 11.sp,
            fontWeight: FontWeight.bold,
            color: Colors.red,
          ),
        ),
      );
    } else if (highCount > 0) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
        decoration: BoxDecoration(
          color: Colors.orange.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(color: Colors.orange),
        ),
        child: Text(
          '$highCount High',
          style: TextStyle(
            fontSize: 11.sp,
            fontWeight: FontWeight.bold,
            color: Colors.orange,
          ),
        ),
      );
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.green),
      ),
      child: Text(
        'All Clear',
        style: TextStyle(
          fontSize: 11.sp,
          fontWeight: FontWeight.bold,
          color: Colors.green,
        ),
      ),
    );
  }

  void _handleAlertTap(SecurityAlert alert) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(alert.type),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Severity: ${alert.severity.toUpperCase()}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: _getSeverityColor(alert.severity),
              ),
            ),
            SizedBox(height: 1.h),
            Text(alert.description),
            SizedBox(height: 1.h),
            Text(
              'Timestamp: ${alert.timestamp}',
              style: TextStyle(fontSize: 11.sp, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              _acknowledgeAlert(alert);
              Navigator.pop(context);
            },
            child: const Text('Acknowledge'),
          ),
        ],
      ),
    );
  }

  Future<void> _acknowledgeAlert(SecurityAlert alert) async {
    try {
      await supabase
          .from('security_incidents')
          .update({'acknowledged': true})
          .eq('id', alert.id);
    } catch (e) {
      // Silent fail
    }
  }

  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'critical':
        return Colors.red;
      case 'high':
        return Colors.orange;
      case 'medium':
        return Colors.yellow[700]!;
      case 'low':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}
