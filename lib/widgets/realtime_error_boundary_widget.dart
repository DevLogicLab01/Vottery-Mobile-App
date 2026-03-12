import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../services/realtime_gamification_notification_service.dart'
    as rt_service;

/// Error boundary widget wrapping realtime notification subscriptions
class RealtimeErrorBoundary extends StatefulWidget {
  final Widget child;
  final VoidCallback? onRetry;

  const RealtimeErrorBoundary({super.key, required this.child, this.onRetry});

  @override
  State<RealtimeErrorBoundary> createState() => _RealtimeErrorBoundaryState();
}

class _RealtimeErrorBoundaryState extends State<RealtimeErrorBoundary> {
  bool _hasError = false;

  void setError(bool hasError) {
    if (mounted) setState(() => _hasError = hasError);
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return _ErrorCard(
        onRetry: () {
          setError(false);
          widget.onRetry?.call();
        },
      );
    }
    return widget.child;
  }
}

class _ErrorCard extends StatelessWidget {
  final VoidCallback? onRetry;

  const _ErrorCard({this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.orange.shade50,
      margin: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Row(
          children: [
            Icon(
              Icons.signal_wifi_off,
              color: Colors.orange.shade700,
              size: 20,
            ),
            SizedBox(width: 2.w),
            Expanded(
              child: Text(
                'Gamification notifications temporarily unavailable',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: Colors.orange.shade800,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ),
            if (onRetry != null)
              TextButton(
                onPressed: onRetry,
                child: Text(
                  'Retry',
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: Colors.orange.shade900,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Connection status badge showing realtime connection state
class ConnectionStatusBadge extends StatefulWidget {
  const ConnectionStatusBadge({super.key});

  @override
  State<ConnectionStatusBadge> createState() => _ConnectionStatusBadgeState();
}

class _ConnectionStatusBadgeState extends State<ConnectionStatusBadge> {
  late final Stream<rt_service.ConnectionState> _stream;
  rt_service.ConnectionState _state = rt_service.ConnectionState.disconnected;

  @override
  void initState() {
    super.initState();
    _state = rt_service
        .RealtimeGamificationNotificationService
        .instance
        .connectionState;
    _stream = rt_service
        .RealtimeGamificationNotificationService
        .instance
        .connectionStateStream;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<rt_service.ConnectionState>(
      stream: _stream,
      initialData: _state,
      builder: (context, snapshot) {
        final state = snapshot.data ?? rt_service.ConnectionState.disconnected;
        return Tooltip(
          message: _label(state),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 1.w),
            child: _buildIcon(state),
          ),
        );
      },
    );
  }

  Widget _buildIcon(rt_service.ConnectionState state) {
    switch (state) {
      case rt_service.ConnectionState.connected:
        return Icon(Icons.cloud_done, color: Colors.green, size: 20);
      case rt_service.ConnectionState.disconnected:
        return Icon(Icons.cloud_off, color: Colors.red, size: 20);
      case rt_service.ConnectionState.reconnecting:
        return SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.orange,
          ),
        );
    }
  }

  String _label(rt_service.ConnectionState state) {
    switch (state) {
      case rt_service.ConnectionState.connected:
        return 'Realtime: Connected';
      case rt_service.ConnectionState.disconnected:
        return 'Realtime: Disconnected';
      case rt_service.ConnectionState.reconnecting:
        return 'Realtime: Reconnecting...';
    }
  }
}
