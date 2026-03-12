import 'package:flutter/material.dart';
import '../../../services/realtime_gamification_notification_service.dart'
    as rg;

class ConnectionStatusBadgeWidget extends StatefulWidget {
  const ConnectionStatusBadgeWidget({super.key});

  @override
  State<ConnectionStatusBadgeWidget> createState() =>
      _ConnectionStatusBadgeWidgetState();
}

class _ConnectionStatusBadgeWidgetState
    extends State<ConnectionStatusBadgeWidget> {
  rg.ConnectionState _state = rg.ConnectionState.disconnected;

  @override
  void initState() {
    super.initState();
    _state =
        rg.RealtimeGamificationNotificationService.instance.connectionState;
    rg.RealtimeGamificationNotificationService.instance.connectionStateStream
        .listen((state) {
          if (mounted) setState(() => _state = state);
        });
  }

  @override
  Widget build(BuildContext context) {
    switch (_state) {
      case rg.ConnectionState.connected:
        return Tooltip(
          message: 'Gamification notifications connected',
          child: Icon(Icons.cloud_done, color: Colors.green[400], size: 22),
        );
      case rg.ConnectionState.disconnected:
        return Tooltip(
          message: 'Gamification notifications disconnected',
          child: Icon(Icons.cloud_off, color: Colors.red[400], size: 22),
        );
      case rg.ConnectionState.reconnecting:
        return Tooltip(
          message: 'Reconnecting...',
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.yellow[700],
            ),
          ),
        );
    }
  }
}
