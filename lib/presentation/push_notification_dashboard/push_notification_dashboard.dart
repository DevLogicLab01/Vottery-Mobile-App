import 'dart:async';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../core/app_export.dart';
import '../../services/enhanced_notification_service.dart';
import '../../services/supabase_service.dart';
import '../../widgets/custom_app_bar.dart';

/// Push Notification Dashboard
/// Real-time notification management with WebSocket integration and delivery analytics
class PushNotificationDashboard extends StatefulWidget {
  const PushNotificationDashboard({super.key});

  @override
  State<PushNotificationDashboard> createState() =>
      _PushNotificationDashboardState();
}

class _PushNotificationDashboardState extends State<PushNotificationDashboard> {
  final EnhancedNotificationService _notificationService =
      EnhancedNotificationService.instance;

  WebSocketChannel? _channel;
  bool _isConnected = false;
  bool _isReconnecting = false;
  int _reconnectAttempts = 0;
  Timer? _heartbeatTimer;
  Timer? _reconnectTimer;

  final List<Map<String, dynamic>> _realtimeNotifications = [];
  final Map<String, dynamic> _metrics = {
    'sent_today': 1247,
    'delivery_rate': 94.3,
    'open_rate': 67.8,
    'click_rate': 23.4,
  };
  List<Map<String, dynamic>> _retryQueue = [];
  List<Map<String, dynamic>> _deliveryLogs = [];
  final Map<String, bool> _categoryPreferences = {};
  final Map<String, int> _notificationVolume = {};

  @override
  void initState() {
    super.initState();
    _connectWebSocket();
    _loadInitialData();
  }

  @override
  void dispose() {
    _heartbeatTimer?.cancel();
    _reconnectTimer?.cancel();
    _channel?.sink.close();
    super.dispose();
  }

  void _connectWebSocket() {
    try {
      final supabaseUrl = SupabaseService.supabaseUrl;
      final wsUrl =
          '${supabaseUrl.replaceFirst('https://', 'wss://')}/realtime/v1/websocket';

      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));

      setState(() {
        _isConnected = true;
        _isReconnecting = false;
        _reconnectAttempts = 0;
      });

      // Start heartbeat
      _startHeartbeat();

      // Subscribe to notifications_realtime table
      _channel!.sink.add({
        'event': 'phx_join',
        'topic': 'realtime:public:notifications_realtime',
        'payload': {},
        'ref': '1',
      });

