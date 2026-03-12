import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../services/realtime_gamification_notification_service.dart'
    as gamification;
import '../../services/realtime_gamification_notification_service.dart'
    show RetryConfig;
import './widgets/connection_status_badge_widget.dart';
import './widgets/offline_queue_panel_widget.dart';
import './widgets/retry_config_panel_widget.dart';
import './widgets/subscription_health_card_widget.dart';

class RealtimeGamificationErrorRecoveryHub extends StatefulWidget {
  const RealtimeGamificationErrorRecoveryHub({super.key});

  @override
  State<RealtimeGamificationErrorRecoveryHub> createState() =>
      _RealtimeGamificationErrorRecoveryHubState();
}

class _RealtimeGamificationErrorRecoveryHubState
    extends State<RealtimeGamificationErrorRecoveryHub> {
  final _service =
      gamification.RealtimeGamificationNotificationService.instance;
  bool _isReconnecting = false;
  gamification.ConnectionState _connectionState =
      gamification.ConnectionState.disconnected;

  final List<Map<String, dynamic>> _subscriptions = [
    {
      'name': 'VP Transactions',
      'table': 'user_vp_transactions',
      'status': 'connected',
      'retries': 0,
      'lastEvent': 'Just now',
    },
    {
      'name': 'Quests',
      'table': 'user_quests',
      'status': 'connected',
      'retries': 0,
      'lastEvent': '2 min ago',
    },
    {
      'name': 'Achievements',
      'table': 'user_achievements',
      'status': 'connected',
      'retries': 0,
      'lastEvent': '5 min ago',
    },
    {
      'name': 'Streaks',
      'table': 'user_streaks',
      'status': 'connected',
      'retries': 0,
      'lastEvent': '1 hour ago',
    },
    {
      'name': 'Leaderboards',
      'table': 'leaderboard_positions',
      'status': 'connected',
      'retries': 0,
      'lastEvent': '30 min ago',
    },
  ];

  @override
  void initState() {
    super.initState();
    _connectionState = _service.connectionState;
    _service.connectionStateStream.listen((state) {
      if (mounted) {
        setState(() {
          _connectionState = state;
          if (state == gamification.ConnectionState.connected) {
            _isReconnecting = false;
            for (final sub in _subscriptions) {
              sub['status'] = 'connected';
            }
          } else if (state == gamification.ConnectionState.disconnected) {
            _isReconnecting = false;
          }
        });
      }
    });
  }

  Future<void> _triggerReconnect() async {
    setState(() {
      _isReconnecting = true;
      for (final sub in _subscriptions) {
        sub['status'] = 'reconnecting';
      }
    });
    await _service.reconnectAllSubscriptions();
    if (mounted) {
      setState(() {
        _isReconnecting = false;
        for (final sub in _subscriptions) {
          sub['status'] = 'connected';
          sub['retries'] = (sub['retries'] as int) + 1;
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ All subscriptions reconnected'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _flushQueue() async {
    await _service.offlineQueue.flushAll();
    if (mounted) setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('📤 Offline queue flushed'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  Color get _connectionColor {
    switch (_connectionState) {
      case gamification.ConnectionState.connected:
        return Colors.green;
      case gamification.ConnectionState.disconnected:
        return Colors.red;
      case gamification.ConnectionState.reconnecting:
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String get _connectionLabel {
    switch (_connectionState) {
      case gamification.ConnectionState.connected:
        return 'CONNECTED';
      case gamification.ConnectionState.disconnected:
        return 'DISCONNECTED';
      case gamification.ConnectionState.reconnecting:
        return 'RECONNECTING';
      default:
        return 'UNKNOWN';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Error Recovery Hub',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            fontSize: 16.sp,
          ),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: ConnectionStatusBadgeWidget(),
          ),
        ],
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
      ),
      backgroundColor: Colors.grey[50],
      body: SingleChildScrollView(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Connection Status Overview
            _buildConnectionStatusCard(),
            SizedBox(height: 2.h),

            // Subscription Health Monitor
            Text(
              'Subscription Health Monitor',
              style: GoogleFonts.inter(
                fontSize: 14.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 1.h),
            ..._subscriptions.map(
              (sub) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: SubscriptionHealthCardWidget(
                  subscriptionName: sub['name'] as String,
                  status: sub['status'] as String,
                  retryCount: sub['retries'] as int,
                  lastEvent: sub['lastEvent'] as String,
                  onRetry: _triggerReconnect,
                ),
              ),
            ),
            SizedBox(height: 2.h),

            // Retry Configuration
            RetryConfigPanelWidget(config: RetryConfig()),
            SizedBox(height: 2.h),

            // Offline Queue
            OfflineQueuePanelWidget(
              queue: _service.offlineQueue,
              onFlush: _flushQueue,
            ),
            SizedBox(height: 2.h),

            // Error Recovery Controls
            _buildRecoveryControls(),
            SizedBox(height: 2.h),

            // Error Boundary Info
            _buildErrorBoundaryInfo(),
            SizedBox(height: 4.h),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionStatusCard() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
        side: BorderSide(color: _connectionColor.withAlpha(77), width: 1.5),
      ),
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: _connectionColor,
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: 2.w),
                Text(
                  'Connection Status: $_connectionLabel',
                  style: GoogleFonts.inter(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    color: _connectionColor,
                  ),
                ),
              ],
            ),
            SizedBox(height: 1.5.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  'Active',
                  '${_subscriptions.where((s) => s['status'] == 'connected').length}',
                  Colors.green,
                ),
                _buildStatItem(
                  'Errors',
                  '${_subscriptions.where((s) => s['status'] == 'error').length}',
                  Colors.red,
                ),
                _buildStatItem(
                  'Queued',
                  '${_service.offlineQueue.length}',
                  Colors.orange,
                ),
                _buildStatItem(
                  'Channels',
                  '${_subscriptions.length}',
                  Colors.blue,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 18.sp,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 10.sp, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildRecoveryControls() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.build, color: Colors.purple[600], size: 20),
                SizedBox(width: 2.w),
                Text(
                  'Error Recovery Controls',
                  style: GoogleFonts.inter(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            SizedBox(height: 2.h),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isReconnecting ? null : _triggerReconnect,
                    icon: _isReconnecting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.refresh, size: 16),
                    label: Text(
                      _isReconnecting ? 'Reconnecting...' : 'Reconnect All',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[600],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await _service.reconnectAllSubscriptions();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('🔄 Subscriptions reset'),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.restart_alt, size: 16),
                    label: Text(
                      'Reset Subs',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                    ),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
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

  Widget _buildErrorBoundaryInfo() {
    return Card(
      elevation: 2,
      color: Colors.red[50],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
        side: BorderSide(color: Colors.red[200]!, width: 1),
      ),
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.signal_wifi_off, color: Colors.red[600], size: 20),
                SizedBox(width: 2.w),
                Text(
                  'RealtimeErrorBoundary',
                  style: GoogleFonts.inter(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.red[700],
                  ),
                ),
              ],
            ),
            SizedBox(height: 1.h),
            Text(
              'Gamification notifications temporarily unavailable',
              style: GoogleFonts.inter(fontSize: 12.sp, color: Colors.red[600]),
            ),
            SizedBox(height: 1.5.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _triggerReconnect,
                icon: const Icon(Icons.refresh, size: 16),
                label: Text(
                  'Retry Connection',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[600],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}