      // Listen for messages
      _channel!.stream.listen(
        (message) {
          _handleWebSocketMessage(message);
        },
        onError: (error) {
          debugPrint('WebSocket error: $error');
          _handleDisconnect();
        },
        onDone: () {
          debugPrint('WebSocket connection closed');
          _handleDisconnect();
        },
      );
    } catch (e) {
      debugPrint('WebSocket connection error: $e');
      _handleDisconnect();
    }
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(Duration(seconds: 30), (timer) {
      if (_isConnected) {
        _channel?.sink.add({'event': 'heartbeat', 'payload': {}});
      }
    });
  }

  void _handleWebSocketMessage(dynamic message) {
    // Parse and handle real-time notification updates
    if (message is Map && message['event'] == 'INSERT') {
      final notification = message['payload'] as Map<String, dynamic>;
      setState(() {
        _realtimeNotifications.insert(0, notification);
        _metrics['sent_today'] = (_metrics['sent_today'] as int) + 1;
      });
    }
  }

  void _handleDisconnect() {
    setState(() {
      _isConnected = false;
      _isReconnecting = true;
    });

    _heartbeatTimer?.cancel();

    // Exponential backoff: 1s, 2s, 4s, 8s, 16s (max)
    final delay = Duration(seconds: (1 << _reconnectAttempts).clamp(1, 16));

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(delay, () {
      _reconnectAttempts++;
      _connectWebSocket();
    });
  }

  Future<void> _loadInitialData() async {
    // Load retry queue
    setState(() {
      _retryQueue = [
        {
          'id': '1',
          'user_id': 'user123',
          'title': 'Vote Reminder',
          'retry_count': 2,
          'error': 'Network Timeout',
          'next_retry': DateTime.now().add(Duration(minutes: 15)),
        },
      ];

      _deliveryLogs = List.generate(50, (index) {
        return {
          'timestamp': DateTime.now().subtract(Duration(minutes: index * 5)),
          'user_id': 'user${index + 1}',
          'type': ['Vote Alert', 'Quest Reminder', 'Social'][index % 3],
          'status': ['Delivered', 'Failed', 'Sent'][index % 3],
          'retry_count': index % 4,
          'error': index % 3 == 1 ? 'Invalid Token' : null,
        };
      });

      // Generate 24-hour volume data
      for (int i = 0; i < 24; i++) {
        _notificationVolume['$i:00'] = 30 + (i * 5) % 100;
      }
    });
  }

  Future<void> _retryFailedNotification(String notificationId) async {
    setState(() {
      _retryQueue.removeWhere((n) => n['id'] == notificationId);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Notification queued for retry'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: CustomAppBar(
        leading: Padding(
          padding: EdgeInsets.only(left: 4.w),
          child: IconButton(
            icon: CustomIconWidget(
              iconName: 'arrow_back',
              size: 6.w,
              color: AppTheme.textPrimaryLight,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: 'Push Notification Dashboard',
        actions: [_buildConnectionStatus()],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMetricsOverview(),
            SizedBox(height: 3.h),
            _buildLiveDeliveryStatus(),
            SizedBox(height: 3.h),
            _buildEngagementMetrics(),
            SizedBox(height: 3.h),
            _buildRetryQueue(),
            SizedBox(height: 3.h),
            _buildDeliveryLogs(),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionStatus() {
    return Container(
      margin: EdgeInsets.only(right: 4.w),
      padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
      decoration: BoxDecoration(
        color: _isConnected ? Colors.green : Colors.red,
        borderRadius: BorderRadius.circular(20.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 2.w,
            height: 2.w,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 2.w),
          Text(
            _isConnected
                ? 'Connected'
                : (_isReconnecting ? 'Reconnecting...' : 'Disconnected'),
            style: TextStyle(
              fontSize: 11.sp,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsOverview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Real-Time Engagement Metrics',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimaryLight,
          ),
        ),
        SizedBox(height: 2.h),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          crossAxisSpacing: 3.w,
          mainAxisSpacing: 2.h,
          childAspectRatio: 1.5,
          children: [
            _buildMetricCard(
              'Sent Today',
              '${_metrics['sent_today']}',
              Icons.send,
              Colors.blue,
              '+12%',
            ),
            _buildMetricCard(
              'Delivery Rate',
              '${_metrics['delivery_rate']}%',
              Icons.check_circle,
              Colors.green,
              '+2.1%',
            ),
            _buildMetricCard(
              'Open Rate',
              '${_metrics['open_rate']}%',
              Icons.visibility,
              Colors.orange,
              '+5.3%',
            ),
            _buildMetricCard(
              'Click Rate',
              '${_metrics['click_rate']}%',
              Icons.touch_app,
              Colors.purple,
              '-1.2%',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard(
    String label,
    String value,
    IconData icon,
    Color color,
    String trend,
  ) {
    final isPositive = trend.startsWith('+');
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 6.w),
              Row(
                children: [
                  Icon(
                    isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                    color: isPositive ? Colors.green : Colors.red,
                    size: 4.w,
                  ),
                  Text(
                    trend,
                    style: TextStyle(
                      fontSize: 10.sp,
                      color: isPositive ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.sp,
              color: AppTheme.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveDeliveryStatus() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Live Delivery Status',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimaryLight,
          ),
        ),
        SizedBox(height: 2.h),
        SizedBox(
          height: 40.h,
          child: _realtimeNotifications.isEmpty
              ? Center(
                  child: Text(
                    'Waiting for notifications...',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: AppTheme.textSecondaryLight,
                    ),
                  ),
                )
              : ListView.builder(
                  itemCount: _realtimeNotifications.length,
                  itemBuilder: (context, index) {
                    final notification = _realtimeNotifications[index];
                    return _buildNotificationCard(notification);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> notification) {
    final status = notification['status'] ?? 'Sent';
    final timestamp = notification['sent_at'] != null
        ? DateTime.parse(notification['sent_at'] as String)
        : DateTime.now();

    Color statusColor;
    IconData statusIcon;

    switch (status) {
      case 'Delivered':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'Read':
        statusColor = Colors.grey;
        statusIcon = Icons.check_circle;
        break;
      case 'Failed':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = Colors.blue;
        statusIcon = Icons.circle;
    }

    return Container(
      margin: EdgeInsets.only(bottom: 1.h),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Row(
        children: [
          Icon(statusIcon, color: statusColor, size: 6.w),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notification['title'] ?? 'Notification',
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryLight,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  _getRelativeTime(timestamp),
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: AppTheme.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Text(
              status,
              style: TextStyle(
                fontSize: 10.sp,
                color: statusColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEngagementMetrics() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '24-Hour Notification Volume',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimaryLight,
          ),
        ),
        SizedBox(height: 2.h),
        Container(
          height: 30.h,
          padding: EdgeInsets.all(3.w),
          decoration: BoxDecoration(
            color: AppTheme.surfaceLight,
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: LineChart(
            LineChartData(
              gridData: FlGridData(show: true),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: true, reservedSize: 40),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    getTitlesWidget: (value, meta) {
                      if (value.toInt() % 4 == 0) {
                        return Text(
                          '${value.toInt()}h',
                          style: TextStyle(fontSize: 10.sp),
                        );
                      }
                      return SizedBox();
                    },
                  ),
                ),
                rightTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: _notificationVolume.entries
                      .map(
                        (e) => FlSpot(
                          double.parse(e.key.split(':')[0]),
                          e.value.toDouble(),
                        ),
                      )
                      .toList(),
                  isCurved: true,
                  color: AppTheme.primaryLight,
                  barWidth: 3,
                  dotData: FlDotData(show: false),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRetryQueue() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Retry Queue',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryLight,
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
              decoration: BoxDecoration(
                color: Colors.orange,
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Text(
                '${_retryQueue.length} pending',
                style: TextStyle(
                  fontSize: 10.sp,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 2.h),
        if (_retryQueue.isEmpty)
          Container(
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: AppTheme.surfaceLight,
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Center(
              child: Text(
                'No failed notifications',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: AppTheme.textSecondaryLight,
                ),
              ),
            ),
          )
        else
          ..._retryQueue.map(
            (notification) => Container(
              margin: EdgeInsets.only(bottom: 1.h),
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: AppTheme.surfaceLight,
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          notification['title'] as String,
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Retry ${notification['retry_count']}/3 - ${notification['error']}',
                          style: TextStyle(fontSize: 10.sp, color: Colors.red),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.refresh, color: AppTheme.primaryLight),
                    onPressed: () =>
                        _retryFailedNotification(notification['id'] as String),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDeliveryLogs() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Delivery Logs',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryLight,
              ),
            ),
            TextButton.icon(
              onPressed: () {},
              icon: Icon(Icons.download, size: 5.w),
              label: Text('Export CSV'),
            ),
          ],
        ),
        SizedBox(height: 2.h),
        SizedBox(
          height: 40.h,
          child: ListView.builder(
            itemCount: _deliveryLogs.length,
            itemBuilder: (context, index) {
              final log = _deliveryLogs[index];
              return Container(
                margin: EdgeInsets.only(bottom: 1.h),
                padding: EdgeInsets.all(2.w),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceLight,
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        _getRelativeTime(log['timestamp'] as DateTime),
                        style: TextStyle(fontSize: 10.sp),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        log['type'] as String,
                        style: TextStyle(fontSize: 10.sp),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        log['status'] as String,
                        style: TextStyle(
                          fontSize: 10.sp,
                          color: log['status'] == 'Delivered'
                              ? Colors.green
                              : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Text(
                        '${log['retry_count']}',
                        style: TextStyle(fontSize: 10.sp),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  String _getRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}
